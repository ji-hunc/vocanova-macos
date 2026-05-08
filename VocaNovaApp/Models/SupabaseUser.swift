import Foundation

/// Supabase `/auth/v1/user` 응답 — 우리가 실제로 쓰는 필드만.
struct SupabaseUser: Codable, Equatable {
    var id: String
    var email: String?
    var appMetadata: AppMetadata?
    var userMetadata: UserMetadata?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case appMetadata = "app_metadata"
        case userMetadata = "user_metadata"
    }

    struct AppMetadata: Codable, Equatable {
        var provider: String?    // "google", "apple"
    }

    struct UserMetadata: Codable, Equatable {
        var fullName: String?
        var avatarUrl: String?
        var name: String?

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case avatarUrl = "avatar_url"
            case name
        }
    }

    /// 표시용 이름 — 없으면 이메일 prefix.
    var displayName: String {
        userMetadata?.fullName
            ?? userMetadata?.name
            ?? email?.components(separatedBy: "@").first
            ?? "사용자"
    }
}
