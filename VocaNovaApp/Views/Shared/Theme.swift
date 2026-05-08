import SwiftUI

/// 색/폰트/간격 토큰. 크롬 익스텐션 popup.css 값과 1:1 매칭.
enum Theme {
    // MARK: - Colors
    static let accent = Color(red: 0x2D / 255, green: 0x6C / 255, blue: 0xDF / 255)
    static let accentSoft = Color(red: 0xEA / 255, green: 0xF1 / 255, blue: 0xFF / 255)
    static let surface = Color(.windowBackgroundColor)
    static let primaryText = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255)
    static let secondaryText = Color(red: 0x6B / 255, green: 0x72 / 255, blue: 0x80 / 255)
    static let tertiaryText = Color(red: 0x9C / 255, green: 0xA3 / 255, blue: 0xAF / 255)
    static let border = Color(red: 0xE5 / 255, green: 0xE7 / 255, blue: 0xEB / 255)
    static let exampleBg = Color(red: 0xF7 / 255, green: 0xF8 / 255, blue: 0xFA / 255)

    /// 저장 완료 상태(성공) 표시용. 진한 초록 — 흰 글씨와 충분한 대비.
    static let success = Color(red: 0x16 / 255, green: 0xA3 / 255, blue: 0x4A / 255)
    /// 에러/재시도 상태 표시용 — 흰 글씨와 충분한 대비.
    static let danger = Color(red: 0xDC / 255, green: 0x35 / 255, blue: 0x45 / 255)

    // MARK: - Spacing / radius
    static let cornerRadius: CGFloat = 12
    static let chipRadius: CGFloat = 6
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 14

    // MARK: - Typography (포인트는 macOS의 .system 기반 — 기존 popup.css의 px와 비슷한 비례).
    static let titleFont = Font.system(size: 22, weight: .bold)
    static let posBadgeFont = Font.system(size: 11, weight: .semibold)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let definitionFont = Font.system(size: 13, weight: .medium)
    static let exampleFont = Font.system(size: 12, weight: .regular).italic()
    static let translationFont = Font.system(size: 12, weight: .regular)
    static let chipFont = Font.system(size: 11, weight: .medium)
    static let footerFont = Font.system(size: 11, weight: .regular)
    static let ipaFont = Font.system(size: 12, weight: .regular).monospaced()
}
