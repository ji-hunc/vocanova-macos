import Foundation
import os

/// `os.Logger`의 카테고리별 facade.
///
/// Console.app에서 subsystem `app.vocanova.macos`로 필터링 가능.
/// 토큰 등 민감 데이터는 `redacted(_:)`를 거쳐 앞 8자만 노출.
enum Log {
    static let subsystem = Bundle.main.bundleIdentifier ?? "app.vocanova.macos"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    static let ax = Logger(subsystem: subsystem, category: "ax")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let popup = Logger(subsystem: subsystem, category: "popup")

    /// 토큰처럼 민감한 문자열을 짧게 잘라 로그용으로.
    static func redacted(_ token: String?) -> String {
        guard let token, !token.isEmpty else { return "<nil>" }
        return String(token.prefix(8)) + "…"
    }
}
