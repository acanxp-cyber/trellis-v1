import XCTest
@testable import Trellis

final class VoiceTaskParserTests: XCTestCase {
    func testParsesSpokenItineraryIntoChronologicalDrafts() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        let now = date(hour: 9, minute: 0, calendar: calendar)

        let drafts = VoiceTaskParser().parse(
            "12点给客户打个电话 下午2点开会，要提前5分钟到会议室，下午四点去跑两圈，六点回家去，7点半要去开家长会",
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(
            drafts.map(\.title),
            [
                "给客户打个电话",
                "到会议室开会",
                "去跑两圈",
                "回家",
                "开家长会",
            ]
        )
        XCTAssertEqual(
            drafts.map(\.scheduledAt),
            [
                date(hour: 12, minute: 0, calendar: calendar),
                date(hour: 14, minute: 0, calendar: calendar),
                date(hour: 16, minute: 0, calendar: calendar),
                date(hour: 18, minute: 0, calendar: calendar),
                date(hour: 19, minute: 30, calendar: calendar),
            ]
        )
        XCTAssertEqual(drafts.map(\.reminderLeadMinutes), [0, 5, 0, 0, 0])
    }

    private func date(
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: 2026,
                month: 11,
                day: 11,
                hour: hour,
                minute: minute
            )
        )!
    }
}
