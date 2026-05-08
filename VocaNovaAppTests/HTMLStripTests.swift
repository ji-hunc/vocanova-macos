import XCTest
@testable import VocaNovaApp

final class HTMLStripTests: XCTestCase {

    func testStripsAllTags() {
        let raw = "Hello <em>world</em>, <a href='x'>navigate</a>!"
        XCTAssertEqual(NaverParser.stripHTML(raw), "Hello world, navigate!")
    }

    func testDecodesCommonEntities() {
        XCTAssertEqual(NaverParser.stripHTML("a &amp; b"), "a & b")
        XCTAssertEqual(NaverParser.stripHTML("&quot;quoted&quot;"), "\"quoted\"")
        XCTAssertEqual(NaverParser.stripHTML("&nbsp;space"), " space")
    }

    func testSanitizeExamplePreservesStrong() {
        let raw = "Can you <em>see</em> the <strong>navigate</strong> button?"
        let result = NaverParser.sanitizeExample(raw)
        XCTAssertTrue(result.contains("<strong>navigate</strong>"))
        XCTAssertFalse(result.contains("<em>"))
    }

    func testNormalizeIPAStressMarks() {
        let raw = "ˈnæ<sub>│</sub>vəˌ<sup>│</sup>geɪt"
        let normalized = NaverParser.normalizeIPA(raw)
        XCTAssertFalse(normalized.contains("<"))
        XCTAssertTrue(normalized.contains("ˈ"))
        XCTAssertTrue(normalized.contains("ˌ"))
    }

    func testParsePipeListBasic() {
        let raw = "race^https://a.com|jog^https://b.com"
        let parsed = NaverParser.parsePipeList(raw)
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[0].word, "race")
        XCTAssertEqual(parsed[1].word, "jog")
    }

    func testParsePipeListEmpty() {
        XCTAssertTrue(NaverParser.parsePipeList(nil).isEmpty)
        XCTAssertTrue(NaverParser.parsePipeList("").isEmpty)
    }

    func testParsePipeListWithoutURLs() {
        let raw = "race|jog|sprint"
        let parsed = NaverParser.parsePipeList(raw)
        XCTAssertEqual(parsed.count, 3)
        XCTAssertEqual(parsed.map(\.word), ["race", "jog", "sprint"])
        XCTAssertEqual(parsed[0].url, "")
    }
}
