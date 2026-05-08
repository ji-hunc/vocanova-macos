import Foundation

/// 네이버 영어 사전 응답의 부분 디코드.
///
/// 응답이 80~120KB의 거대한 트리지만 우리는 `searchResultMap.searchResultListMap.WORD.items[0]`
/// 한 곳만 사용한다. 알 수 없는 필드는 무시한다 (lenient decoding) — 모든 필드 optional.
struct NaverResponse: Decodable {
    let searchResultMap: SearchResultMap?

    struct SearchResultMap: Decodable {
        let searchResultListMap: SearchResultListMap?
    }

    struct SearchResultListMap: Decodable {
        let WORD: WordList?
    }

    struct WordList: Decodable {
        let items: [WordItem]?
    }

    struct WordItem: Decodable {
        let handleEntry: String?
        let meansCollector: [Collector]?
        let searchPhoneticSymbolList: [PhoneticSymbol]?
        let expSynonym: String?
        let expAntonym: String?
        let entryImageURL: [String]?
        let hasImage: Int?
        let sourceDictnameKO: String?
        let frequencyAdd: String?
        let hasIdiom: Int?
    }

    struct Collector: Decodable {
        let partOfSpeech: String?
        let means: [Mean]?
    }

    struct Mean: Decodable {
        let order: String?
        let value: String?
        let exampleOri: String?
        let exampleTrans: String?
    }

    struct PhoneticSymbol: Decodable {
        let symbolType: String?
        let symbolValue: String?
        let symbolFile: String?
    }
}
