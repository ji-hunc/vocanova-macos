import Foundation

extension URL {
    /// URL의 fragment(`#a=b&c=d`)를 사전으로 파싱.
    ///
    /// Supabase의 OAuth implicit flow는 `vocanova://auth-callback#access_token=…&refresh_token=…&expires_in=3600`
    /// 형태로 토큰을 fragment에 실어 돌려준다. URLComponents는 fragment를 파싱해주지 않으므로 직접 처리.
    func fragmentParameters() -> [String: String] {
        guard let fragment = self.fragment, !fragment.isEmpty else { return [:] }
        var dict: [String: String] = [:]
        for pair in fragment.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            let key = parts[0].removingPercentEncoding ?? parts[0]
            let value = parts[1].removingPercentEncoding ?? parts[1]
            dict[key] = value
        }
        return dict
    }
}
