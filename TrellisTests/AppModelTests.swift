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

