import SwiftUI

/// 유의어/반의어 chip. URL이 있으면 탭 시 외부 브라우저로 열림.
struct ChipView: View {
    let text: String
    let url: String?

    @State private var isHovered = false

    var body: some View {
        Button {
            if let s = url, let u = URL(string: s), !s.isEmpty {
                NSWorkspace.shared.open(u)
            }
        } label: {
            Text(text)
                .font(Theme.chipFont)
                .foregroundStyle(isHovered ? .white : Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    isHovered ? Theme.accent : Theme.accentSoft,
                    in: RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
