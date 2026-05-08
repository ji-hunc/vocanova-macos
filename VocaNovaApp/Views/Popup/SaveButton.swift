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
            HStack(spacing: 4) {
                icon
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .help(tooltip)
    }

    private var label: String {
        switch state {
        case .ready: return isSignedIn ? "단어장에 저장" : "단어장에 저장"
        case .saving: return "저장 중…"
        case .saved: return "저장됨"
        case .alreadySaved: return "이미 저장됨"
        case .error: return "다시 시도"
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .ready, .error: Image(systemName: "plus")
        case .saving: ProgressView().controlSize(.mini)
        case .saved, .alreadySaved: Image(systemName: "checkmark")
        }
    }

    private var foreground: Color {
        switch state {
        case .saved, .alreadySaved: return .white
        default: return Theme.accent
        }
    }

    private var background: Color {
        switch state {
        case .saved, .alreadySaved: return Theme.accent
        default: return Theme.accentSoft
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
