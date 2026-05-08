import KeyboardShortcuts
import SwiftUI

struct OnboardingStepHotkey: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let hotkey: HotkeyService

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("단축키를 설정하세요")
                .font(.system(size: 22, weight: .bold))

            Text("기본값은 ⌘ ⇧ F. 다른 앱과 충돌하면 자유롭게 바꿀 수 있어요.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Text("단축키")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                KeyboardShortcuts.Recorder(for: .lookupSelection)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 24)

            Spacer()

            HStack {
                Button("이전") { viewModel.goToPrevious() }
                Spacer()
                Button("다음") { viewModel.goToNext() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .padding(.top, 32)
    }
}
