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

    func testSchemaOneRecordDecodesWithEmptyAttachments() throws {
        let recordID = UUID()
        let json = """
        {
          "schemaVersion": 1,
          "tasks": [],
          "records": [
            {
              "id": "\(recordID.uuidString)",
              "text": "旧版本记录",
              "createdAt": "2026-11-13T02:00:00Z"
            }
          ],
          "reviews": []
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(AppData.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.records.first?.text, "旧版本记录")
        XCTAssertEqual(decoded.records.first?.attachments, [])
    }

    func testRecordMediaStoreKeepsFilesLocalAndDeletesThem() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let store = try RecordMediaStore(baseDirectory: directory)
        let recordID = UUID()

        let attachment = try await store.save(
            Data("local-media".utf8),
            recordID: recordID,
            kind: .photo,
            fileExtension: "jpg"
        )

        XCTAssertEqual(attachment.recordID, recordID)
        XCTAssertEqual(attachment.kind, .photo)
        XCTAssertFalse(attachment.relativePath.hasPrefix("/"))
        let savedURL = try await store.url(for: attachment)
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: savedURL.path
            )
        )

        try await store.delete(attachment)
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: savedURL.path
            )
        )
    }

    func testRecordMediaStoreDeletesEveryFileForARecord() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let store = try RecordMediaStore(baseDirectory: directory)
        let recordID = UUID()
        let photo = try await store.save(
            Data("photo".utf8),
            recordID: recordID,
            kind: .photo,
            fileExtension: "jpg"
        )
        let video = try await store.save(
            Data("video".utf8),
            recordID: recordID,
            kind: .video,
            fileExtension: "mov"
        )
        let photoURL = try await store.url(for: photo)
        let videoURL = try await store.url(for: video)

        try await store.deleteRecordDirectory(recordID)

        XCTAssertFalse(FileManager.default.fileExists(atPath: photoURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: videoURL.path))
    }
}

