import XCTest
@testable import Trellis

final class RecordStudioTests: XCTestCase {
    func testFinishedAudioRestartsFromBeginning() {
        let id = UUID()
        var state = ReplayableAudioState()

        state.toggle(attachmentID: id, duration: 12)
        state.markFinished()
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.position, 12, accuracy: 0.01)

        state.toggle(attachmentID: id, duration: 12)
        XCTAssertTrue(state.isPlaying)
        XCTAssertEqual(state.position, 0, accuracy: 0.01)
    }

    func testAudioPauseAndResumeKeepsPosition() {
        let id = UUID()
        var state = ReplayableAudioState()

        state.toggle(attachmentID: id, duration: 12)
        state.tick(3)
        state.toggle(attachmentID: id, duration: 12)
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.position, 3, accuracy: 0.01)

        state.toggle(attachmentID: id, duration: 12)
        XCTAssertTrue(state.isPlaying)
        XCTAssertEqual(state.position, 3, accuracy: 0.01)
    }

    func testCreativeEntriesArePartOfVisibleRecordActions() {
        let visible = Set(RecordStudioActionCatalog.all.map(\.id))

        XCTAssertTrue(visible.contains(.drawing))
        XCTAssertTrue(visible.contains(.pixelArt))
        XCTAssertTrue(visible.contains(.stickers))
        XCTAssertTrue(visible.contains(.englishReading))
    }

    func testPixelEraserAndUndoRestorePreviousColor() {
        var state = PixelCanvasState()
        state.selectColor(2)
        state.paint(column: 3, row: 4)

        state.selectEraser()
        state.paint(column: 3, row: 4)
        XCTAssertEqual(state.colorIndex(column: 3, row: 4), -1)

        state.undo()
        XCTAssertEqual(state.colorIndex(column: 3, row: 4), 2)
    }

    func testStickerCatalogCoversRequiredCategories() {
        XCTAssertEqual(
            Set(StickerCatalog.stickers.map(\.category)),
            Set(StickerCategory.allCases)
        )
        XCTAssertGreaterThanOrEqual(StickerCatalog.stickers.count, 40)
    }

    func testStickerCanvasSupportsMultipleLayersAndUndo() {
        var state = StickerCanvasState()
        let first = StickerCatalog.stickers[0]
        let second = StickerCatalog.stickers[1]

        state.add(first)
        state.add(second)
        XCTAssertEqual(state.layers.count, 2)
        XCTAssertEqual(state.selectedLayerID, state.layers.last?.id)

        state.deleteSelected()
        XCTAssertEqual(state.layers.count, 1)
        state.undo()
        XCTAssertEqual(state.layers.count, 2)
    }

    func testSpokenAlarmTextIsShortAndIdentifiesTheTask() {
        let text = SpokenAlarmTextBuilder.text(
            for: String(repeating: "下午两点和客户开会并确认下一版方案", count: 4)
        )

        XCTAssertFalse(text.hasPrefix("提醒："))
        XCTAssertFalse(text.contains("提醒我"))
        XCTAssertLessThanOrEqual(text.count, 42)
    }

    func testSpokenAlarmSpeaksTheScheduledTimeWithoutReminderPrefix() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(identifier: "Asia/Shanghai")
        )
        let date = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 11,
                    day: 13,
                    hour: 12,
                    minute: 30
                )
            )
        )

        let text = SpokenAlarmTextBuilder.text(
            for: "提醒我吃饭",
            scheduledAt: date,
            fireDate: date,
            calendar: calendar
        )

        XCTAssertEqual(text, "12点半到了，吃饭囉")
    }

    func testEarlySpokenAlarmIncludesLeadTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(identifier: "Asia/Shanghai")
        )
        let fireDate = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 11,
                    day: 13,
                    hour: 12,
                    minute: 25
                )
            )
        )
        let scheduledAt = try XCTUnwrap(
            calendar.date(byAdding: .minute, value: 5, to: fireDate)
        )

        let text = SpokenAlarmTextBuilder.text(
            for: "记得提醒我吃饭",
            scheduledAt: scheduledAt,
            fireDate: fireDate,
            calendar: calendar
        )

        XCTAssertEqual(text, "还有5分钟到12点半，吃饭囉")
    }

    @MainActor
    func testAlarmVoicePreferencesUseTaiwaneseDefaultAndCanReset() {
        let suiteName = "AlarmVoicePreferencesTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let preferences = AlarmVoicePreferences(defaults: defaults)
        XCTAssertTrue(preferences.isSpokenAlarmEnabled)
        XCTAssertEqual(preferences.profile, .gentleTaiwanese)

        preferences.isSpokenAlarmEnabled = false
        preferences.profile = .clearMandarin
        preferences.resetToDefaults()

        XCTAssertTrue(preferences.isSpokenAlarmEnabled)
        XCTAssertEqual(preferences.profile, .gentleTaiwanese)
    }

    func testRecordStudioUsesRequestedActionOrder() {
        XCTAssertEqual(
            RecordStudioActionCatalog.all.map(\.id),
            [
                .camera,
                .video,
                .library,
                .voice,
                .drawing,
                .englishReading,
                .pixelArt,
                .stickers,
            ]
        )
    }

    func testPixelCanvasResizesWithNearestNeighbor() {
        var state = PixelCanvasState()
        state.selectColor(2)
        state.paint(column: 15, row: 15)

        state.setGridSize(8)

        XCTAssertEqual(state.gridSize, 8)
        XCTAssertEqual(state.colorIndex(column: 7, row: 7), 2)
    }

    func testPixelBrushCanPaintLargerBlocks() {
        var state = PixelCanvasState()
        state.selectColor(3)
        state.setBrushSize(3)
        state.paint(column: 2, row: 2)

        XCTAssertEqual(state.colorIndex(column: 2, row: 2), 3)
        XCTAssertEqual(state.colorIndex(column: 4, row: 4), 3)
        XCTAssertEqual(state.colorIndex(column: 5, row: 5), -1)
    }

    func testPencilPresetsIncludeChalkAndCalligraphy() {
        XCTAssertEqual(
            PencilBrushPreset.allCases.map(\.title),
            ["粉笔", "书法"]
        )
    }

    func testPhotoFilterCatalogContainsRequestedEightLooks() {
        XCTAssertEqual(
            PhotoFilterPreset.allCases.map(\.title),
            [
                "暖阳生活",
                "清透日常",
                "柔光胶片",
                "银盐黑白",
                "旧时记忆",
                "电影青橙",
                "金色暮光",
                "清冷蓝调",
            ]
        )
    }
}
