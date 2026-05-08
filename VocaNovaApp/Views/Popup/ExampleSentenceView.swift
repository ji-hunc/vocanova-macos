import SwiftUI

struct ExampleSentenceView: View {
    let english: String?
    let korean: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let en = english, !en.isEmpty {
                HighlightedText(raw: en)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let ko = korean, !ko.isEmpty {
                Text(ko)
                    .font(Theme.translationFont)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.exampleBg, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            // 좌측 2pt 액센트 막대.
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.accent.opacity(0.5))
                    .frame(width: 2)
                Spacer()
            }
        )
    }
}
