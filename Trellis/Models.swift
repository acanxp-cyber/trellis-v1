import Foundation

struct GrowthTask: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var title: String
    var area: String
    var createdAt: Date
    var completedAt: Date?
    var scheduledAt: Date?
    var reminderAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        area: String = "成长",
        createdAt: Date = .now,
        completedAt: Date? = nil,
        scheduledAt: Date? = nil,
        reminderAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.area = area
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.scheduledAt = scheduledAt
        self.reminderAt = reminderAt
    }

    var isCompleted: Bool {
        completedAt != nil
    }
}

enum RecordAttachmentKind: String, Codable, Sendable {
    case photo
    case video
    case audio
    case drawing
    case pixelArt
    case stickerArtwork
}

struct RecordAttachment: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let recordID: UUID
    let kind: RecordAttachmentKind
    let relativePath: String
    var durationSeconds: Double?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        recordID: UUID,
        kind: RecordAttachmentKind,
        relativePath: String,
        durationSeconds: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.recordID = recordID
        self.kind = kind
        self.relativePath = relativePath
        self.durationSeconds = durationSeconds
        self.createdAt = createdAt
    }
}

struct QuickRecord: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var text: String
    var createdAt: Date
    var attachments: [RecordAttachment]

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = .now,
        attachments: [RecordAttachment] = []
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.attachments = attachments
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case createdAt
        case attachments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        attachments = try container.decodeIfPresent(
            [RecordAttachment].self,
            forKey: .attachments
        ) ?? []
    }
}

struct ClearPlanReceipt: Identifiable, Sendable, Equatable {
    let id: UUID
    let tasks: [GrowthTask]

    init(id: UUID = UUID(), tasks: [GrowthTask]) {
        self.id = id
        self.tasks = tasks
    }
}

struct WeeklyReview: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var weekStart: Date
    var wins: String
    var shift: String
    var focus: [String]
    var completedAt: Date

    init(
        id: UUID = UUID(),
        weekStart: Date,
        wins: String,
        shift: String,
        focus: [String],
        completedAt: Date = .now
    ) {
        self.id = id
        self.weekStart = weekStart
        self.wins = wins
        self.shift = shift
        self.focus = Array(focus.prefix(3))
        self.completedAt = completedAt
    }

    static func startOfWeek(containing date: Date, calendar: Calendar = .trellis) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    static func isValid(wins: String, focus: [String]) -> Bool {
        !wins.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && focus.count == 3
            && focus.allSatisfy {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }
}

struct AppData: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var tasks: [GrowthTask]
    var records: [QuickRecord]
    var reviews: [WeeklyReview]

    init(
        schemaVersion: Int = AppData.currentSchemaVersion,
        tasks: [GrowthTask] = [],
        records: [QuickRecord] = [],
        reviews: [WeeklyReview] = []
    ) {
        self.schemaVersion = schemaVersion
        self.tasks = tasks
        self.records = records
        self.reviews = reviews
    }

    static let empty = AppData()
}

extension Calendar {
    static var trellis: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }
}

