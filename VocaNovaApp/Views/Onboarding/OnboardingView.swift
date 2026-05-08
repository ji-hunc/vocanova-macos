import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let hotkey: HotkeyService
    let onFinish: () -> Void

    init(viewModel: OnboardingViewModel, hotkey: HotkeyService, onFinish: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.hotkey = hotkey
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.step {
            case .accessibility:
                OnboardingStepAccessibility(viewModel: viewModel)
            case .hotkey:
                OnboardingStepHotkey(viewModel: viewModel, hotkey: hotkey)
            case .done:
                OnboardingStepDone(onFinish: onFinish)
            }
        }
        .frame(width: 560, height: 440)
    }
}
