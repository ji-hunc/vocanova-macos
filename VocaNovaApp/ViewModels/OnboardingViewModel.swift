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

    /// 시스템 설정의 손쉬운 사용 패널을 연다. 사용자는 거기서 + 버튼으로
    /// VocaNova를 직접 추가해야 한다.
    ///
    /// macOS 15+가 Apple Development 인증서 + sandbox 조합의 prompt-path 자동 등록을
    /// 차단하기 때문에 (AX 프레임워크가 tccd로 요청을 보내기 전에 짧게 거부),
    /// `AXIsProcessTrustedWithOptions(prompt:true)`로는 목록에 항목이 자동 추가되지
    /// 않는다. Developer ID + 노타라이즈로 가기 전까지는 + 버튼으로 직접 추가하는
    /// 게 유일한 경로. 호출은 그래도 남겨둔다 — 미래 macOS에서 정책이 바뀌면 즉시
    /// 자동 등록될 수 있게.
    func requestAccessibility() {
        Log.ax.info("requestAccessibility(): opening Settings for manual + add")
        _ = AccessibilityService.promptIfNeeded()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3s
            AccessibilityService.openSystemSettings()
        }
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
