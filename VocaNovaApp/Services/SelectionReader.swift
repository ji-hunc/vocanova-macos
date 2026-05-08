import Foundation

/// AX 우선 시도 후 실패하면 클립보드 fallback으로 폴백하는 통합 진입점.
@MainActor
final class SelectionReader {
    private let accessibility: AccessibilityService
    private let clipboard: ClipboardService

    init(accessibility: AccessibilityService, clipboard: ClipboardService) {
        self.accessibility = accessibility
        self.clipboard = clipboard
    }

    /// 선택 텍스트를 읽어 반환. 둘 다 실패하면 throw.
    func read() async throws -> String {
        do {
            let text = try accessibility.readFocusedSelectedText()
            Log.ax.info("selection via AX (\(text.count) chars)")
            return text
        } catch AppError.accessibilityDenied {
            // 권한 자체가 없으면 fallback도 의미 없음 (CGEvent도 권한 필요).
            throw AppError.accessibilityDenied
        } catch {
            // AX는 성공했지만 비어있거나 다른 이유로 실패 → 클립보드 시도.
            Log.ax.notice("AX read failed (\(error.localizedDescription, privacy: .public)) — trying clipboard fallback")
            let text = try await clipboard.copySelectionViaShortcut()
            Log.ax.info("selection via clipboard fallback (\(text.count) chars)")
            return text
        }
    }
}
