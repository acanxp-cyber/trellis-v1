import XCTest
@testable import Trellis

final class LocalAppRepositoryTests: XCTestCase {
    func testDataSurvivesRepositoryRecreation() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("data.json")
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let firstRepository = try LocalAppRepository(fileURL: fileURL)
        var expected = AppData.empty
        expected.tasks = [
            GrowthTask(
                title: "完成原生持久化",
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                completedAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
        ]
        expected.records = [
            QuickRecord(
                text: "今天完成了第一轮验证。",
                createdAt: Date(timeIntervalSince1970: 1_700_000_100)
            ),
        ]

        try await firstRepository.save(expected)

        let secondRepository = try LocalAppRepository(fileURL: fileURL)
        let restored = try await secondRepository.load()
        XCTAssertEqual(restored, expected)
    }

    func testCorruptFileFailsInsteadOfSilentlyResetting() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("data.json")
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data("{not-json".utf8).write(to: fileURL)

        XCTAssertThrowsError(try LocalAppRepository(fileURL: fileURL))
    }
}

