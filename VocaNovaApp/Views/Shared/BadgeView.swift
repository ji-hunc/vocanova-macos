import SwiftUI

/// 작은 라벨 배지. 품사 표시, 미국식/영국식 라벨에 사용.
struct BadgeView: View {
    let text: String
    var background: Color = Theme.accentSoft
    var foreground: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(Theme.posBadgeFont)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
