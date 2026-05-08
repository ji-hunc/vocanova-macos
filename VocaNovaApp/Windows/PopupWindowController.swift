import AppKit
import SwiftUI

/// 팝업 표시 / 위치 / 닫힘 처리.
///
/// 라이프사이클:
///   show(at:viewModel:) → 패널 생성/재사용 → SwiftUI 마운트 → 화면 좌표 클램프 → fade-in → 모니터 등록
///   ESC / 외부 클릭 / 같은 단축키 재발화 → close() → 모니터 제거 → ViewModel cancel
@MainActor
final class PopupWindowController: NSObject, NSWindowDelegate {
    private let environment: AppEnvironment

    private var panel: PopupPanel?
    private var hostingView: NSHostingView<PopupContainer>?
    private var currentViewModel: PopupViewModel?

    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func show(at point: NSPoint, viewModel: PopupViewModel) {
        // 진행 중인 팝업이 있으면 정리.
        if panel != nil { close() }

        let auth = AuthViewModel(sessionStore: environment.sessionStore)
        // 로그인 성공 → 자동 저장 재시도 트리거.
        auth.setOnLoginSuccess { [weak viewModel] in
            viewModel?.didCompleteLogin()
        }

        let container = PopupContainer(
            popup: viewModel,
            auth: auth,
            session: environment.sessionStore,
            audio: environment.audioPlayer,
            onClose: { [weak self] in
                Task { @MainActor in self?.close() }
            }
        )

        let hosting = NSHostingView(rootView: container)
        // 콘텐츠가 자라되 최대 높이로 클램프.
        hosting.translatesAutoresizingMaskIntoConstraints = false

        let initialSize = NSSize(width: Config.popupWidth, height: Config.popupMaxHeight)
        let panel = PopupPanel(contentRect: NSRect(origin: .zero, size: initialSize))
        panel.contentView = NSView(frame: NSRect(origin: .zero, size: initialSize))
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 12
        panel.contentView?.layer?.masksToBounds = true
        panel.contentView?.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: panel.contentView!.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor),
        ])
        panel.delegate = self

        // 위치: 마우스 우하단 8pt 오프셋, 화면 visibleFrame 안으로 클램프.
        let frame = computeFrame(near: point, contentSize: initialSize)
        panel.setFrame(frame, display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()  // ESC 받기 위해 명시적으로 key.

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = Config.popupFadeDuration
            panel.animator().alphaValue = 1
        }

        self.panel = panel
        self.hostingView = hosting
        self.currentViewModel = viewModel

        // 모니터 등록은 약간 지연 — 등록 직후 자체 클릭에 닫히는 버그 방지.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Config.outsideClickMonitorDelay * 1_000_000_000))
            self.installMonitors()
        }

        // 검색 시작.
        viewModel.startLoadIfNeeded()
    }

    func close() {
        removeMonitors()
        currentViewModel?.cancel()
        currentViewModel = nil
        if let panel {
            // 부드러운 페이드아웃.
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = Config.popupFadeDuration
                panel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                self?.panel?.orderOut(nil)
                self?.panel = nil
                self?.hostingView = nil
            })
        }
    }

    // MARK: - 위치 계산

    private func computeFrame(near mouse: NSPoint, contentSize: NSSize) -> NSRect {
        // 마우스가 위치한 화면 결정.
        let screen = NSScreen.screens.first { NSPointInRect(mouse, $0.frame) }
            ?? NSScreen.main
            ?? NSScreen.screens.first

        let visible = screen?.visibleFrame ?? .zero

        // 기본: 마우스 우측 8pt, 아래로 8pt 오프셋. 좌측 상단 기준.
        var origin = NSPoint(x: mouse.x + 8, y: mouse.y - contentSize.height - 8)

        // 우측 클램프.
        if origin.x + contentSize.width > visible.maxX {
            origin.x = visible.maxX - contentSize.width - 8
        }
        // 좌측 클램프.
        if origin.x < visible.minX {
            origin.x = visible.minX + 8
        }
        // 아래 클램프 (화면 밖이면 마우스 위로).
        if origin.y < visible.minY {
            origin.y = mouse.y + 8
        }
        // 위 클램프.
        if origin.y + contentSize.height > visible.maxY {
            origin.y = visible.maxY - contentSize.height - 8
        }

        return NSRect(origin: origin, size: contentSize)
    }

    // MARK: - 이벤트 모니터

    private func installMonitors() {
        // 외부 (다른 앱 / 데스크탑) 클릭 → 닫기.
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            Task { @MainActor in self?.close() }
        }
        // 로컬 키 다운 → ESC 닫기 (이벤트 swallow). ⌘⇧F 다시 눌러도 닫기.
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            [weak self] event in
            // ESC: keyCode 53.
            if event.keyCode == 53 {
                Task { @MainActor in self?.close() }
                return nil
            }
            return event
        }
    }

    private func removeMonitors() {
        if let m = globalClickMonitor {
            NSEvent.removeMonitor(m)
            globalClickMonitor = nil
        }
        if let m = localKeyMonitor {
            NSEvent.removeMonitor(m)
            localKeyMonitor = nil
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // 외부에서 close() 거치지 않고 닫힐 경우 대비.
        removeMonitors()
        currentViewModel?.cancel()
        currentViewModel = nil
        panel = nil
        hostingView = nil
    }
}
