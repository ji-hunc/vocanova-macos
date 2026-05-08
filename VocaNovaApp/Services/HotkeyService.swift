import KeyboardShortcuts
import SwiftUI

/// `KeyboardShortcuts` 라이브러리를 한 번 더 감싼 얇은 어댑터.
///
/// 라이브러리는 Carbon `RegisterEventHotKey`를 사용하므로 비활성 상태에서도 작동한다.
/// 같은 이름을 두 번 등록하면 silent no-op이라는 함정이 있어, 등록을 한 곳(이 클래스)으로 모은다.
@MainActor
final class HotkeyService {
    private var registered = false

    /// 사용자가 한 번도 변경한 적 없으면 기본값(⌘⇧F) 적용.
    func setDefaultIfUnset() {
        if KeyboardShortcuts.getShortcut(for: .lookupSelection) == nil {
            KeyboardShortcuts.setShortcut(Config.defaultHotkey, for: .lookupSelection)
        }
    }

    /// 핸들러 등록. 두 번째 호출은 무시되므로 한 번만 호출할 것.
    func register(handler: @escaping () -> Void) {
        guard !registered else {
            Log.hotkey.notice("hotkey already registered — skipping")
            return
        }
        registered = true
        KeyboardShortcuts.onKeyDown(for: .lookupSelection, action: handler)
        Log.hotkey.info("hotkey registered: \(self.currentDescription, privacy: .public)")
    }

    /// 현재 단축키의 사람-읽기용 표현. 설정 화면 등에서 사용.
    var currentDescription: String {
        KeyboardShortcuts.getShortcut(for: .lookupSelection)?.description ?? "(미설정)"
    }
}
