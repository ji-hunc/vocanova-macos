import Foundation

/// Supabase 인증 세션. Keychain에 JSON 직렬화하여 보관.
///
/// `expiresAt`은 Unix 초. `expires_in`만 받았다면 호출 시점의 `Date.timeIntervalSince1970`에 더해 저장.
///
/// `lastProvider`: 클라이언트에서 직접 추적하는 "방금 어떤 방식으로 로그인했는지".
/// Supabase의 `app_metadata.provider`는 *최초 가입 시* provider라 같은 이메일로 다른 provider로
/// 로그인하면 잘못된 값이 나온다. 이걸 우선해서 표시한다.
/// 옵셔널이므로 기존 keychain 데이터(이 필드 없음)도 호환됨.
struct SupabaseSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: TimeInterval        // unix seconds
    var user: SupabaseUser?
    var lastProvider: String?          // "google" / "apple" / nil

    /// 만료 임박 여부.
    /// `Config.tokenRefreshBufferSeconds`(기본 60초) 이내면 미리 갱신해야 한다.
    var isExpired: Bool {
        Date().timeIntervalSince1970 + Config.tokenRefreshBufferSeconds >= expiresAt
    }
}
