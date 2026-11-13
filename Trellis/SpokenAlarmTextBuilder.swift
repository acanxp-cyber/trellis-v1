import Foundation

enum TaskTitleNormalizer {
    private static let leadingFillers = [
        "记得提醒我",
        "请提醒我",
        "提醒我",
        "叫我",
    ]

    static func normalizedTitle(_ rawTitle: String) -> String {
        var title = rawTitle.trimmingCharacters(
            in: .whitespacesAndNewlines.union(
                CharacterSet(charactersIn: " ,，。；;：:")
            )
        )

        var didStripFiller = true
        while didStripFiller {
            didStripFiller = false
            for filler in leadingFillers where title.hasPrefix(filler) {
                title.removeFirst(filler.count)
                title = title.trimmingCharacters(
                    in: .whitespacesAndNewlines.union(
                        CharacterSet(charactersIn: " ,，。；;：:")
                    )
                )
                didStripFiller = true
                break
            }
        }
        return title
    }
}

enum SpokenAlarmTextBuilder {
    private static let maximumCharacters = 42

    static func text(
        for title: String,
        scheduledAt: Date,
        fireDate: Date,
        calendar: Calendar = .trellis
    ) -> String {
        let leadMinutes = max(
            0,
            Int(
                (scheduledAt.timeIntervalSince(fireDate) / 60)
                    .rounded()
            )
        )
        let time = timeLabel(for: scheduledAt, calendar: calendar)
        let prefix = leadMinutes > 0
            ? "还有\(leadMinutes)分钟到\(time)，"
            : "\(time)到了，"
        return speechText(title: title, prefix: prefix)
    }

    static func text(for title: String) -> String {
        speechText(title: title, prefix: "")
    }

    private static func speechText(
        title: String,
        prefix: String
    ) -> String {
        let compact = TaskTitleNormalizer.normalizedTitle(title)
            .replacingOccurrences(of: "\n", with: "，")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let suffix = "囉"
        let available = max(1, maximumCharacters - prefix.count - suffix.count)
        let content = compact.isEmpty ? "安排" : compact
        return prefix + String(content.prefix(available)) + suffix
    }

    private static func timeLabel(
        for date: Date,
        calendar: Calendar
    ) -> String {
        let components = calendar.dateComponents(
            [.hour, .minute],
            from: date
        )
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        if minute == 0 {
            return "\(hour)点"
        }
        if minute == 30 {
            return "\(hour)点半"
        }
        return "\(hour)点\(minute)分"
    }

    static func fileName(
        for taskID: UUID,
        profile: AlarmVoiceProfile
    ) -> String {
        "task-spoken-\(taskID.uuidString)-\(profile.rawValue).caf"
    }
}
