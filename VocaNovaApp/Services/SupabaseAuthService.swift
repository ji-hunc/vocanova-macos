import AppKit
import AuthenticationServices
import Foundation

/// Supabase 인증 — Google(웹 OAuth) + Apple(네이티브 ID 토큰) + refresh + logout.
///
/// `supabase-swift` SDK를 쓰지 않고 직접 호출하는 이유:
/// - 우리가 호출할 엔드포인트가 4개(authorize, token x2, user, logout)뿐
/// - 의존성 트리를 가볍게 유지
/// - voca-extension JS와 1:1 매핑되어 디버깅 쉬움
@MainActor
final class SupabaseAuthService: NSObject {
    private let client: SupabaseClient
    private let http: HTTPClient

    /// 진행 중인 Apple Sign-In의 identityToken continuation. 여러 동시 호출은 지원하지 않음.
    private var appleSignInContinuationToken: CheckedContinuation<String, Error>?

    /// `ASWebAuthenticationSession`은 약한 참조라 즉시 해제되지 않도록 유지.
    private var webAuthSession: ASWebAuthenticationSession?

    init(client: SupabaseClient, http: HTTPClient) {
        self.client = client
        self.http = http
        super.init()
    }

    // MARK: - Google (web OAuth)

    /// `vocanova://auth-callback#access_token=...` 콜백을 받아 세션을 만든다.
    func signInWithGoogle() async throws -> SupabaseSession {
        let authorizeURL = client.buildAuthorizeURL(provider: "google", redirectTo: Config.oauthCallbackURL)
        Log.auth.info("starting Google OAuth")

        let callbackURL: URL = try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: Config.urlScheme
            ) { url, error in
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    cont.resume(throwing: AppError.authCanceled)
                    return
                }
                if let error {
                    cont.resume(throwing: AppError.unknown(error.localizedDescription))
                    return
                }
                guard let url else {
                    cont.resume(throwing: AppError.authCanceled)
                    return
                }
                cont.resume(returning: url)
            }
            session.presentationContextProvider = self
            // 사용자가 이미 Google에 로그인되어 있어도 매번 계정 선택을 보여주려면 true.
            session.prefersEphemeralWebBrowserSession = false
            self.webAuthSession = session
            session.start()
        }

        let params = callbackURL.fragmentParameters()
        guard let access = params["access_token"],
              let refresh = params["refresh_token"]
        else {
            // 에러 응답일 수도 있음.
            if let err = params["error_description"] {
                throw AppError.unknown(err)
            }
            throw AppError.unknown("OAuth 콜백 파라미터 누락")
        }

        let expiresIn = TimeInterval(params["expires_in"] ?? "") ?? 3600
        var session = SupabaseSession(
            accessToken: access,
            refreshToken: refresh,
            expiresAt: Date().timeIntervalSince1970 + expiresIn,
            user: nil,
            lastProvider: "google"
        )

        // user 정보 채워넣기 (best-effort).
        session.user = try? await fetchUser(accessToken: access)
        Log.auth.info("Google sign-in success — token=\(Log.redacted(access), privacy: .public)")
        return session
    }

    // MARK: - Apple (native ID token)

    func signInWithApple() async throws -> SupabaseSession {
        let rawNonce = NonceGenerator.makeRandom(length: 32)

        let identityToken: String = try await withCheckedThrowingContinuation { cont in
            self.appleSignInContinuationToken = cont

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = rawNonce.sha256Hex()

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        Log.auth.info("Apple identity token received (\(identityToken.count) chars), exchanging with Supabase")

        // identityToken + raw nonce를 Supabase에 교환.
        let bodyDict: [String: String] = [
            "id_token": identityToken,
            "provider": "apple",
            "nonce": rawNonce,
        ]
        let body = try JSONEncoder().encode(bodyDict)
        let request = client.makeRequest(
            path: "/auth/v1/token",
            method: "POST",
            query: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: body
        )
        let (data, response) = try await http.data(for: request)
        guard 200..<300 ~= response.statusCode else {
            let text = String(data: data, encoding: .utf8) ?? "<empty>"
            // 디버깅을 위해 응답 바디를 로그에 남김. 실패 사유가 거의 항상 여기 들어 있다
            // (예: "provider not enabled", "invalid client id", "invalid nonce" 등).
            Log.auth.error("Supabase id_token exchange failed (\(response.statusCode)): \(text, privacy: .public)")
            throw AppError.supabaseHTTP(response.statusCode, text)
        }

        var session = try await decodeSession(data: data)
        session.lastProvider = "apple"
        session.user = try? await fetchUser(accessToken: session.accessToken)
        Log.auth.info("Apple sign-in success — token=\(Log.redacted(session.accessToken), privacy: .public)")
        return session
    }

    // MARK: - Refresh

    /// refresh token을 사용해 새 access token 발급.
    func refresh(refreshToken: String) async throws -> SupabaseSession {
        let bodyDict = ["refresh_token": refreshToken]
        let body = try JSONEncoder().encode(bodyDict)
        let request = client.makeRequest(
            path: "/auth/v1/token",
            method: "POST",
            query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: body
        )
        let (data, response) = try await http.data(for: request)
        guard 200..<300 ~= response.statusCode else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw AppError.supabaseHTTP(response.statusCode, text)
        }

        var session = try await decodeSession(data: data)
        // refresh 응답에는 user가 없을 수도 있어 best-effort로 보강.
        if session.user == nil {
            session.user = try? await fetchUser(accessToken: session.accessToken)
        }
        return session
    }

    // MARK: - Fetch user

    func fetchUser(accessToken: String) async throws -> SupabaseUser {
        let request = client.makeRequest(
            path: "/auth/v1/user",
            method: "GET",
            accessToken: accessToken
        )
        let (data, response) = try await http.data(for: request)
        guard 200..<300 ~= response.statusCode else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw AppError.supabaseHTTP(response.statusCode, text)
        }
        return try await http.decode(SupabaseUser.self, from: data, snakeCase: false)
    }

    // MARK: - Logout

    func logout(accessToken: String) async {
        let request = client.makeRequest(
            path: "/auth/v1/logout",
            method: "POST",
            accessToken: accessToken
        )
        // 실패해도 클라이언트 측 토큰은 어차피 버릴 거라 에러 무시.
        _ = try? await http.data(for: request)
    }

    // MARK: - Private

    private func decodeSession(data: Data) async throws -> SupabaseSession {
        struct TokenResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
            let user: SupabaseUser?
        }
        let decoded = try await http.decode(TokenResponse.self, from: data, snakeCase: true)
        return SupabaseSession(
            accessToken: decoded.accessToken,
            refreshToken: decoded.refreshToken,
            expiresAt: Date().timeIntervalSince1970 + TimeInterval(decoded.expiresIn),
            user: decoded.user
        )
    }
}

// MARK: - ASWebAuthentication / ASAuthorization delegates

extension SupabaseAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // 메인 스레드에서 키 윈도우를 가져오되, 없으면 새 임시 윈도우 사용.
        // (메뉴바 전용 앱이라 키 윈도우가 없을 수 있다.)
        MainActor.assumeIsolated {
            NSApp.keyWindow ?? NSApp.windows.first ?? NSWindow()
        }
    }
}

extension SupabaseAuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            NSApp.keyWindow ?? NSApp.windows.first ?? NSWindow()
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithAuthorization authorization: ASAuthorization) {
        MainActor.assumeIsolated {
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8)
            else {
                appleSignInContinuationToken?.resume(throwing: AppError.unknown("Apple identity token 누락"))
                appleSignInContinuationToken = nil
                return
            }
            appleSignInContinuationToken?.resume(returning: token)
            appleSignInContinuationToken = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithError error: Error) {
        // ns 에러 코드도 함께 로깅 — ASAuthorizationError는 .failed (1000)이 가장 흔하고,
        // 보통 (a) Sign in with Apple capability 미설정 (b) Apple Developer 측 Service ID 미등록
        // (c) 사인되지 않은 dev 빌드 또는 nonce 불일치가 원인이다.
        let nsError = error as NSError
        Log.auth.error("Apple authorization failed — domain=\(nsError.domain, privacy: .public) code=\(nsError.code) desc=\(error.localizedDescription, privacy: .public)")

        MainActor.assumeIsolated {
            if let err = error as? ASAuthorizationError {
                switch err.code {
                case .canceled:
                    appleSignInContinuationToken?.resume(throwing: AppError.authCanceled)
                case .failed:
                    appleSignInContinuationToken?.resume(throwing: AppError.unknown(
                        "Apple 로그인이 실패했어요. Sign in with Apple capability와 Apple Developer 설정을 확인해주세요. (코드 \(err.code.rawValue))"
                    ))
                default:
                    appleSignInContinuationToken?.resume(throwing: AppError.unknown(
                        "Apple 로그인 오류 (코드 \(err.code.rawValue)): \(error.localizedDescription)"
                    ))
                }
            } else {
                appleSignInContinuationToken?.resume(throwing: AppError.unknown(error.localizedDescription))
            }
            appleSignInContinuationToken = nil
        }
    }
}
