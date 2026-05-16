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

    /// 사용자가 "권한 부여 시작" 버튼을 눌러 시스템 설정을 띄운 적이 있는지.
    /// 누른 뒤에는 + 버튼 추가 가이드 카드를 노출한다.
    @Published var didOpenSettings: Bool = false

    private var pollTimer: Timer?

    init() {
        if isAXTrusted { step = .hotkey }
    }

    /// OS의 접근성 권한 요청 다이얼로그를 띄운다. Developer ID + 노타라이즈된
    /// 빌드에서는 prompt만으로 시스템이 손쉬운 사용 목록에 VocaNova를 자동 등록하므로
    /// (사용자는 다이얼로그의 "시스템 설정 열기" 누른 뒤 토글만 켜면 됨), 별도로
    /// `openSystemSettings()`를 동시에 부르지 않는다 — 그러면 창 두 개가 뜬다.
    func requestAccessibility() {
        Log.ax.info("requestAccessibility(): triggering OS prompt")
        _ = AccessibilityService.promptIfNeeded()
        didOpenSettings = true
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
