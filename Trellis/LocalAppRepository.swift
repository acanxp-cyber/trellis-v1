import Foundation

protocol AppRepository: Sendable {
    func load() async throws -> AppData
    func save(_ data: AppData) async throws
    func exportData() async throws -> Data
}

enum LocalAppRepositoryError: LocalizedError {
    case cannotCreateDirectory(Error)
    case cannotRead(Error)
    case cannotDecode(Error)
    case cannotEncode(Error)
    case cannotWrite(Error)

    var errorDescription: String? {
        switch self {
        case .cannotCreateDirectory:
            return "无法创建本地数据目录。"
        case .cannotRead:
            return "无法读取本地数据。"
        case .cannotDecode:
            return "本地数据格式无法识别，原文件已保留。"
        case .cannotEncode:
            return "无法生成数据备份。"
        case .cannotWrite:
            return "无法写入本地数据，请检查设备存储空间。"
        }
    }
}

actor LocalAppRepository: AppRepository {
    private let fileURL: URL
    private var cachedData: AppData

    init(fileURL: URL, fileManager: FileManager = .default) throws {
        self.fileURL = fileURL

        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Self.excludeFromBackup(
                fileURL.deletingLastPathComponent(),
                fileManager: fileManager
            )
        } catch {
            throw LocalAppRepositoryError.cannotCreateDirectory(error)
        }

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                self.cachedData = try Self.decoder.decode(AppData.self, from: data)
            } catch let error as LocalAppRepositoryError {
                throw error
            } catch {
                if error is DecodingError {
                    throw LocalAppRepositoryError.cannotDecode(error)
                }
                throw LocalAppRepositoryError.cannotRead(error)
            }
        } else {
            self.cachedData = .empty
        }
    }

    static func makeDefault(fileManager: FileManager = .default) throws -> LocalAppRepository {
        let baseDirectory: URL
        do {
            baseDirectory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            throw LocalAppRepositoryError.cannotCreateDirectory(error)
        }

        let directory = baseDirectory.appendingPathComponent(
            "Trellis",
            isDirectory: true
        )
        let fileURL = directory.appendingPathComponent("app-data-v1.json")
        return try LocalAppRepository(fileURL: fileURL, fileManager: fileManager)
    }

    func load() async throws -> AppData {
        cachedData
    }

    func save(_ data: AppData) async throws {
        let encoded: Data
        do {
            encoded = try Self.encoder.encode(data)
        } catch {
            throw LocalAppRepositoryError.cannotEncode(error)
        }

        do {
            try encoded.write(
                to: fileURL,
                options: [.atomic, .completeFileProtection]
            )
            cachedData = data
        } catch {
            throw LocalAppRepositoryError.cannotWrite(error)
        }
    }

    func exportData() async throws -> Data {
        do {
            return try Self.encoder.encode(cachedData)
        } catch {
            throw LocalAppRepositoryError.cannotEncode(error)
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

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

actor UnavailableAppRepository: AppRepository {
    private let startupError: Error

    init(startupError: Error) {
        self.startupError = startupError
    }

    func load() async throws -> AppData {
        throw startupError
    }

    func save(_ data: AppData) async throws {
        throw startupError
    }

    func exportData() async throws -> Data {
        throw startupError
    }
}

