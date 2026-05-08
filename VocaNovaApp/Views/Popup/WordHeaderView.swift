import SwiftUI

/// 단어 타이틀. 클릭하면 외부 사전 페이지로 이동.
struct WordHeaderView: View {
    let snapshot: WordSnapshot

    var body: some View {
        Button {
            if let s = snapshot.externalUrl, let u = URL(string: s) {
                NSWorkspace.shared.open(u)
            }
        } label: {
            Text(snapshot.word)
                .font(Theme.titleFont)
                .foregroundStyle(Theme.primaryText)
        }
        .buttonStyle(.plain)
        .help("Naver 영어사전에서 자세히 보기")
    }
}
