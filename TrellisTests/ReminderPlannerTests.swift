import XCTest
@testable import Trellis

final class ReminderPlannerTests: XCTestCase {
    func testOnlyFutureRemindersAreScheduled() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let futureTask = GrowthTask(
            title: "开会",
            scheduledAt: now.addingTimeInterval(600),
            reminderAt: now.addingTimeInterval(300)
        )
        let pastTask = GrowthTask(
            title: "已经过去",
            scheduledAt: now.addingTimeInterval(-600),
            reminderAt: now.addingTimeInterval(-300)
        )
        let noReminderTask = GrowthTask(
            title: "不提醒",
            scheduledAt: now.addingTimeInterval(900)
        )

        let plans = ReminderPlanner().plans(
            for: [pastTask, noReminderTask, futureTask],
            now: now
        )

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans[0].taskID, futureTask.id)
        XCTAssertEqual(plans[0].title, "开会")
        XCTAssertEqual(
            plans[0].fireDate,
            now.addingTimeInterval(300)
        )
    }

    func testReminderInsideMinuteGraceIsMovedToImmediateFireDate() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = GrowthTask(
            title: "刚刚到点",
            scheduledAt: now,
            reminderAt: now.addingTimeInterval(-30)
        )

        let plans = ReminderPlanner().plans(for: [task], now: now)

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(
            plans[0].fireDate,
            now.addingTimeInterval(1)
        )
    }

    func testReminderOlderThanGraceWindowIsSkipped() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = GrowthTask(
            title: "已经过去",
            scheduledAt: now,
            reminderAt: now.addingTimeInterval(-61)
        )

        XCTAssertTrue(
            ReminderPlanner().plans(for: [task], now: now).isEmpty
        )
    }
}
