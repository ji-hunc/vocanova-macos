import XCTest
@testable import VocaNovaApp

/// 실제 키체인 접근 테스트. CI 환경에 따라 실패할 수 있어 로컬 한정 권장.
final class KeychainStoreTests: XCTestCase {

    private let service = "app.vocanova.macos.tests"
    private let key = "test-roundtrip"
    private var store: KeychainStore!

    override func setUp() {
        super.setUp()
        store = KeychainStore(service: service)
        try? store.delete(forKey: key)
    }

    override func tearDown() {
        try? store.delete(forKey: key)
        super.tearDown()
    }

    func testSetAndGetData() throws {
        let original = "hello-keychain".data(using: .utf8)!
        try store.setData(original, forKey: key)

        let read = try store.getData(forKey: key)
        XCTAssertEqual(read, original)
    }

    func testOverwrite() throws {
        try store.setData(Data([0x00]), forKey: key)
        try store.setData(Data([0xFF]), forKey: key)
        let read = try store.getData(forKey: key)
        XCTAssertEqual(read, Data([0xFF]))
    }

    func testDelete() throws {
        try store.setData(Data([0x01]), forKey: key)
        try store.delete(forKey: key)
        XCTAssertNil(try store.getData(forKey: key))
    }
}
