import Foundation

/// Supabase REST 호출 공통 헤더/URL 빌더.
///
/// `apikey`는 항상, `Authorization: Bearer <token>`은 토큰이 있을 때만 세팅.
final class SupabaseClient {
    let baseURL: URL
    let anonKey: String

    init(baseURL: URL, anonKey: String) {
        self.baseURL = baseURL
        self.anonKey = anonKey
    }

    /// path는 `/auth/v1/...` 또는 `/rest/v1/...` 형태로 시작.
    func makeRequest(path: String,
                     method: String,
                     accessToken: String? = nil,
                     query: [URLQueryItem] = [],
                     body: Data? = nil,
                     extraHeaders: [String: String] = [:]) -> URLRequest {

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (k, v) in extraHeaders {
            request.setValue(v, forHTTPHeaderField: k)
        }
        request.httpBody = body
        return request
    }

    /// Authorize URL (OAuth provider 경유 로그인).
    func buildAuthorizeURL(provider: String, redirectTo: String) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("/auth/v1/authorize"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "provider", value: provider),
            URLQueryItem(name: "redirect_to", value: redirectTo),
        ]
        return components.url!
    }
}
