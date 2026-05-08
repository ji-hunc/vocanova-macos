import SwiftUI

struct RelatedWordsView: View {
    let label: String           // "유의어" / "반의어"
    let items: [RelatedWord]

    var body: some View {
        if !items.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 4)
                    .frame(width: 38, alignment: .leading)

                FlowLayout(spacing: 6) {
                    ForEach(items.prefix(8)) { item in
                        ChipView(text: item.word, url: item.url)
                    }
                }
            }
        }
    }
}
