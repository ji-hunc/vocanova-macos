import AppKit
import SwiftUI

/// 앱 라이프사이클 + 메뉴바 + 단축키 트리거 진입점.
///
/// LSUIElement 앱이라 NSStatusItem이 사실상 유일한 시각적 진입점이다.
/// 단축키가 들어오면 → 선택 텍스트 읽고 → 팝업 띄우는 플로우의 시작점이 여기다.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var environment: AppEnvironment!
    private var statusItem: NSStatusItem?

    private var popupController: PopupWindowController!
    private var onboardingController: OnboardingWindowController?
    private var settingsController: SettingsWindowController?

    /// AppDelegate가 환경을 생성하기 전 한 줄짜리 로그를 위해 즉시 사용하는 글로벌 로거.
    private let log = Log.app

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("VocaNovaApp launching")

        environment = AppEnvironment()
        popupController = PopupWindowController(environment: environment)

        // SettingsViewModel이 "메뉴바 표시" 토글을 변경하면 우리에게 콜백.
        environment.menuBarVisibilitySetter = { [weak self] visible in
            self?.setMenuBarIconVisible(visible)
        }

        // 영속된 메뉴바 표시 상태 적용 (기본 true).
        let visibleAtLaunch = Config.UD.bool(Config.UD.showMenuBarIcon, default: true)
        setMenuBarIconVisible(visibleAtLaunch)

        registerHotkey()

        // 단축키 활성/비활성은 register() *다음에* 적용해야 한다.
        let hotkeyOnAtLaunch = Config.UD.bool(Config.UD.hotkeyEnabled, default: true)
        environment.hotkeyService.setEnabled(hotkeyOnAtLaunch)

        observeURLCallback()

        // 첫 실행 또는 AX 권한이 없으면 Onboarding 표시.
        if !AccessibilityService.isTrusted || !UserDefaults.standard.bool(forKey: "didCompleteOnboarding") {
            showOnboarding()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false  // 메뉴바 전용 — 마지막 창 닫혀도 종료 안 함.
    }

    /// Dock 아이콘 클릭 시(메뉴바 숨김 사용자의 안전망) 설정창을 자동으로 띄움.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            showSettings()
        }
        return true
    }

    // MARK: - Status item

    /// 메뉴바 아이콘을 보일지 숨길지 토글.
    /// - 보이기: NSStatusItem 생성 + activation policy = .accessory (Dock 아이콘 없음, LSUIElement 기본 동작)
    /// - 숨기기: NSStatusItem 제거 + activation policy = .regular (Dock 아이콘으로 폴백)
    func setMenuBarIconVisible(_ visible: Bool) {
        if visible {
            showStatusItem()
            NSApp.setActivationPolicy(.accessory)
        } else {
            hideStatusItem()
            NSApp.setActivationPolicy(.regular)
        }
        log.info("menu bar icon \(visible ? "shown" : "hidden", privacy: .public)")
    }

    private func showStatusItem() {
        guard statusItem == nil else { return }  // idempotent

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            // 시스템 심볼을 사용해 light/dark 자동 대응.
            // SF Symbol "character.book.closed" 사용 — 책 아이콘.
            let img = NSImage(systemSymbolName: "character.book.closed",
                              accessibilityDescription: "VocaNova")
            img?.isTemplate = true
            button.image = img
            button.toolTip = "VocaNova"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "클립보드 단어 검색",
                                action: #selector(lookupClipboard),
                                keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "설정…",
                                action: #selector(showSettings),
                                keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "시작하기 다시 보기",
                                action: #selector(showOnboarding),
                                keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "VocaNova 종료",
                                action: #selector(quit),
                                keyEquivalent: "q"))
        // target을 명시해야 NSMenuItem이 first responder를 거치지 않고 우리에게 직접 전달.
        for mi in menu.items { mi.target = self }
        item.menu = menu

        statusItem = item
    }

    private func hideStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }

    // MARK: - Hotkey

    private func registerHotkey() {
        environment.hotkeyService.setDefaultIfUnset()
        environment.hotkeyService.register { [weak self] in
            Task { @MainActor in
                await self?.triggerLookup()
            }
        }
    }

    /// 단축키 또는 메뉴 트리거 진입점.
    private func triggerLookup() async {
        log.info("hotkey triggered")

        // 1) AX 권한 확인. 없으면 Onboarding 띄움.
        guard AccessibilityService.isTrusted else {
            log.notice("AX not trusted; showing onboarding")
            showOnboarding()
            return
        }

        // 2) 선택 텍스트 가져오기 (AX → clipboard fallback).
        let text: String
        do {
            text = try await environment.selectionReader.read()
        } catch {
            log.error("selection read failed: \(error.localizedDescription, privacy: .public)")
            // 빈 텍스트인 상태도 그대로 팝업 에러 화면에 노출.
            await showPopup(query: "", initialError: error)
            return
        }

        await showPopup(query: text, initialError: nil)
    }

    @objc private func lookupClipboard() {
        Task { @MainActor in
            let pb = NSPasteboard.general
            let text = pb.string(forType: .string) ?? ""
            await showPopup(query: text, initialError: text.isEmpty ? AppError.noSelection : nil)
        }
    }

    private func showPopup(query: String, initialError: Error?) async {
        let location = NSEvent.mouseLocation
        let vm = PopupViewModel(query: query, environment: environment, initialError: initialError)
        popupController.show(at: location, viewModel: vm)
    }

    // MARK: - Windows

    @objc private func showSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(environment: environment)
        }
        settingsController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showOnboarding() {
        if onboardingController == nil {
            onboardingController = OnboardingWindowController(environment: environment) { [weak self] in
                UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
                self?.onboardingController?.close()
                self?.onboardingController = nil
            }
        }
        onboardingController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - URL callback (OAuth)

    private func observeURLCallback() {
        // ASWebAuthenticationSession 자체가 콜백을 잡으므로 보통은 필요 없지만,
        // 외부 브라우저에서 vocanova:// URL을 직접 열 가능성을 대비해 등록.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
        log.info("received URL callback")
        // 현재는 ASWebAuthenticationSession이 처리. 미래 확장 자리.
        _ = urlString
    }
}
