import Foundation

/// 단어 저장 RPC 클라이언트.
///
/// `add_word_to_vocab(p_lemma, p_snapshot, p_source_url, p_context_sentence)` 한 가지.
/// PostgREST RPC는 응답이 단일 객체 또는 배열일 수 있어 두 형태 모두 처리한다.
@MainActor
final class VocabService {
    private let client: SupabaseClient
    private let http: HTTPClient
    private let session: SessionStore

    init(client: SupabaseClient, http: HTTPClient, session: SessionStore) {
        self.client = client
        self.http = http
        self.session = session
    }

    /// 단어 저장. 401이면 한 번 refresh 후 재시도.
    func saveWord(snapshot: WordSnapshot,
                  sourceURL: String? = nil,
                  contextSentence: String? = nil) async throws -> SaveWordResult {
        guard let token = try await session.validAccessToken() else {
            throw AppError.supabaseHTTP(401, "로그인 필요")
        }

        do {
            return try await call(snapshot: snapshot,
                                  sourceURL: sourceURL,
                                  contextSentence: contextSentence,
                                  token: token)
        } catch AppError.supabaseHTTP(401, _) {
            // 만료된 토큰을 들고 있었던 경우 — 한 번만 refresh 후 재시도.
            Log.network.notice("vocab save 401 → retrying after refresh")
            _ = try await session.refreshIfPossible()
            guard let newToken = try await session.validAccessToken() else {
                throw AppError.supabaseHTTP(401, "재로그인 필요")
            }
            return try await call(snapshot: snapshot,
                                  sourceURL: sourceURL,
                                  contextSentence: contextSentence,
                                  token: newToken)
        }
    }

    private func call(snapshot: WordSnapshot,
                      sourceURL: String?,
                      contextSentence: String?,
                      token: String) async throws -> SaveWordResult {

        // RPC 본문을 동적으로 구성: snapshot은 그대로, 나머지는 nil이면 NSNull.
        struct Payload: Encodable {
            let p_lemma: String
            let p_snapshot: WordSnapshot
            let p_source_url: String?
            let p_context_sentence: String?
        }
        let payload = Payload(
            p_lemma: snapshot.word,
            p_snapshot: snapshot,
            p_source_url: sourceURL,
            p_context_sentence: contextSentence
        )
        let body = try JSONEncoder().encode(payload)

        let request = client.makeRequest(
            path: "/rest/v1/rpc/add_word_to_vocab",
            method: "POST",
            accessToken: token,
            body: body,
            extraHeaders: ["Prefer": "return=representation"]
        )

        let (data, response) = try await http.data(for: request)
        guard 200..<300 ~= response.statusCode else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw AppError.supabaseHTTP(response.statusCode, bodyText)
        }

        // RPC는 단일 row 또는 배열로 반환됨 — 둘 다 시도.
        if let single = try? JSONDecoder().decode(SaveWordResult.self, from: data) {
            return single
        }
        if let array = try? JSONDecoder().decode([SaveWordResult].self, from: data),
           let first = array.first {
            return first
        }
        let preview = String(data: data.prefix(200), encoding: .utf8) ?? ""
        throw AppError.decoding("RPC 응답 해석 실패: \(preview)")
    }
}
