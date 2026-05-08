import Foundation

/// Supabase 인증 세션. Keychain에 JSON 직렬화하여 보관.
///
/// `expiresAt`은 Unix 초. `expires_in`만 받았다면 호출 시점의 `Date.timeIntervalSince1970`에 더해 저장.
struct SupabaseSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: TimeInterval        // unix seconds
    var user: SupabaseUser?

    /// 만료 임박 여부.
    /// `Config.tokenRefreshBufferSeconds`(기본 60초) 이내면 미리 갱신해야 한다.
    var isExpired: Bool {
        Date().timeIntervalSince1970 + Config.tokenRefreshBufferSeconds >= expiresAt
    }
}
