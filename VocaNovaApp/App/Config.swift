import AppKit
import KeyboardShortcuts

/// 앱 전역 설정 상수.
///
/// 모든 외부 엔드포인트, 공개 키, 기본값을 한 곳에 모은다. 빌드 환경별(Debug/Release)
/// 분기가 필요해지면 이 enum을 namespace로 두고 안에서 분기하는 것이 가장 단순하다.
enum Config {
    // MARK: - Supabase

    /// Voca 서비스 공통 Supabase 프로젝트.
    /// 크롬 익스텐션, iOS 앱과 같은 백엔드를 공유한다.
    static let supabaseURL = URL(string: "https://sqhvrnlkjxebkodpghon.supabase.co")!

    /// Supabase publishable(anon) 키. RLS가 걸려 있다는 전제로 클라이언트에 포함해도 안전하다.
    static let supabaseAnonKey = "sb_publishable_5RNRvK8oO4lonBinOBc1Uw_3FWY5WK3"

    // MARK: - OAuth

    /// 커스텀 URL 스킴. Info.plist의 CFBundleURLSchemes와 일치해야 한다.
    static let urlScheme = "vocanova"

    /// OAuth 콜백 URL. Supabase 대시보드의 Redirect URLs에도 등록되어 있어야 한다.
    static let oauthCallbackURL = "vocanova://auth-callback"

    // MARK: - Naver Dictionary

    /// 네이버 영어 사전 검색 엔드포인트. m=mobile, lang=ko 고정.
    static let naverEndpoint = "https://en.dict.naver.com/api3/enko/search?m=mobile&lang=ko&query="

    /// Referer가 없으면 서버가 빈 응답 또는 403을 돌려준다 — 반드시 명시.
    static let naverReferer = "https://en.dict.naver.com"

    /// 빈 UA는 일부 CDN에서 차단됨.
    static let naverUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    // MARK: - 토큰 / 단축키 / 팝업

    /// access token 만료 X초 전부터는 미리 refresh.
    static let tokenRefreshBufferSeconds: TimeInterval = 60

    /// 기본 단축키: ⌘⇧F.
    /// 사용자가 한 번이라도 변경하면 KeyboardShortcuts가 UserDefaults에 저장하므로 그 값이 우선.
    static let defaultHotkey = KeyboardShortcuts.Shortcut(.f, modifiers: [.command, .shift])

    /// 팝업 카드 너비 (pt). voca-extension의 360px와 동일.
    static let popupWidth: CGFloat = 360

    /// 팝업 카드 최대 높이. 초과 시 스크롤.
    static let popupMaxHeight: CGFloat = 480

    /// 팝업 페이드인 시간.
    static let popupFadeDuration: TimeInterval = 0.12

    /// 외부 클릭 모니터 등록 지연 (등록 직후 자체 클릭에 닫히는 버그 방지).
    static let outsideClickMonitorDelay: TimeInterval = 0.05

    // MARK: - Keychain

    /// Keychain service 이름. 기본은 bundle id.
    static var keychainService: String {
        Bundle.main.bundleIdentifier ?? "app.vocanova.macos"
    }

    /// 세션 저장 키.
    static let sessionKeychainKey = "supabase.session"
}
