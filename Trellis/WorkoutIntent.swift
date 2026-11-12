import Foundation

enum WorkoutActivityKind: String, Sendable {
    case strength
    case cardio
    case sport
    case mobility
    case equipment
}

struct WorkoutRequest: Equatable, Sendable {
    let focus: FitnessFocus
    let activityKind: WorkoutActivityKind
    let matchedExerciseTitle: String?
    let scheduledAt: Date?
    let hour: Int?
    let minute: Int?
    let durationMinutes: Int?
    let sets: Int?
    let reps: Int?
    let equipment: String?
}

enum WorkoutIntentParser {
    private static let durationRegex = try! NSRegularExpression(
        pattern: #"([0-9]{1,3}|[一二两三四五六七八九十]{1,3})\s*分钟"#
    )
    private static let hourDurationRegex = try! NSRegularExpression(
        pattern: #"([0-9]{1,2}|[一二两三四五六七八九十]{1,3})\s*(?:个)?小时"#
    )
    private static let repsRegex = try! NSRegularExpression(
        pattern: #"([0-9]{1,4})\s*(?:个|次)"#
    )
    private static let setsRegex = try! NSRegularExpression(
        pattern: #"(?:共|总共|做|完成)?\s*([0-9]{1,2})\s*组"#
    )

    static func parse(
        _ transcript: String,
        now: Date = .now
    ) -> WorkoutRequest? {
        guard let focus = FitnessIntentParser.focus(in: transcript) else {
            return nil
        }

        let scheduledAt = VoiceTaskParser().parse(
            transcript,
            now: now
        ).first?.scheduledAt
        let components = scheduledAt.map {
            Calendar.trellis.dateComponents(
                [.hour, .minute],
                from: $0
            )
        }
        let match = FitnessExerciseMatcher.match(in: transcript)
        let equipment = equipment(in: transcript)
        let activityKind = activityKind(
            in: transcript,
            focus: focus
        )

        return WorkoutRequest(
            focus: focus,
            activityKind: activityKind,
            matchedExerciseTitle: match?.exercise.title,
            scheduledAt: scheduledAt,
            hour: components?.hour,
            minute: components?.minute,
            durationMinutes: durationMinutes(in: transcript),
            sets: firstNumber(matching: setsRegex, in: transcript),
            reps: firstNumber(matching: repsRegex, in: transcript),
            equipment: equipment
        )
    }

    private static func durationMinutes(in text: String) -> Int? {
        if let minutes = firstNumber(
            matching: durationRegex,
            in: text
        ) {
            return minutes
        }
        if let hours = firstNumber(
            matching: hourDurationRegex,
            in: text
        ) {
            return hours * 60
        }
        return nil
    }

    private static func firstNumber(
        matching regex: NSRegularExpression,
        in text: String
    ) -> Int? {
        let nsText = text as NSString
        guard
            let match = regex.firstMatch(
                in: text,
                range: NSRange(
                    location: 0,
                    length: nsText.length
                )
            ),
            match.range(at: 1).location != NSNotFound
        else {
            return nil
        }
        return parseNumber(nsText.substring(with: match.range(at: 1)))
    }

    private static func parseNumber(_ text: String) -> Int? {
        if let number = Int(text) {
            return number
        }
        let digits: [Character: Int] = [
            "一": 1, "二": 2, "两": 2, "三": 3, "四": 4,
            "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
        ]
        if text == "十" {
            return 10
        }
        if let index = text.firstIndex(of: "十") {
            let tensText = String(text[..<index])
            let onesText = String(text[text.index(after: index)...])
            let tens = tensText.isEmpty
                ? 1
                : tensText.first.flatMap { digits[$0] } ?? 0
            let ones = onesText.first.flatMap { digits[$0] } ?? 0
            return tens * 10 + ones
        }
        return text.first.flatMap { digits[$0] }
    }

    private static func equipment(in text: String) -> String? {
        let keywords = [
            "哑铃", "杠铃", "弹力带", "壶铃", "胸推机",
            "腿举机", "高位下拉", "跑步机", "椭圆机",
            "动感单车",
        ]
        return keywords.first { text.contains($0) }
    }

    private static func activityKind(
        in text: String,
        focus: FitnessFocus
    ) -> WorkoutActivityKind {
        if equipment(in: text) != nil || focus == .equipment {
            return .equipment
        }
        if focus == .sport
            || containsAny(
                text,
                ["篮球", "足球", "羽毛球", "乒乓球", "网球", "游泳", "骑行", "徒步"]
            )
        {
            return .sport
        }
        if focus == .cardio
            || containsAny(
                text,
                ["跑", "快走", "跳绳", "有氧", "楼梯", "单车"]
            )
        {
            return .cardio
        }
        if focus == .mobility {
            return .mobility
        }
        return .strength
    }

    private static func containsAny(
        _ text: String,
        _ terms: [String]
    ) -> Bool {
        terms.contains { text.contains($0) }
    }
}
