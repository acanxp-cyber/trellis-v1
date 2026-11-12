import Foundation

enum RecordMediaStoreError: LocalizedError {
    case cannotCreateDirectory(Error)
    case cannotWrite(Error)
    case cannotRead(Error)
    case invalidRelativePath

    var errorDescription: String? {
        switch self {
        case .cannotCreateDirectory:
            return "无法创建本地媒体目录。"
        case .cannotWrite:
            return "无法保存本地媒体文件。"
        case .cannotRead:
            return "无法读取本地媒体文件。"
        case .invalidRelativePath:
            return "媒体文件路径无效。"
        }
    }
}

actor RecordMediaStore {
    private let baseDirectory: URL
    private let fileManager = FileManager.default

    init(baseDirectory: URL) throws {
        self.baseDirectory = baseDirectory.standardizedFileURL
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                at: baseDirectory,
                withIntermediateDirectories: true
            )
            try Self.excludeFromBackup(
                baseDirectory,
                fileManager: fileManager
            )
        } catch {
            throw RecordMediaStoreError.cannotCreateDirectory(error)
        }
    }

    static func makeDefault(
        fileManager: FileManager = .default
    ) throws -> RecordMediaStore {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base
            .appendingPathComponent("Trellis", isDirectory: true)
            .appendingPathComponent("RecordMedia", isDirectory: true)
        return try RecordMediaStore(baseDirectory: directory)
    }

    func save(
        _ data: Data,
        recordID: UUID,
        kind: RecordAttachmentKind,
        fileExtension: String,
        durationSeconds: Double? = nil,
        createdAt: Date = .now
    ) throws -> RecordAttachment {
        let safeExtension = fileExtension
            .lowercased()
            .filter { $0.isLetter }
        let attachmentID = UUID()
        let directory = baseDirectory.appendingPathComponent(
            recordID.uuidString,
            isDirectory: true
        )
        let filename = safeExtension.isEmpty
            ? attachmentID.uuidString
            : "\(attachmentID.uuidString).\(safeExtension)"

        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try data.write(
                to: directory.appendingPathComponent(filename),
                options: [.atomic, .completeFileProtection]
            )
        } catch {
            throw RecordMediaStoreError.cannotWrite(error)
        }

        return RecordAttachment(
            id: attachmentID,
            recordID: recordID,
            kind: kind,
            relativePath: "\(recordID.uuidString)/\(filename)",
            durationSeconds: durationSeconds,
            createdAt: createdAt
        )
    }

    func data(for attachment: RecordAttachment) throws -> Data {
        do {
            return try Data(contentsOf: try url(for: attachment))
        } catch let error as RecordMediaStoreError {
            throw error
        } catch {
            throw RecordMediaStoreError.cannotRead(error)
        }
    }

    func url(for attachment: RecordAttachment) throws -> URL {
        let candidate = baseDirectory
            .appendingPathComponent(attachment.relativePath)
            .standardizedFileURL
        let basePath = baseDirectory.path + "/"
        guard candidate.path.hasPrefix(basePath) else {
            throw RecordMediaStoreError.invalidRelativePath
        }
        return candidate
    }

    func delete(_ attachment: RecordAttachment) throws {
        let fileURL = try url(for: attachment)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    private static func excludeFromBackup(
        _ directory: URL,
        fileManager: FileManager
    ) throws {
        guard fileManager.fileExists(atPath: directory.path) else {
            return
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDirectory = directory
        try mutableDirectory.setResourceValues(values)
    }
}
