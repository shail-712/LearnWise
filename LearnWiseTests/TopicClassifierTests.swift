import XCTest
@testable import LearnWise

final class TopicClassifierTests: XCTestCase {

    func testTokensNormaliseText() {
        XCTAssertEqual(TopicText.tokens("Graphs & BFS in C++!"), ["graph", "bfs", "c++"])
        XCTAssertEqual(TopicText.tokens("Intro to the OS"), ["os"])
        XCTAssertEqual(TopicText.tokens("Machine Learning"), ["machine", "learning"])
    }

    func testKeywordFallbackCategories() {
        let expectations: [String: String] = [
            "binary search on arrays": "DSA",
            "react server components": "Web",
            "swiftui animations": "iOS",
            "transformer models": "ML",
            "linear algebra for ML": "Math",
            "tcp congestion control": "Systems",
            "postgres indexes": "Databases",
        ]
        for (topic, category) in expectations {
            XCTAssertEqual(TopicClassifier.keywordCategory(for: topic), category, "topic: \(topic)")
        }
    }

    func testUnknownTopicIsGeneral() {
        let classifier = TopicClassifier(model: nil)
        XCTAssertNil(TopicClassifier.keywordCategory(for: "underwater basket weaving"))
        XCTAssertEqual(classifier.category(for: "underwater basket weaving"), "General")
    }

    func testBundledModelPredictsAKnownLabel() throws {
        let classifier = TopicClassifier()
        try XCTSkipUnless(classifier.usesMLModel, "LearnWiseTopicClassifier.mlmodel isn't in the app yet")

        XCTAssertTrue(TopicClassifier.labels.contains(classifier.category(for: "dijkstra shortest path")))
    }
}
