import Foundation

/// 사전 검색 결과의 정규화된 형태.
///
/// `voca-extension`(JS)과 `VocaNova`(RN) 둘 다 같은 camelCase JSON으로 직렬화한다.
/// 이 macOS 앱이 Supabase RPC `add_word_to_vocab`의 `p_snapshot`으로 보내는 JSON이
/// 그쪽들과 바이트 호환되어야 같은 row가 모든 클라이언트에서 그대로 보인다.
/// → CodingKeys를 명시하지 않고 camelCase 그대로 둔다.
struct WordSnapshot: Codable, Equatable, Hashable {
    var word: String
    var externalUrl: String?
    var source: String?
    var level: String?
    var hasIdiom: Bool?

    var pronunciations: [Pronunciation]
    var partsOfSpeech: [PartOfSpeech]
    var synonyms: [RelatedWord]
    var antonyms: [RelatedWord]
    var images: [String]
}

struct Pronunciation: Codable, Equatable, Hashable, Identifiable {
    var label: String      // "미국식" / "영국식" / "미국∙영국" 등
    var ipa: String        // "ˈnævəˌɡeɪt"
    var audioUrl: String   // mp3 URL (빈 문자열일 수 있음)

    var id: String { "\(label)|\(ipa)|\(audioUrl)" }
}

struct PartOfSpeech: Codable, Equatable, Hashable, Identifiable {
    var pos: String                  // "동사", "명사", ...
    var meanings: [Meaning]

    var id: String { pos + "|" + meanings.map(\.order).joined(separator: ",") }
}

struct Meaning: Codable, Equatable, Hashable, Identifiable {
    var order: String
    var definition: String           // 한국어 정의 (HTML 제거됨)
    var exampleEn: String?           // 영어 예문 (<strong> 보존)
    var exampleKo: String?           // 한국어 번역

    var id: String { order + "|" + definition }
}

struct RelatedWord: Codable, Equatable, Hashable, Identifiable {
    var word: String
    var url: String

    var id: String { word + "|" + url }
}
