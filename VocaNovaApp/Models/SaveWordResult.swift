import Foundation

/// `add_word_to_vocab` RPC 응답.
///
/// PostgREST 함수 호출은 단일 객체 또는 배열로 반환될 수 있다.
/// `VocabService`가 두 형태 모두 디코드 시도 후 하나로 정규화한다.
struct SaveWordResult: Codable, Equatable {
    var userWordId: String        // UUID 문자열
    var wasNew: Bool

    enum CodingKeys: String, CodingKey {
        case userWordId = "user_word_id"
        case wasNew = "was_new"
    }
}
