import AppKit
import ApplicationServices

/// macOS Accessibility(AX) API 래퍼.
///
/// 핵심: `AXUIElementCopyAttributeValue`로 *현재 포커스된* UI 요소의 선택 텍스트를 읽는다.
/// 이게 작동하려면:
///   1) 사용자가 시스템 설정 → 개인정보 보호 → 손쉬운 사용에서 우리 앱을 켜야 함
///   2) 앱이 한 번 등록되어 있어야 함 (`promptIfNeeded()` 또는 사용자가 직접 + 추가)
///
/// 시스템은 우리 앱의 (bundle id + 코드 사인 신원) 쌍에 권한을 부여한다.
/// 사인 신원이 바뀌면 권한이 무효화되어 "선택 텍스트 비어있음"으로 보인다 — 개발 중 유의.
/// Sandboxed 앱도 사용자가 손쉬운 사용 권한을 부여하면 cross-process AX API 사용 가능
/// (Magnet, Rectangle 등 MAS 앱이 같은 패턴).
@MainActor
final class AccessibilityService {

    /// 권한 상태 조회. nil options = prompt 없이 현재 상태 반환 (Apple 표준).
    ///
    /// `[:] as CFDictionary`로 빈 dictionary를 만들면 일부 환경에서 잘못된 참조로
    /// 변환되어 EXC_BAD_ACCESS가 발생한다 — `nil` 전달이 documented 안전 경로.
    /// 캐시 문제가 의심되면 호출자 쪽에서 짧은 폴링 + 앱 재시작 안내로 우회한다.
    static var isTrusted: Bool {
        AXIsProcessTrustedWithOptions(nil)
    }

    /// 권한이 없을 때 시스템 다이얼로그를 띄운다 (번들 ID + 사인 신원당 한 번만 표시).
    /// 반환값은 *호출 시점* 기준 권한 여부 — 다이얼로그를 막 띄운 직후엔 보통 false.
    /// dev/TestFlight 빌드에서 자동 등록이 종종 실패하므로 결과를 로그에 남긴다.
    @discardableResult
    static func promptIfNeeded() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: [String: Bool] = [key: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        Log.ax.info("AXIsProcessTrustedWithOptions(prompt:true) → \(trusted, privacy: .public)")
        return trusted
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
