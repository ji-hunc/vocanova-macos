import AppKit
import ApplicationServices

/// macOS Accessibility(AX) API 래퍼.
///
/// 핵심: `AXUIElementCopyAttributeValue`로 *현재 포커스된* UI 요소의 선택 텍스트를 읽는다.
/// 이게 작동하려면:
///   1) 앱이 비-샌드박스여야 함 (entitlements에서 `app-sandbox = false`)
///   2) 사용자가 시스템 설정 → 개인정보 보호 → 손쉬운 사용에서 우리 앱을 켜야 함
///
/// 시스템은 우리 앱의 (bundle id + 코드 사인 신원) 쌍에 권한을 부여한다.
/// 사인 신원이 바뀌면 권한이 무효화되어 "선택 텍스트 비어있음"으로 보인다 — 개발 중 유의.
@MainActor
final class AccessibilityService {

    /// 권한 상태 — 다이얼로그 띄우지 않고 단순 조회.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// 권한이 없을 때 시스템 다이얼로그를 띄운다 (번들 ID + 사인 신원당 한 번만 표시).
    /// 반환값은 *호출 시점* 기준 권한 여부 — 다이얼로그를 막 띄운 직후엔 보통 false.
    @discardableResult
    static func promptIfNeeded() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: [String: Bool] = [key: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// 시스템 설정의 손쉬운 사용 패널을 직접 연다.
    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// 시스템 전체에서 현재 포커스된 UI 요소의 선택 텍스트를 읽는다.
    /// - Throws: `AppError.accessibilityDenied` (권한 없음) / `.noSelection` (선택 비어있음)
    func readFocusedSelectedText() throws -> String {
        guard Self.isTrusted else { throw AppError.accessibilityDenied }

        let systemWide = AXUIElementCreateSystemWide()

        // 1) 포커스된 요소.
        var focusedRef: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        guard focusedStatus == .success, let cfElement = focusedRef else {
            Log.ax.notice("no focused element (\(focusedStatus.rawValue))")
            throw AppError.noSelection
        }
        // CFTypeRef → AXUIElement (둘은 toll-free bridge되지 않으므로 unsafeBitCast 사용).
        let focused = cfElement as! AXUIElement

        // 2) 선택 텍스트.
        var selectedRef: CFTypeRef?
        let selectedStatus = AXUIElementCopyAttributeValue(
            focused,
            kAXSelectedTextAttribute as CFString,
            &selectedRef
        )
        guard selectedStatus == .success, let str = selectedRef as? String else {
            Log.ax.notice("no selected text on focused element (\(selectedStatus.rawValue))")
            throw AppError.noSelection
        }
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw AppError.noSelection }
        return trimmed
    }
}
