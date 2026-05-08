import Combine
import Foundation
import SwiftUI

/// AX 권한 → 단축키 안내 → 완료 단계 진행.
///
/// 시스템 설정에서 사용자가 토글을 켜면 자동으로 다음 단계로 넘어가도록 폴링한다 (TCC는 알림 없음).
@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case accessibility, hotkey, done
    }

    @Published var step: Step = .accessibility
    @Published var isAXTrusted: Bool = AccessibilityService.isTrusted

    private var pollTimer: Timer?

    init() {
        if isAXTrusted { step = .hotkey }
    }

    /// 권한 다이얼로그 띄우고, 사용자가 토글할 때까지 폴링.
    func requestAccessibility() {
        AccessibilityService.promptIfNeeded()
        AccessibilityService.openSystemSettings()
        startPolling()
    }

    func goToNext() {
        let next = Step(rawValue: step.rawValue + 1) ?? .done
        step = next
    }

    func goToPrevious() {
        let prev = Step(rawValue: step.rawValue - 1) ?? .accessibility
        step = prev
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    deinit {
        // @MainActor에서 deinit 호출이라 직접 invalidate 가능
        pollTimer?.invalidate()
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let trusted = AccessibilityService.isTrusted
                self.isAXTrusted = trusted
                if trusted {
                    self.stopPolling()
                    if self.step == .accessibility { self.goToNext() }
                }
            }
        }
    }
}
