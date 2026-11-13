import Foundation

enum SpokenAlarmTextBuilder {
    private static let maximumCharacters = 42

    static func text(for title: String) -> String {
        let compact = title
            .replacingOccurrences(of: "\n", with: "，")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let prefix = "提醒："
        let available = max(4, maximumCharacters - prefix.count)
        let content = compact.isEmpty ? "时间到了" : compact
        return prefix + String(content.prefix(available))
    }

    static func fileName(for taskID: UUID) -> String {
        "task-spoken-\(taskID.uuidString).caf"
    }
}
