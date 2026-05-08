import Foundation

/// 설정 화면 상태. 단축키 표시는 KeyboardShortcuts.Recorder가 직접 관리하므로 여기는 슬림.
@MainActor
final class SettingsViewModel: ObservableObject {
    let sessionStore: SessionStore
    let hotkey: HotkeyService

    init(sessionStore: SessionStore, hotkey: HotkeyService) {
        self.sessionStore = sessionStore
        self.hotkey = hotkey
    }

    var isAXTrusted: Bool { AccessibilityService.isTrusted }

    func openAccessibilitySettings() {
        AccessibilityService.openSystemSettings()
    }

    func signOut() async {
        await sessionStore.signOut()
    }
}
