import Foundation
import ServiceManagement

/// macOS 13+ `SMAppService` 기반 시작 시 실행 토글.
///
/// `SMAppService.mainApp`은 별도 helper bundle 없이 메인 앱 자체를 로그인 항목으로 등록한다.
/// 진실의 원천은 OS이므로 UserDefaults에 별도 미러링하지 않고, 매번 `status`를 조회한다.
///
/// 주의:
/// - 코드 사인 안 된 dev 빌드는 `register()`가 실패하거나 `.notFound` 상태가 될 수 있다.
///   Developer ID로 사인된 Release 빌드에서 최종 검증할 것.
/// - 사용자가 한 번 거부하면 상태가 `.requiresApproval`로 남아 시스템 설정에서 직접 켜야 한다.
@MainActor
final class LaunchAtLoginService {

    /// 로그인 항목으로 활성화되어 있고 OS의 승인이 끝난 상태인가.
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// macOS가 사용자에게 한 번 더 승인을 요구하는 상태인가.
    /// UI에서 "시스템 설정 → 일반 → 로그인 항목" 안내 버튼을 띄우는 신호.
    var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// 디버그/로그용 한국어 상태 문자열.
    var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .notRegistered: return "등록 안 됨"
        case .enabled: return "활성"
        case .requiresApproval: return "승인 필요"
        case .notFound: return "찾을 수 없음 (사인 미완 빌드?)"
        @unknown default: return "알 수 없음"
        }
    }

    /// 등록/해제. throw하면 caller(`SettingsViewModel`)가 토글을 revert하고 에러를 표시.
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        Log.app.info("LaunchAtLogin → \(self.statusDescription, privacy: .public)")
    }
}
