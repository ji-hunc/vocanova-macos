import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {

    init(environment: AppEnvironment) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "VocaNova 설정"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let viewModel = SettingsViewModel(
            sessionStore: environment.sessionStore,
            hotkey: environment.hotkeyService
        )
        let auth = AuthViewModel(sessionStore: environment.sessionStore)

        let view = SettingsView(viewModel: viewModel, auth: auth)
            .environmentObject(environment.sessionStore)
        window.contentView = NSHostingView(rootView: view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}
