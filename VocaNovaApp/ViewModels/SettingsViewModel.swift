import AppKit
import Foundation

/// 설정창 상태 + 토글 사이드 이펙트.
///
/// `@Published` 토글 3개:
/// - `launchAtLoginEnabled` — `SMAppService.mainApp` 직접 등록/해제 (UD 미러 없음)
/// - `showMenuBarIcon` — UD에 영속, AppDelegate가 NSStatusItem + activation policy 토글
/// - `hotkeyEnabled` — UD에 영속, HotkeyService가 KeyboardShortcuts.enable/disable
///
/// `didSet`은 `init` 내부 할당에서 발화하지 않으므로 초기 사이드 이펙트는 AppDelegate가
/// `applicationDidFinishLaunching`에서 한 번 적용한다 (이중 호출 방지).
@MainActor
final class SettingsViewModel: ObservableObject {
    let sessionStore: SessionStore
    let hotkey: HotkeyService
    let launchAtLogin: LaunchAtLoginService
    private let onMenuBarVisibilityChanged: @MainActor (Bool) -> Void

    // MARK: - Published toggles

    @Published var launchAtLoginEnabled: Bool {
        didSet {
            guard !isApplying else { return }
            do {
                try launchAtLogin.setEnabled(launchAtLoginEnabled)
                // 등록 직후 즉시 .requiresApproval일 수 있다.
                if launchAtLogin.requiresApproval {
                    launchAtLoginError = "시스템 설정 → 일반 → 로그인 항목에서 승인이 필요해요."
                } else {
                    launchAtLoginError = nil
                }
            } catch {
                launchAtLoginError = error.localizedDescription
                // 실제 OS 상태와 UI를 일치시키기 위해 토글을 oldValue로 되돌림.
                isApplying = true
                launchAtLoginEnabled = oldValue
                isApplying = false
            }
        }
    }

    @Published var showMenuBarIcon: Bool {
        didSet {
            guard !isApplying else { return }
            Config.UD.setBool(showMenuBarIcon, forKey: Config.UD.showMenuBarIcon)
            onMenuBarVisibilityChanged(showMenuBarIcon)
        }
    }

    @Published var hotkeyEnabled: Bool {
        didSet {
            guard !isApplying else { return }
            Config.UD.setBool(hotkeyEnabled, forKey: Config.UD.hotkeyEnabled)
            hotkey.setEnabled(hotkeyEnabled)
        }
    }

    /// 앱 외관 모드 — 자동/라이트/다크. `NSApp.appearance`를 갱신하면 열려 있는
    /// 모든 윈도우(설정/팝업)가 즉시 다시 그려진다.
    @Published var appearance: AppearanceMode {
        didSet {
            guard !isApplying else { return }
            Config.UD.setString(appearance.rawValue, forKey: Config.UD.appearanceMode)
            NSApp.appearance = appearance.nsAppearance
        }
    }

    /// SMAppService 호출 결과 에러 메시지(`requiresApproval`도 포함). UI에서 빨간 텍스트로 노출.
    @Published var launchAtLoginError: String?

    /// View가 알림 후 호출 — 다음번에는 알림 없이 바로 끔.
    var didConfirmMenuBarHide: Bool {
        get { Config.UD.bool(Config.UD.didConfirmMenuBarHide, default: false) }
        set { Config.UD.setBool(newValue, forKey: Config.UD.didConfirmMenuBarHide) }
    }

    /// `didSet` 가드. 토글 revert / init 시 무한 루프 방지.
    private var isApplying = false

    init(sessionStore: SessionStore,
         hotkey: HotkeyService,
         launchAtLogin: LaunchAtLoginService,
         onMenuBarVisibilityChanged: @escaping @MainActor (Bool) -> Void) {
        self.sessionStore = sessionStore
        self.hotkey = hotkey
        self.launchAtLogin = launchAtLogin
        self.onMenuBarVisibilityChanged = onMenuBarVisibilityChanged

        // 초기 로드 — init 내부 할당이라 didSet 트리거 안 됨.
        // 사이드 이펙트는 AppDelegate가 launch 시 별도로 적용해두므로 안전.
        self.launchAtLoginEnabled = launchAtLogin.isEnabled
        self.showMenuBarIcon = Config.UD.bool(Config.UD.showMenuBarIcon, default: true)
        self.hotkeyEnabled = Config.UD.bool(Config.UD.hotkeyEnabled, default: true)
        let appearanceRaw = Config.UD.string(Config.UD.appearanceMode, default: AppearanceMode.system.rawValue)
        self.appearance = AppearanceMode(rawValue: appearanceRaw) ?? .system

        // 설정창이 열릴 때 OS의 launchAtLogin 상태가 변경되었을 수 있어 한 번 동기화.
        if launchAtLogin.requiresApproval {
            self.launchAtLoginError = "시스템 설정 → 일반 → 로그인 항목에서 승인이 필요해요."
        }
    }

    // MARK: - 기존 API (유지)

    var isAXTrusted: Bool { AccessibilityService.isTrusted }

    func openAccessibilitySettings() {
        AccessibilityService.openSystemSettings()
    }

    /// 시스템 설정 → 로그인 항목 패널을 직접 연다.
    func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    func signOut() async {
        await sessionStore.signOut()
    }
}
