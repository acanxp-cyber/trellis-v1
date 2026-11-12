import XCTest
@testable import Trellis

final class FitnessCatalogTests: XCTestCase {
    func testCatalogContainsFiftyDistinctBodyweightExercises() {
        XCTAssertEqual(FitnessCatalog.exercises.count, 50)
        XCTAssertEqual(
            Set(FitnessCatalog.exercises.map(\.id)).count,
            FitnessCatalog.exercises.count
        )
        XCTAssertTrue(
            FitnessCatalog.exercises.allSatisfy {
                !$0.method.isEmpty
                    && !$0.prescription.isEmpty
                    && !$0.adjustment.isEmpty
            }
        )
    }

    func testCatalogHasExercisesForEveryFocus() {
        XCTAssertEqual(FitnessCatalog.exercises(for: .upper).count, 12)
        XCTAssertEqual(FitnessCatalog.exercises(for: .lower).count, 10)
        XCTAssertEqual(FitnessCatalog.exercises(for: .core).count, 10)
        XCTAssertEqual(FitnessCatalog.exercises(for: .fullBody).count, 10)
        XCTAssertEqual(FitnessCatalog.exercises(for: .mobility).count, 8)
    }

    func testVoicePhrasesRecommendGroupedRoutines() {
        let cases: [(String, FitnessFocus)] = [
            ("帮我练上半身", .upper),
            ("练上肢", .upper),
            ("今天练腿和臀", .lower),
            ("练核心", .core),
            ("做一次全身训练", .fullBody),
            ("做点拉伸放松", .mobility),
        ]

        for (phrase, expectedFocus) in cases {
            let recommendation = FitnessIntentParser.recommendation(
                from: phrase
            )
            XCTAssertEqual(recommendation?.focus, expectedFocus)
            XCTAssertEqual(recommendation?.blocks.count, 3)
            XCTAssertTrue(
                recommendation?.blocks.allSatisfy {
                    !$0.items.isEmpty
                } == true
            )
        }
    }

    func testNonFitnessPhraseDoesNotCreateRecommendation() {
        XCTAssertNil(
            FitnessIntentParser.recommendation(from: "下午两点开会")
        )
    }
}
