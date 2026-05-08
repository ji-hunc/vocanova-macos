import XCTest
@testable import VocaNovaApp

final class SessionStoreTests: XCTestCase {

    func testIsExpiredHonorsBuffer() {
        let now = Date().timeIntervalSince1970

        // 만료까지 30초 — 버퍼(60초)보다 작으므로 만료됨으로 간주.
        let soon = SupabaseSession(accessToken: "a", refreshToken: "b", expiresAt: now + 30, user: nil)
        XCTAssertTrue(soon.isExpired)

        // 만료까지 600초 — 안전.
        let later = SupabaseSession(accessToken: "a", refreshToken: "b", expiresAt: now + 600, user: nil)
        XCTAssertFalse(later.isExpired)
    }

    func testSessionRoundTripsAsJSON() throws {
        let user = SupabaseUser(
            id: "user-1",
            email: "test@example.com",
            appMetadata: .init(provider: "google"),
            userMetadata: .init(fullName: "테스터", avatarUrl: nil, name: nil)
        )
        let session = SupabaseSession(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: 1_700_000_000,
            user: user
        )
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(SupabaseSession.self, from: data)
        XCTAssertEqual(decoded, session)
        XCTAssertEqual(decoded.user?.displayName, "테스터")
    }
}
