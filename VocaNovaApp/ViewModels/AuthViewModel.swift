import Foundation
import SwiftUI

/// 로그인/로그아웃 트리거 + 진행 상태.
///
/// `SessionStore`는 진실의 원천이고 이 VM은 UI 보조 상태(loading/error)만 관리한다.
@MainActor
final class AuthViewModel: ObservableObject {

    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    let sessionStore: SessionStore
    private(set) var onLoginSuccess: (() -> Void)?

    init(sessionStore: SessionStore, onLoginSuccess: (() -> Void)? = nil) {
        self.sessionStore = sessionStore
        self.onLoginSuccess = onLoginSuccess
    }

    func setOnLoginSuccess(_ closure: @escaping () -> Void) {
        self.onLoginSuccess = closure
    }

    func signInWithGoogle() async {
        await runLogin { try await self.sessionStore.signInWithGoogle() }
    }

    func signInWithApple() async {
        await runLogin { try await self.sessionStore.signInWithApple() }
    }

    func signOut() async {
        isWorking = true
        defer { isWorking = false }
        await sessionStore.signOut()
    }

    private func runLogin(_ work: @escaping () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        do {
            try await work()
            onLoginSuccess?()
        } catch AppError.authCanceled {
            // 사용자가 취소 — 에러 메시지 띄우지 않음.
        } catch {
            errorMessage = (error as? AppError)?.localizedDescription
                ?? error.localizedDescription
        }
        isWorking = false
    }
}
