import XCTest
@testable import Trellis

final class FitnessCatalogTests: XCTestCase {
    func testCatalogContainsEightyDistinctActivities() {
        XCTAssertEqual(FitnessCatalog.exercises.count, 80)
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

    func testFuzzyExerciseMatchExpandsPushupIntoRelevantRoutine() {
        for phrase in ["做俯卧撑", "我想做俯撑", "今天来一组俯卧称"] {
            let match = FitnessExerciseMatcher.match(in: phrase)
            XCTAssertEqual(match?.exercise.title, "标准俯卧撑")

            let recommendation = FitnessIntentParser.recommendation(
                from: phrase
            )
            XCTAssertEqual(
                recommendation?.matchedExerciseTitle,
                "标准俯卧撑"
            )
            XCTAssertEqual(recommendation?.focus, .upper)
            XCTAssertEqual(
                recommendation?.blocks[1].items.first?.exercise.title,
                "标准俯卧撑"
            )
        }
    }

    func testSpecificExerciseRoutineStillContainsWarmupAndCooldown() {
        let recommendation = FitnessIntentParser.recommendation(
            from: "练深蹲"
        )

        XCTAssertEqual(recommendation?.matchedExerciseTitle, "徒手深蹲")
        XCTAssertEqual(recommendation?.blocks.count, 3)
        XCTAssertEqual(recommendation?.blocks[1].items.first?.exercise.title, "徒手深蹲")
        XCTAssertFalse(recommendation?.blocks[0].items.isEmpty ?? true)
        XCTAssertFalse(recommendation?.blocks[2].items.isEmpty ?? true)
    }

    func testWorkoutRequestPreservesFiveMinuteStretchDuration() {
        let request = WorkoutIntentParser.parse(
            "上午十点开始，做5分钟的拉伸"
        )

        XCTAssertEqual(request?.focus, .mobility)
        XCTAssertEqual(request?.durationMinutes, 5)
        XCTAssertEqual(request?.hour, 10)
        XCTAssertEqual(request?.minute, 0)
    }

    func testWorkoutRequestPreservesPushupSetsAndReps() {
        let request = WorkoutIntentParser.parse(
            "上午十点开始，做80个俯卧撑一组，共2组"
        )

        XCTAssertEqual(request?.matchedExerciseTitle, "标准俯卧撑")
        XCTAssertEqual(request?.sets, 2)
        XCTAssertEqual(request?.reps, 80)
        XCTAssertNil(request?.durationMinutes)
    }

    func testWorkoutRequestRecognizesEquipmentCardioAndSport() {
        XCTAssertEqual(
            WorkoutIntentParser.parse("用哑铃练上肢")?.activityKind,
            .equipment
        )
        XCTAssertEqual(
            WorkoutIntentParser.parse("出去慢跑30分钟")?.activityKind,
            .cardio
        )
        XCTAssertEqual(
            WorkoutIntentParser.parse("打一小时羽毛球")?.activityKind,
            .sport
        )
    }

    func testExpandedCatalogIncludesEquipmentCardioAndSport() {
        XCTAssertGreaterThanOrEqual(FitnessCatalog.exercises.count, 80)
        XCTAssertFalse(FitnessCatalog.exercises(for: .equipment).isEmpty)
        XCTAssertFalse(FitnessCatalog.exercises(for: .cardio).isEmpty)
        XCTAssertFalse(FitnessCatalog.exercises(for: .sport).isEmpty)
    }

    func testFiveMinuteWorkoutKeepsShortWarmupAndCooldown() {
        let timing = FitnessRoutineTimingPolicy.allocate(
            totalMinutes: 5,
            focus: .upper
        )

        XCTAssertEqual(timing.totalSeconds, 5 * 60)
        XCTAssertLessThanOrEqual(timing.warmupSeconds, 60)
        XCTAssertLessThanOrEqual(timing.cooldownSeconds, 60)
        XCTAssertGreaterThan(timing.mainSeconds, 0)
    }

    func testThirtyMinuteWorkoutCapsTransitionOverhead() {
        let timing = FitnessRoutineTimingPolicy.allocate(
            totalMinutes: 30,
            focus: .fullBody
        )

        XCTAssertEqual(timing.totalSeconds, 30 * 60)
        XCTAssertLessThanOrEqual(
            timing.warmupSeconds + timing.cooldownSeconds,
            120
        )
    }

    func testMobilitySessionDoesNotAddRedundantWarmup() {
        let timing = FitnessRoutineTimingPolicy.allocate(
            totalMinutes: 5,
            focus: .mobility
        )

        XCTAssertEqual(timing.warmupSeconds, 0)
        XCTAssertEqual(timing.totalSeconds, 5 * 60)
    }

    func testExplicitWorkoutUsesAtMostOneWarmupAndOneCooldownItem() {
        let request = WorkoutIntentParser.parse(
            "做80个俯卧撑一组，共2组"
        )
        let recommendation = FitnessIntentParser.recommendation(
            for: try! XCTUnwrap(request)
        )

        XCTAssertEqual(recommendation.blocks[0].items.count, 1)
        XCTAssertEqual(recommendation.blocks[2].items.count, 1)
    }
}
