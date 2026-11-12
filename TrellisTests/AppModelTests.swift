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

    func testClearTodayRemovesOnlyTodayUnfinishedTasksAndCanUndo() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        let now = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 11,
                day: 13,
                hour: 10
            )
        )!
        let repository = InMemoryRepository()
        let todayOpenID = UUID()
        let todayDoneID = UUID()
        let tomorrowID = UUID()
        var data = AppData.empty
        data.tasks = [
            GrowthTask(
                id: todayOpenID,
                title: "今天未完成",
                scheduledAt: now.addingTimeInterval(3_600)
            ),
            GrowthTask(
                id: todayDoneID,
                title: "今天已完成",
                createdAt: now,
                completedAt: now
            ),
            GrowthTask(
                id: tomorrowID,
                title: "明天",
                scheduledAt: now.addingTimeInterval(86_400)
            ),
        ]
        await repository.save(data)
        let model = AppModel(repository: repository)
        await model.bootstrap()

        let receipt = try XCTUnwrap(
            await model.clearUnfinishedTasksToday(now: now)
        )

        XCTAssertEqual(receipt.tasks.map(\.id), [todayOpenID])
        XCTAssertEqual(
            Set(model.data.tasks.map(\.id)),
            Set([todayDoneID, tomorrowID])
        )

        let restored = await model.restoreClearedPlan(receipt)
        XCTAssertTrue(restored)
        XCTAssertEqual(
            Set(model.data.tasks.map(\.id)),
            Set([todayOpenID, todayDoneID, tomorrowID])
        )
    }

    func testRecordPersistsLocalAttachmentMetadata() async throws {
        let repository = InMemoryRepository()
        let model = AppModel(repository: repository)
        await model.bootstrap()
        let recordID = UUID()
        let attachment = RecordAttachment(
            recordID: recordID,
            kind: .photo,
            relativePath: "\(recordID.uuidString)/photo.jpg"
        )

        let didSave = await model.addRecord(
            text: "带照片的记录",
            recordID: recordID,
            attachments: [attachment]
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(model.data.records.first?.id, recordID)
        XCTAssertEqual(model.data.records.first?.attachments, [attachment])
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

