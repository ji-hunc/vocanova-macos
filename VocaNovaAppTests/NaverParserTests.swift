import XCTest
@testable import VocaNovaApp

final class NaverParserTests: XCTestCase {

    func loadFixture() throws -> NaverResponse {
        let bundle = Bundle(for: NaverParserTests.self)
        guard let url = bundle.url(forResource: "naver_sample_response", withExtension: "json") else {
            // 테스트 번들 리소스로 들어오지 않은 경우 — 디스크에서 직접 로드.
            let path = "VocaNovaAppTests/Fixtures/naver_sample_response.json"
            let absolutePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(path)
            let data = try Data(contentsOf: absolutePath)
            return try JSONDecoder().decode(NaverResponse.self, from: data)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(NaverResponse.self, from: data)
    }

    func testParsesNavigateFixture() throws {
        let response = try loadFixture()
        let snapshot = try XCTUnwrap(NaverParser.parse(response))

        XCTAssertEqual(snapshot.word, "navigate")
        XCTAssertEqual(snapshot.source, "옥스퍼드 영한사전")
    }

    func testNormalizesIPA() throws {
        let response = try loadFixture()
        let snapshot = try XCTUnwrap(NaverParser.parse(response))

        // 미국식 IPA의 <sub>│</sub>가 ˌ로, <sup>│</sup>가 ˈ로 치환되었어야 함.
        let us = snapshot.pronunciations.first { $0.label == "미국식" }
        XCTAssertNotNil(us)
        XCTAssertTrue(us!.ipa.contains("ˌ"))
        XCTAssertTrue(us!.ipa.contains("ˈ"))
        XCTAssertFalse(us!.ipa.contains("<"))
    }

    func testParsesPosAndMeanings() throws {
        let response = try loadFixture()
        let snapshot = try XCTUnwrap(NaverParser.parse(response))

        XCTAssertEqual(snapshot.partsOfSpeech.count, 1)
        XCTAssertEqual(snapshot.partsOfSpeech[0].pos, "동사")
        XCTAssertEqual(snapshot.partsOfSpeech[0].meanings.count, 2)

        let m1 = snapshot.partsOfSpeech[0].meanings[0]
        XCTAssertTrue(m1.exampleEn?.contains("<strong>navigated</strong>") ?? false)
        XCTAssertEqual(m1.exampleKo, "그는 폭풍을 뚫고 배의 항로를 잡았다.")
    }

    func testSplitsSynonyms() throws {
        let response = try loadFixture()
        let snapshot = try XCTUnwrap(NaverParser.parse(response))

        XCTAssertEqual(snapshot.synonyms.count, 2)
        XCTAssertEqual(snapshot.synonyms[0].word, "steer")
        XCTAssertTrue(snapshot.synonyms[0].url.hasPrefix("https://"))
    }
}
