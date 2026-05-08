import AppKit

/// 비활성 패널이 ESC 키를 받도록 하기 위한 보조.
///
/// `NSPanel(.nonactivatingPanel)`은 기본적으로 `canBecomeKey`가 false라
/// `keyDown` 이벤트가 들어오지 않는다. 이 옵션이 켜져 있으면 앱이 활성화되지 않고도
/// 패널이 key 윈도우가 될 수 있어 ESC 처리가 가능해진다.
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
