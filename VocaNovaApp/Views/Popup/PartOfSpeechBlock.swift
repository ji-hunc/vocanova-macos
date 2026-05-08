import SwiftUI

struct PartOfSpeechBlock: View {
    let pos: PartOfSpeech

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !pos.pos.isEmpty {
                BadgeView(text: pos.pos)
            }
            MeaningsView(meanings: pos.meanings)
        }
    }
}
