import SwiftUI

struct PopupErrorView: View {
    let title: String
    let message: String
    let onRetry: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
            Text(message)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let onRetry {
                    Button("다시 시도") { onRetry() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                Button("닫기") { onClose() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
