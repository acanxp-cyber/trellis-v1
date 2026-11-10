import Foundation

struct GrowthTask: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var title: String
    var area: String
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        area: String = "成长",
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.area = area
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var isCompleted: Bool {
        completedAt != nil
    }
}

struct QuickRecord: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
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
    static let currentSchemaVersion = 1

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

