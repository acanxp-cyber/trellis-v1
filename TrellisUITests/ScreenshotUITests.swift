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

        app.tabBars.buttons["记录"].tap()
        capture("02-records")

        app.tabBars.buttons["回顾"].tap()
        capture("03-review")

        app.tabBars.buttons["年轮"].tap()
        capture("04-year")

        app.tabBars.buttons["更多"].tap()
        capture("05-more")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

