import XCTest

/// Runs the app with `-UITestMockAI`: sample data instead of Gemini, and an in-memory store.
final class RecommendationFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestMockAI"]
        app.launch()
    }

    func testSearchShowsResults() {
        let topicField = app.textFields["topicField"]
        XCTAssertTrue(topicField.waitForExistence(timeout: 5))
        topicField.tap()
        topicField.typeText("Dynamic Programming")

        app.buttons["searchButton"].tap()

        XCTAssertTrue(app.navigationBars["Dynamic Programming"].waitForExistence(timeout: 10))
        // Each card is one button, so its texts merge into the button's label.
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Climbing Stairs'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
    }

    func testSuggestionChipFillsTopic() {
        app.buttons["SwiftUI"].tap()

        XCTAssertEqual(app.textFields["topicField"].value as? String, "SwiftUI")
        XCTAssertTrue(app.buttons["searchButton"].isEnabled)
    }

    func testSearchButtonDisabledWithoutTopic() {
        XCTAssertFalse(app.buttons["searchButton"].isEnabled)
    }
}
