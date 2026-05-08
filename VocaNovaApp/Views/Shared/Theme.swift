import AppKit
import SwiftUI

/// 색/폰트/간격 토큰. 크롬 익스텐션 popup.css 값과 1:1 매칭.
///
/// 색은 모두 dynamic — `NSColor(name:dynamicProvider:)`로 light/dark 두 변종을
/// 들고 있다가 윈도우의 effective appearance에 따라 자동으로 골라진다.
/// 따라서 `NSApp.appearance`를 바꾸면 (또는 시스템 설정이 바뀌면) 별도 새로고침
/// 없이 모든 화면이 즉시 새 색으로 다시 그려진다.
enum Theme {
    // MARK: - Colors

    /// 브랜드 액센트(파랑). 다크에선 살짝 더 밝게 — 어두운 배경에서 콘트라스트 확보.
    static let accent = dynamic(
        light: NSColor(red: 0x2D / 255, green: 0x6C / 255, blue: 0xDF / 255, alpha: 1),
        dark:  NSColor(red: 0x5B / 255, green: 0x8D / 255, blue: 0xEF / 255, alpha: 1)
    )

    /// 액센트 위에 얹는 옅은 칩 배경. 다크에선 깊은 네이비.
    static let accentSoft = dynamic(
        light: NSColor(red: 0xEA / 255, green: 0xF1 / 255, blue: 0xFF / 255, alpha: 1),
        dark:  NSColor(red: 0x1F / 255, green: 0x2D / 255, blue: 0x4F / 255, alpha: 1)
    )

    /// 카드 배경. 시스템 windowBackgroundColor가 이미 light/dark 자동 대응.
    static let surface = Color(.windowBackgroundColor)

    /// 본문 글자색. 다크에서 검정 그대로 두면 안 보이는 게 사용자 보고 핵심 이슈였음.
    static let primaryText = dynamic(
        light: NSColor(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255, alpha: 1),
        dark:  NSColor(red: 0xF3 / 255, green: 0xF4 / 255, blue: 0xF6 / 255, alpha: 1)
    )

    static let secondaryText = dynamic(
        light: NSColor(red: 0x6B / 255, green: 0x72 / 255, blue: 0x80 / 255, alpha: 1),
        dark:  NSColor(red: 0xA1 / 255, green: 0xA7 / 255, blue: 0xB3 / 255, alpha: 1)
    )

    static let tertiaryText = dynamic(
        light: NSColor(red: 0x9C / 255, green: 0xA3 / 255, blue: 0xAF / 255, alpha: 1),
        dark:  NSColor(red: 0x6B / 255, green: 0x72 / 255, blue: 0x80 / 255, alpha: 1)
    )

    static let border = dynamic(
        light: NSColor(red: 0xE5 / 255, green: 0xE7 / 255, blue: 0xEB / 255, alpha: 1),
        dark:  NSColor(red: 0x3A / 255, green: 0x3D / 255, blue: 0x44 / 255, alpha: 1)
    )

    /// 예문 박스 배경. 본문 카드와 미세하게 구분되도록 한 단계 어둡거나 밝게.
    static let exampleBg = dynamic(
        light: NSColor(red: 0xF7 / 255, green: 0xF8 / 255, blue: 0xFA / 255, alpha: 1),
        dark:  NSColor(red: 0x26 / 255, green: 0x28 / 255, blue: 0x2D / 255, alpha: 1)
    )

    /// 저장 완료(성공) 표시 — 흰 글씨와 충분한 대비.
    static let success = dynamic(
        light: NSColor(red: 0x16 / 255, green: 0xA3 / 255, blue: 0x4A / 255, alpha: 1),
        dark:  NSColor(red: 0x22 / 255, green: 0xC5 / 255, blue: 0x5E / 255, alpha: 1)
    )

    /// 에러/재시도 표시 — 흰 글씨와 충분한 대비.
    static let danger = dynamic(
        light: NSColor(red: 0xDC / 255, green: 0x35 / 255, blue: 0x45 / 255, alpha: 1),
        dark:  NSColor(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255, alpha: 1)
    )

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

    // MARK: - Helpers

    /// light/dark 두 NSColor를 dynamic provider로 감싸 SwiftUI Color로 노출.
    /// `Color(NSColor)`는 NSColor의 dynamic 동작을 그대로 보존하므로 윈도우의
    /// effective appearance에 따라 매 draw 시 적절한 변종이 선택된다.
    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}
