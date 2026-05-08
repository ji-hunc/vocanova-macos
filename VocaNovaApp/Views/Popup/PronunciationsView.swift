import SwiftUI

struct PronunciationsView: View {
    let pronunciations: [Pronunciation]
    let audio: AudioPlayer

    var body: some View {
        // 발음이 여러 개면 여러 줄로 줄바꿈.
        FlowLayout(spacing: 8) {
            ForEach(pronunciations) { p in
                pronunciationItem(p)
            }
        }
    }

    @ViewBuilder
    private func pronunciationItem(_ p: Pronunciation) -> some View {
        HStack(spacing: 4) {
            if !p.label.isEmpty {
                BadgeView(text: p.label,
                          background: Color.gray.opacity(0.10),
                          foreground: Theme.secondaryText)
            }
            if !p.ipa.isEmpty {
                Text("[\(p.ipa)]")
                    .font(Theme.ipaFont)
                    .foregroundStyle(Theme.primaryText)
            }
            if !p.audioUrl.isEmpty {
                Button {
                    audio.play(urlString: p.audioUrl)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .padding(4)
                        .background(Theme.accentSoft, in: Circle())
                }
                .buttonStyle(.plain)
                .help("발음 듣기")
            }
        }
    }
}

/// 단순 flow layout — 가로 폭이 모자라면 다음 줄로.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: width.isFinite ? width : x, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
