import SwiftUI

struct MeaningsView: View {
    let meanings: [Meaning]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(meanings) { m in
                MeaningRow(meaning: m)
            }
        }
    }
}

struct MeaningRow: View {
    let meaning: Meaning

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 번호 배지.
            Text(meaning.order)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(minWidth: 16, alignment: .trailing)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(meaning.definition)
                    .font(Theme.definitionFont)
                    .foregroundStyle(Theme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if meaning.exampleEn != nil || meaning.exampleKo != nil {
                    ExampleSentenceView(
                        english: meaning.exampleEn,
                        korean: meaning.exampleKo
                    )
                }
            }
        }
    }
}
