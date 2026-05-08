import SwiftUI

/// 단어장에 저장 버튼.
///
/// 상태별 라벨/아이콘은 voca-extension의 popup.js와 동일한 텍스트.
struct SaveButton: View {
    let state: PopupViewModel.SaveState
    let isSignedIn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                icon
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background, in: Capsule())
            // 비활성 상태(saved/saving)에서도 색상은 그대로 유지하고 살짝 dim만.
            .opacity(isDisabled ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(tooltip)
    }

    private var label: String {
        switch state {
        case .ready: return "단어장에 저장"
        case .saving: return "저장 중…"
        case .saved: return "저장됨"
        case .alreadySaved: return "이미 저장됨"
        case .error: return "다시 시도"
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .ready: Image(systemName: "plus").font(.system(size: 11, weight: .bold))
        case .error: Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .bold))
        case .saving: ProgressView().controlSize(.mini).tint(.white)
        case .saved, .alreadySaved: Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
        }
    }

    /// 모든 상태에서 흰 글씨를 쓰므로, 배경만 상태별로 분기.
    /// - ready/saving: primary accent (파랑)
    /// - saved/alreadySaved: success (초록)
    /// - error: danger (빨강)
    private var background: Color {
        switch state {
        case .ready, .saving: return Theme.accent
        case .saved, .alreadySaved: return Theme.success
        case .error: return Theme.danger
        }
    }

    private var isDisabled: Bool {
        switch state {
        case .saving, .saved, .alreadySaved: return true
        default: return false
        }
    }

    private var tooltip: String {
        switch state {
        case .error(let msg): return msg
        default: return ""
        }
    }
}
