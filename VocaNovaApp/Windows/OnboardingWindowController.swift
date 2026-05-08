import AppKit
import SwiftUI

/// 첫 실행 시 표시되는 온보딩 — AX 권한 요청 + 단축키 안내 + 완료.
@MainActor
final class OnboardingWindowController: NSWindowController {
    private let environment: AppEnvironment
    private let onComplete: () -> Void

    init(environment: AppEnvironment, onComplete: @escaping () -> Void) {
        self.environment = environment
        self.onComplete = onComplete

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 440),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "VocaNova 시작하기"
        window.titlebarAppearsTransparent = true
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let viewModel = OnboardingViewModel()
        let view = OnboardingView(viewModel: viewModel, hotkey: environment.hotkeyService) { [weak self] in
            self?.onComplete()
        }
        window.contentView = NSHostingView(rootView: view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}
