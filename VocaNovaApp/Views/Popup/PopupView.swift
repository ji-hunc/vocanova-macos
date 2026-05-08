import SwiftUI

/// 메인 사전 카드 — 헤더, 발음, POS 블록, 유의어/반의어, 푸터를 한 화면에.
struct PopupView: View {
    let snapshot: WordSnapshot
    @ObservedObject var popup: PopupViewModel
    @ObservedObject var auth: AuthViewModel
    @ObservedObject var session: SessionStore
    let audio: AudioPlayer

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.sectionSpacing) {

            // 우상단 액션 (저장/로그인 카드).
            topActions

            // 단어 헤더.
            WordHeaderView(snapshot: snapshot)

            // 발음 (US/UK + 스피커).
            if !snapshot.pronunciations.isEmpty {
                PronunciationsView(pronunciations: snapshot.pronunciations, audio: audio)
            }

            // 단어 의미 (품사별 블록).
            ForEach(snapshot.partsOfSpeech) { pos in
                PartOfSpeechBlock(pos: pos)
            }

            // 유의어/반의어.
            if !snapshot.synonyms.isEmpty {
                RelatedWordsView(label: "유의어", items: snapshot.synonyms)
            }
            if !snapshot.antonyms.isEmpty {
                RelatedWordsView(label: "반의어", items: snapshot.antonyms)
            }

            // 푸터.
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var topActions: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Spacer()
                SaveButton(state: popup.saveState,
                           isSignedIn: session.isSignedIn) {
                    popup.saveCurrentWord()
                }
            }
            if popup.showLoginCard {
                LoginMenu(auth: auth) {
                    popup.showLoginCard = false
                }
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        Divider().padding(.top, 4)
        HStack {
            if let source = snapshot.source, !source.isEmpty {
                Text(source)
                    .font(Theme.footerFont)
                    .foregroundStyle(Theme.tertiaryText)
            }
            Spacer()
            if let urlStr = snapshot.externalUrl, let url = URL(string: urlStr) {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Text("자세히 보기 →")
                        .font(Theme.footerFont)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
