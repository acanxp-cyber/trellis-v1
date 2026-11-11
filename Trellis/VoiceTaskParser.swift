import Foundation

struct VoiceTaskDraft: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var scheduledAt: Date
    var reminderLeadMinutes: Int

    init(
        id: UUID = UUID(),
        title: String,
        scheduledAt: Date,
        reminderLeadMinutes: Int = 0
    ) {
        self.id = id
        self.title = title
        self.scheduledAt = scheduledAt
        self.reminderLeadMinutes = reminderLeadMinutes
    }

    var reminderAt: Date {
        scheduledAt.addingTimeInterval(
            -Double(reminderLeadMinutes * 60)
        )
    }
}

struct VoiceTaskParser {
    private struct TimeMatch {
        let range: Range<String.Index>
        let hour: Int
        let minute: Int
        let period: String?
    }

    private let timeRegex: NSRegularExpression
    private let reminderRegex: NSRegularExpression

    init() {
        timeRegex = try! NSRegularExpression(
            pattern: #"(?:(明天|今天|后天)?\s*(凌晨|早上|上午|中午|下午|傍晚|晚上)?\s*)?([0-9]{1,2}|[零〇一二两三四五六七八九十]{1,3})\s*(?:[:：点时])\s*(半|[0-9]{1,2}|[零〇一二两三四五六七八九十]{1,3})?\s*分?"#
        )
        reminderRegex = try! NSRegularExpression(
            pattern: #"(?:提前|提早)\s*([0-9]{1,2}|[零〇一二两三四五六七八九十]{1,3})\s*(?:分钟|分)"#
        )
    }

    func parse(
        _ transcript: String,
        now: Date = .now,
        calendar: Calendar = .trellis
    ) -> [VoiceTaskDraft] {
        let normalized = normalize(transcript)
        let nsText = normalized as NSString
        let matches = timeRegex.matches(
            in: normalized,
            range: NSRange(location: 0, length: nsText.length)
        )
        guard !matches.isEmpty else {
            return []
        }

        var previousDate: Date?
        var drafts: [VoiceTaskDraft] = []

        for (index, match) in matches.enumerated() {
            guard
                let fullRange = Range(match.range, in: normalized),
                let hourText = capture(3, from: match, in: nsText),
                let parsedHour = parseNumber(hourText),
                let resolvedDate = resolveDate(
                    hour: parsedHour,
                    minute: parseMinute(capture(4, from: match, in: nsText)),
                    period: capture(2, from: match, in: nsText),
                    after: previousDate,
                    now: now,
                    calendar: calendar
                )
            else {
                continue
            }

            let contentStart = fullRange.upperBound
            let contentEnd = index + 1 < matches.count
                ? Range(
                    matches[index + 1].range,
                    in: normalized
                )?.lowerBound ?? normalized.endIndex
                : normalized.endIndex
            let content = String(normalized[contentStart..<contentEnd])
            let extraction = extractReminder(from: content)
            let title = cleanedTitle(from: extraction.content)

            guard !title.isEmpty else {
                continue
            }

            drafts.append(
                VoiceTaskDraft(
                    title: title,
                    scheduledAt: resolvedDate,
                    reminderLeadMinutes: extraction.leadMinutes
                )
            )
            previousDate = resolvedDate
        }

        return drafts.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private func normalize(_ value: String) -> String {
        value
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "。", with: ",")
            .replacingOccurrences(of: "；", with: ",")
            .replacingOccurrences(of: "\u{00a0}", with: " ")
    }

    private func capture(
        _ index: Int,
        from match: NSTextCheckingResult,
        in text: NSString
    ) -> String? {
        guard
            index < match.numberOfRanges,
            match.range(at: index).location != NSNotFound
        else {
            return nil
        }
        return text.substring(with: match.range(at: index))
    }

    private func resolveDate(
        hour rawHour: Int,
        minute: Int,
        period: String?,
        after previousDate: Date?,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        let lowerBound = previousDate ?? now
        let baseDay = calendar.startOfDay(for: lowerBound)
        var candidates: [Date] = []

        if let period, !period.isEmpty {
            let hour = explicitHour(rawHour, period: period)
            if let date = date(
                day: baseDay,
                hour: hour,
                minute: minute,
                dayOffset: 0,
                calendar: calendar
            ) {
                candidates.append(date)
            }
        } else if rawHour > 12 {
            if let date = date(
                day: baseDay,
                hour: rawHour,
                minute: minute,
                dayOffset: 0,
                calendar: calendar
            ) {
                candidates.append(date)
            }
        } else {
            for hour in Set([rawHour, rawHour == 12 ? 12 : rawHour + 12]) {
                if let date = date(
                    day: baseDay,
                    hour: hour,
                    minute: minute,
                    dayOffset: 0,
                    calendar: calendar
                ) {
                    candidates.append(date)
                }
            }
        }

        candidates.sort()
        if let candidate = candidates.first(where: {
            $0 >= lowerBound.addingTimeInterval(-1)
        }) {
            return candidate
        }

        guard
            let earliest = candidates.first,
            let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: earliest
            )
        else {
            return nil
        }
        return nextDay
    }

    private func explicitHour(_ hour: Int, period: String) -> Int {
        switch period {
        case "下午", "傍晚", "晚上":
            return hour < 12 ? hour + 12 : hour
        case "中午":
            return hour < 6 ? hour + 12 : hour
        case "凌晨":
            return hour == 12 ? 0 : hour
        default:
            return hour
        }
    }

    private func date(
        day: Date,
        hour: Int,
        minute: Int,
        dayOffset: Int,
        calendar: Calendar
    ) -> Date? {
        guard
            let shiftedDay = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: day
            )
        else {
            return nil
        }
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: shiftedDay
        )
    }

    private func parseMinute(_ value: String?) -> Int {
        guard let value, !value.isEmpty else {
            return 0
        }
        if value == "半" {
            return 30
        }
        return parseNumber(value) ?? 0
    }

    private func parseNumber(_ value: String) -> Int? {
        if let number = Int(value) {
            return number
        }

        let digits: [Character: Int] = [
            "零": 0, "〇": 0, "一": 1, "二": 2, "两": 2, "三": 3,
            "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
        ]

        if value == "十" {
            return 10
        }

        if let tenIndex = value.firstIndex(of: "十") {
            let before = String(value[..<tenIndex])
            let after = String(value[value.index(after: tenIndex)...])
            let tens = before.isEmpty ? 1 : (parseSingleDigit(before, digits) ?? 0)
            let ones = after.isEmpty ? 0 : (parseSingleDigit(after, digits) ?? 0)
            return tens * 10 + ones
        }

        return parseSingleDigit(value, digits)
    }

    private func parseSingleDigit(
        _ value: String,
        _ digits: [Character: Int]
    ) -> Int? {
        guard value.count == 1, let character = value.first else {
            return nil
        }
        return digits[character]
    }

    private func extractReminder(
        from content: String
    ) -> (content: String, leadMinutes: Int) {
        guard
            let match = reminderRegex.firstMatch(
                in: content,
                range: NSRange(
                    location: 0,
                    length: (content as NSString).length
                )
            ),
            let fullRange = Range(match.range, in: content),
            let numberText = capture(
                1,
                from: match,
                in: content as NSString
            ),
            let minutes = parseNumber(numberText)
        else {
            return (content, 0)
        }

        var cleaned = content
        cleaned.removeSubrange(fullRange)
        return (cleaned, max(0, minutes))
    }

    private func cleanedTitle(from content: String) -> String {
        let clauses = content
            .components(separatedBy: CharacterSet(charactersIn: ",.、;；"))
            .map(cleanClause)
            .filter { !$0.isEmpty }

        guard !clauses.isEmpty else {
            return ""
        }

        if
            clauses.count >= 2,
            clauses[0].hasSuffix("开会"),
            clauses[1].hasPrefix("到")
        {
            return clauses[1] + clauses[0]
        }

        return clauses.joined(separator: "，")
    }

    private func cleanClause(_ value: String) -> String {
        var result = value.trimmingCharacters(
            in: .whitespacesAndNewlines.union(
                CharacterSet(charactersIn: " ,.，。；;")
            )
        )

        for prefix in ["然后", "接着", "要去", "要", "请"] {
            if result.hasPrefix(prefix) {
                result.removeFirst(prefix.count)
                result = result.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                break
            }
        }

        if result.hasSuffix("去"), result.count > 1 {
            result.removeLast()
        }
        return result
    }
}
