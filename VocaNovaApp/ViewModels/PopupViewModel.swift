import Foundation
import SwiftUI

/// 단어 검색 + 저장의 상태머신.
///
/// 두 상태가 독립적으로 존재한다:
/// - LoadState: 사전 결과를 가져오는 흐름
/// - SaveState: "저장" 버튼의 상태 (저장 결과 표시는 LoadState와 직교)
@MainActor
final class PopupViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(WordSnapshot)
        case notFound(query: String)
        case error(String)
    }

    enum SaveState: Equatable {
        case ready
        case saving
        case saved
        case alreadySaved
        case error(String)
    }

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var saveState: SaveState = .ready
    @Published var showLoginCard: Bool = false

    let initialQuery: String
    private let environment: AppEnvironment
    private var loadTask: Task<Void, Never>?

    /// 미로그인 상태에서 저장 시도 후 로그인이 완료되면 자동 저장 재시도.
    private var autoSaveAfterLogin = false

    init(query: String, environment: AppEnvironment, initialError: Error?) {
        self.initialQuery = query
        self.environment = environment
        if let initialError {
            self.loadState = .error((initialError as? AppError)?.localizedDescription
                                    ?? initialError.localizedDescription)
        }
    }

    // MARK: - Load

    /// 팝업이 표시되면 호출. 이미 에러 상태면 다시 시도하지 않음.
    func startLoadIfNeeded() {
        if case .error = loadState { return }
        if loadState != .idle { return }
        startLoad()
    }

    func retry() {
        startLoad()
    }

    private func startLoad() {
        loadTask?.cancel()
        let q = initialQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            loadState = .error(AppError.noSelection.localizedDescription ?? "선택이 비어있어요.")
            return
        }
        loadState = .loading

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let snapshot = try await environment.naverService.lookup(q)
                if Task.isCancelled { return }
                if let snapshot {
                    loadState = .loaded(snapshot)
                } else {
                    loadState = .notFound(query: q)
                }
            } catch {
                if Task.isCancelled { return }
                let message = (error as? AppError)?.localizedDescription
                    ?? error.localizedDescription
                loadState = .error(message)
            }
        }
    }

    // MARK: - Save

    func saveCurrentWord() {
        guard case .loaded(let snapshot) = loadState else { return }

        // 미로그인이면 인라인 로그인 카드 표시.
        if !environment.sessionStore.isSignedIn {
            showLoginCard = true
            autoSaveAfterLogin = true
            return
        }

        Task { @MainActor in
            await performSave(snapshot)
        }
    }

    /// 로그인 완료 후 호출됨 — 자동 저장 재시도.
    func didCompleteLogin() {
        showLoginCard = false
        guard autoSaveAfterLogin else { return }
        autoSaveAfterLogin = false
        if case .loaded(let snapshot) = loadState {
            Task { @MainActor in
                await performSave(snapshot)
            }
        }
    }

    private func performSave(_ snapshot: WordSnapshot) async {
        saveState = .saving
        do {
            let result = try await environment.vocabService.saveWord(
                snapshot: snapshot,
                sourceURL: nil,
                contextSentence: nil
            )
            saveState = result.wasNew ? .saved : .alreadySaved
        } catch {
            let message = (error as? AppError)?.localizedDescription
                ?? error.localizedDescription
            saveState = .error(message)
        }
    }

    // MARK: - Cancellation

    /// 팝업 닫힐 때 호출. 진행 중인 검색을 정리.
    func cancel() {
        loadTask?.cancel()
        loadTask = nil
    }
}
