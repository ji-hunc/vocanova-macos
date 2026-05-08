import AppKit

/// 선택 텍스트의 fallback 경로.
///
/// AX API가 비어있는 결과를 돌려주는 환경(일부 Electron 앱, PDF 뷰어, 보호된 web view 등)에서는
/// 합성 ⌘C 키스트로크를 보내고 클립보드를 읽는 방식이 사실상 유일한 보편 해법이다.
///
/// 트레이드오프:
/// - 타겟 앱의 포커스된 입력에 ⌘C가 그대로 전달됨 → 일부 보안/금융 앱은 이를 차단할 수 있다.
/// - 사용자 클립보드를 잠시 덮어쓴 뒤 복원하므로 다른 클립보드 매니저와 충돌할 수 있다.
@MainActor
final class ClipboardService {

    /// 합성 ⌘C로 선택을 복사하고, 새 텍스트를 읽은 뒤 원래 클립보드를 복원.
    func copySelectionViaShortcut() async throws -> String {
        let pasteboard = NSPasteboard.general

        // 1) 원본 클립보드 스냅샷.
        let original = snapshot(pasteboard)
        let beforeChange = pasteboard.changeCount

        // 2) 합성 ⌘C 전송.
        postCommandC()

        // 3) changeCount가 바뀔 때까지 최대 200ms 대기.
        let deadline = Date().addingTimeInterval(0.2)
        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 15_000_000)
            if pasteboard.changeCount != beforeChange { break }
        }

        // 4) 새 텍스트 읽기.
        let copied = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 5) 원본 복원 — 항상 수행.
        defer { restore(pasteboard, items: original) }

        guard let text = copied, !text.isEmpty else {
            throw AppError.noSelection
        }
        return text
    }

    // MARK: - 내부

    /// 모든 type별 데이터를 보존.
    private func snapshot(_ pb: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        guard let items = pb.pasteboardItems else { return [] }
        return items.map { item in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict
        }
    }

    private func restore(_ pb: NSPasteboard, items: [[NSPasteboard.PasteboardType: Data]]) {
        pb.clearContents()
        let restored = items.map { dict -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in dict {
                item.setData(data, forType: type)
            }
            return item
        }
        if !restored.isEmpty {
            pb.writeObjects(restored)
        }
    }

    /// 가상 키 0x08 == 'c'.
    private let kVK_ANSI_C: CGKeyCode = 0x08

    private func postCommandC() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }

        let down = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_C, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: source, virtualKey: kVK_ANSI_C, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)
    }
}
