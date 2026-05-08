import Foundation
import SwiftUI

/// Supabase 세션의 단일 진실 공급원.
///
/// SwiftUI 뷰는 `@ObservedObject` / `@EnvironmentObject`로 구독하고,
/// 서비스 레이어는 `validAccessToken()`을 호출해 만료 임박 시 자동 refresh를 받는다.
@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var session: SupabaseSession?

    private let keychain: KeychainStore
    private let key: String
    private let auth: SupabaseAuthService

    /// 진행 중인 refresh를 합쳐 동시 호출 시 한 번만 실행.
    private var refreshTask: Task<SupabaseSession, Error>?

    init(keychain: KeychainStore, key: String, auth: SupabaseAuthService) {
        self.keychain = keychain
        self.key = key
        self.auth = auth
        self.session = (try? keychain.getCodable(SupabaseSession.self, forKey: key)) ?? nil
    }

    // MARK: - Mutations

    func setSession(_ new: SupabaseSession) {
        session = new
        try? keychain.setCodable(new, forKey: key)
    }

    func clear() {
        session = nil
        try? keychain.delete(forKey: key)
    }

    // MARK: - Refresh

    /// 만료 임박이면 refresh 수행 후 access token 반환. 미로그인이면 nil.
    /// 실패 시 세션 클리어 후 nil 반환 (사용자에게 재로그인 요구).
    func validAccessToken() async throws -> String? {
        guard let current = session else { return nil }
        guard current.isExpired else { return current.accessToken }
        do {
            let refreshed = try await refreshIfPossible()
            return refreshed.accessToken
        } catch {
            Log.auth.error("refresh failed: \(error.localizedDescription, privacy: .public)")
            clear()
            return nil
        }
    }

    /// 명시적 refresh. 동시 호출은 합쳐진다.
    @discardableResult
    func refreshIfPossible() async throws -> SupabaseSession {
        if let task = refreshTask {
            return try await task.value
        }
        guard let current = session else {
            throw AppError.unknown("로그인 상태가 아닙니다.")
        }

        let task = Task<SupabaseSession, Error> { [weak self] in
            guard let self else { throw AppError.unknown("self 해제됨") }
            var refreshed = try await self.auth.refresh(refreshToken: current.refreshToken)
            // refresh 응답엔 provider 정보가 없으니 직전 세션의 lastProvider를 보존.
            refreshed.lastProvider = current.lastProvider
            self.setSession(refreshed)
            return refreshed
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    // MARK: - 로그인 트리거

    func signInWithGoogle() async throws {
        let new = try await auth.signInWithGoogle()
        setSession(new)
    }

    func signInWithApple() async throws {
        let new = try await auth.signInWithApple()
        setSession(new)
    }

    func signOut() async {
        if let token = session?.accessToken {
            await auth.logout(accessToken: token)
        }
        clear()
    }

    var isSignedIn: Bool { session != nil }
}
