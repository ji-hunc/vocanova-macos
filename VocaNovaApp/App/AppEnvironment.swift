import Foundation

/// 서비스 싱글톤 컨테이너.
///
/// SwiftUI의 `@Environment`는 뷰 트리 안에서만 유효하므로, ViewModel·NSWindowController처럼
/// 뷰 외부에서 살아가는 객체에 의존성을 주입하려면 별도 컨테이너가 필요하다. AppDelegate가
/// 한 번 만들어 모든 곳에 전달한다.
@MainActor
final class AppEnvironment {
    let httpClient: HTTPClient
    let naverService: NaverDictionaryService
    let supabaseClient: SupabaseClient
    let supabaseAuth: SupabaseAuthService
    let vocabService: VocabService
    let keychain: KeychainStore
    let sessionStore: SessionStore
    let hotkeyService: HotkeyService
    let audioPlayer: AudioPlayer
    let selectionReader: SelectionReader
    let launchAtLogin: LaunchAtLoginService

    /// AppDelegate가 자기 메서드를 주입한다. SettingsViewModel이 이걸 호출해
    /// 메뉴바 아이콘 표시/숨김을 토글한다. AppDelegate가 만들어지지 않은 시점엔 nil.
    var menuBarVisibilitySetter: ((Bool) -> Void)?

    init() {
        let httpClient = HTTPClient()
        let keychain = KeychainStore(service: Config.keychainService)
        let supabaseClient = SupabaseClient(baseURL: Config.supabaseURL, anonKey: Config.supabaseAnonKey)
        let supabaseAuth = SupabaseAuthService(client: supabaseClient, http: httpClient)
        let sessionStore = SessionStore(keychain: keychain, key: Config.sessionKeychainKey, auth: supabaseAuth)
        let vocabService = VocabService(client: supabaseClient, http: httpClient, session: sessionStore)
        let naverService = NaverDictionaryService(http: httpClient)
        let hotkey = HotkeyService()
        let audio = AudioPlayer()
        let accessibility = AccessibilityService()
        let clipboard = ClipboardService()
        let reader = SelectionReader(accessibility: accessibility, clipboard: clipboard)
        let launchAtLogin = LaunchAtLoginService()

        self.httpClient = httpClient
        self.keychain = keychain
        self.supabaseClient = supabaseClient
        self.supabaseAuth = supabaseAuth
        self.sessionStore = sessionStore
        self.vocabService = vocabService
        self.naverService = naverService
        self.hotkeyService = hotkey
        self.audioPlayer = audio
        self.selectionReader = reader
        self.launchAtLogin = launchAtLogin
    }
}
