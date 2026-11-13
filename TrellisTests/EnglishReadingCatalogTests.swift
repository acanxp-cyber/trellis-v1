import XCTest
@testable import Trellis

final class EnglishReadingCatalogTests: XCTestCase {
    func testCatalogContainsOneHundredCompletePassages() throws {
        let passages = try EnglishReadingCatalog.load()

        XCTAssertEqual(passages.count, 100)
        XCTAssertEqual(Set(passages.map(\.id)).count, 100)
    }

    func testPassagesFitThirtySecondReadingPractice() throws {
        let passages = try EnglishReadingCatalog.load()

        for passage in passages {
            let words = passage.english.split(whereSeparator: \.isWhitespace)
            XCTAssertGreaterThanOrEqual(words.count, 45, passage.id)
            XCTAssertLessThanOrEqual(words.count, 100, passage.id)
            XCTAssertFalse(passage.chinese.isEmpty, passage.id)
            XCTAssertGreaterThanOrEqual(passage.vocabulary.count, 2, passage.id)
            XCTAssertTrue(
                passage.vocabulary.allSatisfy {
                    $0.ipa.hasPrefix("/") && $0.ipa.hasSuffix("/")
                },
                passage.id
            )
        }
    }

    func testRandomNextDoesNotImmediatelyRepeat() {
        let ids = (0..<100).map(\.description)
        var deck = ReadingPassageDeck(ids: ids, currentID: ids[0])

        for _ in 0..<50 {
            let previous = deck.currentID
            deck.next()
            XCTAssertNotEqual(deck.currentID, previous)
        }
    }
}
