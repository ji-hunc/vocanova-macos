import Foundation

/// 네이버 영어 사전 검색 — `WordSnapshot`까지 정규화하여 반환.
final class NaverDictionaryService {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    /// 결과가 없으면 nil. HTTP 오류는 throw.
    /// - Parameter raw: 사용자가 선택한 원문 (앞뒤 공백/문장 부호 포함 가능).
    func lookup(_ raw: String) async throws -> WordSnapshot? {
        let cleaned = sanitize(raw)
        guard !cleaned.isEmpty else { return nil }

        guard let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: Config.naverEndpoint + encoded)
        else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Referer 미설정 시 빈 응답이 와서 무조건 명시.
        request.setValue(Config.naverReferer, forHTTPHeaderField: "Referer")
        request.setValue(Config.naverUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")

        Log.network.info("naver lookup: \(cleaned, privacy: .public)")
        let (data, response) = try await http.data(for: request)

        guard 200..<300 ~= response.statusCode else {
            throw AppError.naverHTTP(response.statusCode)
        }

        let decoded = try await http.decode(NaverResponse.self, from: data, snakeCase: false)
        return NaverParser.parse(decoded)
    }

    /// 선택 텍스트를 검색어로 정리.
    ///
    /// - 양 끝 공백/문장부호 제거
    /// - 너무 길면 첫 줄, 첫 5단어로 자름 (extension의 정책과 동일)
    /// - **모두 소문자로 변환** — 사전 lemma는 소문자라 "Apple"/"APPLE" → "apple"로 정규화해야 일관된 hit rate.
    private func sanitize(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:\"'()[]{}<>—–"))
        // 줄바꿈 있으면 첫 줄만.
        if let firstLine = s.components(separatedBy: .newlines).first { s = firstLine }
        // 5단어 초과 시 잘라냄 — 사전에 통째로 던질 의미가 없다.
        let words = s.split(separator: " ", omittingEmptySubsequences: true)
        if words.count > 5 {
            s = words.prefix(1).joined(separator: " ")
        }
        return s.lowercased()
    }
}
