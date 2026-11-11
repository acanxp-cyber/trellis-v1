import XCTest
@testable import Trellis

@MainActor
final class AppModelTests: XCTestCase {
    func testAddAndToggleTaskPersists() async {
        let repository = InMemoryRepository()
        let model = AppModel(repository: repository)

        await model.bootstrap()
        let didAdd = await model.addTask(title: "写下一步")
        XCTAssertTrue(didAdd)
        XCTAssertEqual(model.data.tasks.count, 1)

        let taskID = try! XCTUnwrap(model.data.tasks.first?.id)
        await model.toggleTask(id: taskID)

        XCTAssertTrue(model.data.tasks[0].isCompleted)
        let saved = await repository.currentData()
        XCTAssertEqual(saved, model.data)
    }

    func testReviewRequiresExactlyThreeNonEmptyFocuses() async {
        let repository = InMemoryRepository()
        let model = AppModel(repository: repository)
        await model.bootstrap()

        let invalidReviewSaved = await model.completeReview(
            wins: "完成了持久化",
            shift: "更清楚",
            focus: ["一", "", "三"]
        )
        XCTAssertFalse(invalidReviewSaved)
        XCTAssertTrue(model.data.reviews.isEmpty)

        let validReviewSaved = await model.completeReview(
            wins: "完成了持久化",
            shift: "更清楚",
            focus: ["一", "二", "三"]
        )
        XCTAssertTrue(validReviewSaved)
        XCTAssertEqual(model.data.reviews.count, 1)
        XCTAssertEqual(model.data.reviews[0].focus, ["一", "二", "三"])
    }

    func testAddScheduledTaskPersistsTimeAndReminder() async throws {
        let repository = InMemoryRepository()
        let model = AppModel(repository: repository)
        await model.bootstrap()

        let scheduledAt = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = VoiceTaskDraft(
            title: "到会议室开会",
            scheduledAt: scheduledAt,
            reminderLeadMinutes: 5
        )

        let didAdd = await model.addScheduledTasks([draft])

        XCTAssertTrue(didAdd)
        let task = try XCTUnwrap(model.data.tasks.first)
        XCTAssertEqual(task.title, "到会议室开会")
        XCTAssertEqual(task.scheduledAt, scheduledAt)
        XCTAssertEqual(
            task.reminderAt,
            scheduledAt.addingTimeInterval(-300)
        )

        let saved = await repository.currentData()
        XCTAssertEqual(saved.tasks, model.data.tasks)
    }

    func testOpenTasksSortTimedTasksChronologically() async {
        let repository = InMemoryRepository()
        let model = AppModel(repository: repository)
        await model.bootstrap()

        let later = VoiceTaskDraft(
            title: "晚一点",
            scheduledAt: Date(timeIntervalSince1970: 1_800_000_600)
        )
        let earlier = VoiceTaskDraft(
            title: "先做",
            scheduledAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        await model.addScheduledTasks([later, earlier])
        await model.addTask(title: "没有时间的任务")

        XCTAssertEqual(
            model.openTasks.map(\.title),
            ["先做", "晚一点", "没有时间的任务"]
        )
    }
}

private actor InMemoryRepository: AppRepository {
    private var data = AppData.empty

    func load() async throws -> AppData {
        data
    }

    func save(_ data: AppData) async throws {
        self.data = data
    }

    func exportData() async throws -> Data {
        try JSONEncoder().encode(data)
    }

    func currentData() -> AppData {
        data
    }
}

