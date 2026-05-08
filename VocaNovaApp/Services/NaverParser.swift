import Foundation

/// 네이버 사전 응답 → `WordSnapshot`.
///
/// `voca-extension/parser.js`와 `VocaNova/src/lib/naverDict.ts` 두 구현을 한 곳에 통합한 Swift 포팅.
/// 모든 함수는 순수 함수 — 네트워킹 없음, 테스트 용이.
enum NaverParser {

    /// 응답 → 정규화된 단어 모델. 결과가 없으면 nil.
    static func parse(_ response: NaverResponse) -> WordSnapshot? {
        guard let item = response.searchResultMap?.searchResultListMap?.WORD?.items?.first,
              let word = item.handleEntry, !word.isEmpty
        else { return nil }

        let pronunciations = parsePronunciations(item.searchPhoneticSymbolList ?? [])
        let partsOfSpeech = parsePartsOfSpeech(item.meansCollector ?? [])

        // 발음/뜻이 모두 비어 있으면 의미 없는 결과 — nil.
        guard !partsOfSpeech.isEmpty || !pronunciations.isEmpty else { return nil }

        let synonyms = parsePipeList(item.expSynonym)
        let antonyms = parsePipeList(item.expAntonym)
        let images: [String] = {
            guard item.hasImage == 1, let urls = item.entryImageURL else { return [] }
            return urls.filter { !$0.isEmpty }
        }()

        let externalUrl = "https://en.dict.naver.com/#/search?query=" +
            (word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word)

        return WordSnapshot(
            word: word,
            externalUrl: externalUrl,
            source: item.sourceDictnameKO,
            level: item.frequencyAdd,
            hasIdiom: (item.hasIdiom ?? 0) == 1,
            pronunciations: pronunciations,
            partsOfSpeech: partsOfSpeech,
            synonyms: synonyms,
            antonyms: antonyms,
            images: images
        )
    }

    // MARK: - Pronunciations

    private static func parsePronunciations(_ list: [NaverResponse.PhoneticSymbol]) -> [Pronunciation] {
        list.compactMap { sym -> Pronunciation? in
            let label = sym.symbolType ?? ""
            let rawIPA = sym.symbolValue ?? ""
            let audio = sym.symbolFile ?? ""
            // ipa와 audio가 모두 비어있는 항목은 버림.
            if rawIPA.isEmpty && audio.isEmpty { return nil }
            return Pronunciation(
                label: label,
                ipa: normalizeIPA(rawIPA),
                audioUrl: audio
            )
        }
    }

    // MARK: - Parts of speech / meanings

    private static func parsePartsOfSpeech(_ list: [NaverResponse.Collector]) -> [PartOfSpeech] {
        list.compactMap { collector -> PartOfSpeech? in
            let pos = collector.partOfSpeech ?? ""
            let meanings = (collector.means ?? []).compactMap { mean -> Meaning? in
                guard let value = mean.value, !value.isEmpty else { return nil }
                return Meaning(
                    order: mean.order ?? "",
                    definition: stripHTML(value),
                    exampleEn: mean.exampleOri.map { sanitizeExample($0) },
                    exampleKo: mean.exampleTrans.map { stripHTML($0) }
                )
            }
            guard !meanings.isEmpty else { return nil }
            return PartOfSpeech(pos: pos, meanings: meanings)
        }
    }

    // MARK: - Pipe-delimited synonym/antonym

    /// "race^https://...|jog^https://..." → [{word: "race", url: "..."}, ...]
    static func parsePipeList(_ raw: String?) -> [RelatedWord] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: "|").compactMap { entry in
            let parts = entry.components(separatedBy: "^")
            guard let first = parts.first?.trimmingCharacters(in: .whitespaces),
                  !first.isEmpty
            else { return nil }
            let url = parts.count > 1 ? parts[1] : ""
            return RelatedWord(word: first, url: url)
        }
    }

    // MARK: - HTML / IPA 정규화 (parser.js의 정규식 체인을 그대로 옮김)

    /// IPA에서 네이버의 HTML 강세 표기를 표준 IPA 기호로 변환.
    /// 예) "ˈnæ<sub>│</sub>vəˌ<sup>│</sup>geɪt" → "ˈnævəˌˈgeɪt" 비슷한 형태로 정리.
    static func normalizeIPA(_ raw: String) -> String {
        var s = raw
        s = s.replacingOccurrences(
            of: #"<sup[^>]*>│</sup>"#,
            with: "ˈ",
            options: .regularExpression
        )
        s = s.replacingOccurrences(
            of: #"<sub[^>]*>│</sub>"#,
            with: "ˌ",
            options: .regularExpression
        )
        s = stripHTML(s)
        s = s.replacingOccurrences(of: "│", with: "ˈ")
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// 모든 HTML 태그 제거 + 엔티티 디코드.
    static func stripHTML(_ raw: String) -> String {
        var s = raw.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: "",
            options: .regularExpression
        )
        s = decodeHTMLEntities(s)
        return s
    }

    /// `<strong>`만 보존, 나머지 태그 제거. SwiftUI 측에서 `<strong>`을 굵기 범위로 변환한다.
    static func sanitizeExample(_ raw: String) -> String {
        // 보호: <strong>·</strong> 토큰을 임시 placeholder로 치환 → 다른 태그 모두 제거 → 복원.
        let openMarker = "\u{F011}STRONG_OPEN\u{F011}"
        let closeMarker = "\u{F012}STRONG_CLOSE\u{F012}"
        var s = raw.replacingOccurrences(
            of: #"<\s*strong\s*>"#,
            with: openMarker,
            options: .regularExpression
        )
        s = s.replacingOccurrences(
            of: #"<\s*/\s*strong\s*>"#,
            with: closeMarker,
            options: .regularExpression
        )
        s = s.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: "",
            options: .regularExpression
        )
        s = s.replacingOccurrences(of: openMarker, with: "<strong>")
        s = s.replacingOccurrences(of: closeMarker, with: "</strong>")
        return decodeHTMLEntities(s)
    }

    /// 자주 등장하는 HTML 엔티티만 처리 (의존성 없이 가볍게).
    private static func decodeHTMLEntities(_ s: String) -> String {
        var out = s
        let pairs: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&nbsp;", " "),
            ("&middot;", "·"),
        ]
        for (k, v) in pairs {
            out = out.replacingOccurrences(of: k, with: v)
        }
        return out
    }
}
