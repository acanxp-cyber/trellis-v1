import XCTest

final class ScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launchEnvironment["TRELLIS_UI_TEST"] = "1"
        app.launch()

        XCTAssertTrue(app.staticTexts["今天"].firstMatch.waitForExistence(timeout: 10))
        capture("01-today")

        let voiceEntry = app.buttons["voice-task-capture"]
        XCTAssertTrue(voiceEntry.waitForExistence(timeout: 5))
        voiceEntry.tap()
        XCTAssertTrue(
            app.staticTexts["一次说完，自动排成时间线。"]
                .waitForExistence(timeout: 5)
        )
        capture("02-voice-capture")
        app.buttons["取消"].tap()

        app.buttons["tab-records"].tap()
        capture("03-records")

        app.buttons["tab-fitness"].tap()
        XCTAssertTrue(app.staticTexts["今天练什么？"].waitForExistence(timeout: 5))
        capture("04-fitness")

        app.buttons["tab-more"].tap()
        XCTAssertTrue(app.staticTexts["时间线"].waitForExistence(timeout: 5))
        capture("05-more")

        app.buttons["周回顾"].tap()
        capture("06-review")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["年轮"].tap()
        capture("07-year")
    }

    func testVoiceCaptureTapDoesNotTerminateApp() throws {
        let app = XCUIApplication()
        app.launchEnvironment["TRELLIS_UI_TEST"] = "1"
        app.launch()

        addUIInterruptionMonitor(
            withDescription: "Voice permissions"
        ) { alert in
            for label in ["允许", "Allow", "好", "OK"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }

        let voiceEntry = app.buttons["voice-task-capture"]
        XCTAssertTrue(voiceEntry.waitForExistence(timeout: 10))
        voiceEntry.tap()

        let startButton = app.buttons["开始语音输入"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        app.tap()
        app.tap()

        XCTAssertTrue(
            app.staticTexts["一次说完，自动排成时间线。"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertEqual(app.state, .runningForeground)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

