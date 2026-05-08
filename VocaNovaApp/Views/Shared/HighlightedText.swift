import SwiftUI

/// `<strong>...</strong>` 태그를 굵기 범위로 변환해 렌더하는 텍스트 컴포넌트.
///
/// 네이버 응답의 영어 예문에는 검색 단어 자체가 `<strong>` 으로 감싸져 있다.
/// 우리는 문자열 단위로 토큰화한 뒤 AttributedString을 만든다.
struct HighlightedText: View {
    let raw: String
    var baseFont: Font = Theme.exampleFont
    var color: Color = Theme.primaryText

    var body: some View {
        Text(makeAttributedString())
    }

    private func makeAttributedString() -> AttributedString {
        var result = AttributedString()
        let pattern = #"<strong>(.*?)</strong>"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            var fallback = AttributedString(raw)
            fallback.font = baseFont
            fallback.foregroundColor = color
            return fallback
        }

        let ns = raw as NSString
        var cursor = 0
        let range = NSRange(location: 0, length: ns.length)

        regex.enumerateMatches(in: raw, options: [], range: range) { match, _, _ in
            guard let match else { return }
            let outerRange = match.range
            let innerRange = match.range(at: 1)

            // 일반 텍스트.
            if outerRange.location > cursor {
                let plain = ns.substring(with: NSRange(location: cursor, length: outerRange.location - cursor))
                var seg = AttributedString(plain)
                seg.font = baseFont
                seg.foregroundColor = color
                result.append(seg)
            }
            // 강조 텍스트.
            let strong = ns.substring(with: innerRange)
            var bold = AttributedString(strong)
            bold.font = baseFont.weight(.semibold)
            bold.foregroundColor = Theme.accent
            result.append(bold)

            cursor = outerRange.location + outerRange.length
        }

        // 남은 꼬리.
        if cursor < ns.length {
            let tail = ns.substring(with: NSRange(location: cursor, length: ns.length - cursor))
            var seg = AttributedString(tail)
            seg.font = baseFont
            seg.foregroundColor = color
            result.append(seg)
        }
        return result
    }
}
