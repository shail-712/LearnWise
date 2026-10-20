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

    // MARK: Helpers

    private func searchSample() {
        app.buttons["Dynamic Programming"].tap()       // suggestion chip
        app.buttons["searchButton"].tap()
        XCTAssertTrue(app.navigationBars["Dynamic Programming"].waitForExistence(timeout: 10))
    }

    private func button(containing text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    // MARK: Discover

    func testSearchButtonDisabledWithoutTopic() {
        XCTAssertFalse(app.buttons["searchButton"].isEnabled)
    }

    func testSuggestionChipFillsTopic() {
        app.buttons["SwiftUI"].tap()

        XCTAssertEqual(app.textFields["topicField"].value as? String, "SwiftUI")
        XCTAssertTrue(app.buttons["searchButton"].isEnabled)
    }

    func testSearchShowsResults() {
        let topicField = app.textFields["topicField"]
        XCTAssertTrue(topicField.waitForExistence(timeout: 5))
        topicField.tap()
        topicField.typeText("Dynamic Programming")

        app.buttons["searchButton"].tap()

        XCTAssertTrue(app.navigationBars["Dynamic Programming"].waitForExistence(timeout: 10))
        // Each card is one link, so its texts merge into the link's label.
        XCTAssertTrue(button(containing: "Climbing Stairs").waitForExistence(timeout: 5))
    }

    // MARK: Detail and bookmarks

    func testBookmarkAppearsInSavedTab() {
        searchSample()
        let card = button(containing: "Climbing Stairs")
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()

        XCTAssertTrue(app.buttons["openResourceButton"].waitForExistence(timeout: 5))
        app.buttons["detailBookmarkButton"].tap()
        XCTAssertEqual(app.buttons["detailBookmarkButton"].label, "Remove bookmark")

        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(button(containing: "Climbing Stairs").waitForExistence(timeout: 5))
    }

    // MARK: Roadmap

    func testSaveRoadmapAndTickStep() {
        searchSample()
        app.buttons["roadmapLink"].tap()

        let save = app.buttons["saveRoadmapButton"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertTrue(app.descendants(matching: .any)["roadmapProgress"].waitForExistence(timeout: 5))

        app.buttons["stepToggle1"].firstMatch.tap()

        app.tabBars.buttons["Saved"].tap()
        app.buttons["Roadmaps"].tap()
        XCTAssertTrue(button(containing: "Dynamic Programming").waitForExistence(timeout: 5))
    }

    // MARK: History

    func testHistoryReopensCachedResults() {
        searchSample()

        app.tabBars.buttons["History"].tap()
        let entry = button(containing: "Dynamic Programming")
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        entry.tap()

        // Opens straight away from the cache, with no loading overlay.
        XCTAssertTrue(app.navigationBars["Dynamic Programming"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["cancelSearchButton"].exists)
    }
}
