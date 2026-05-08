import AppKit

/// 플로팅 팝업으로 사용할 NSPanel.
///
/// 설계 포인트:
/// - `.nonactivatingPanel`: 우리가 떠도 사용자가 보고 있던 앱은 활성 상태 유지.
/// - `canBecomeKey = true` (KeyablePanel 상속): ESC 키 이벤트를 받으려면 key 윈도우가 되어야 함.
///   `becomesKeyOnlyIfNeeded = true`이라 makeKey()를 명시 호출했을 때만 key가 된다.
/// - `.borderless` + `.fullSizeContentView`: 우리가 SwiftUI로 그린 카드를 그대로 노출.
/// - `level = .floating`: 거의 모든 일반 윈도우 위에. 풀스크린 상위가 필요하면 statusBar+1로 상승.
/// - `collectionBehavior`: 모든 Space에서 보이고, 풀스크린 보조 윈도우로도 동작 + transient 표시
///   → Mission Control이 우리를 일반 윈도우처럼 다루지 않게 한다.
final class PopupPanel: KeyablePanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.becomesKeyOnlyIfNeeded = true
        self.worksWhenModal = true
        self.hidesOnDeactivate = false
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true

        // 호스팅 contentView에 둥근 모서리.
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 12
        self.contentView?.layer?.masksToBounds = true
    }

    override var acceptsFirstResponder: Bool { true }
}
