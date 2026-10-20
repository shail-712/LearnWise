import XCTest
@testable import LearnWise

final class OfflineCatalogServiceTests: XCTestCase {

    /// Always answers the same category, so tests don't depend on the Core ML model.
    private struct FixedClassifier: TopicClassifying {
        let label: String
        func category(for topic: String) -> String { label }
    }

    private func makeService(classifier: String = "General") -> OfflineCatalogService {
        OfflineCatalogService(entries: OfflineCatalogService.loadEntries(from: .main), classifier: FixedClassifier(label: classifier))
    }

    // MARK: Bundled catalog

    func testBundledCatalogLoads() {
        let entries = OfflineCatalogService.loadEntries(from: .main)
        XCTAssertEqual(entries.count, 20, "Is resources_catalog.json in the LearnWise target?")
        XCTAssertTrue(entries.allSatisfy { !$0.resources.isEmpty })
        XCTAssertTrue(entries.allSatisfy { TopicClassifier.labels.contains($0.category) })
    }

    // MARK: Matching

    func testMatchesTopicsAndKeywords() {
        let service = makeService()
        let expectations: [String: String] = [
            "Dynamic Programming": "Dynamic Programming",
            "dp": "Dynamic Programming",
            "DP for interviews": "Dynamic Programming",
            "trees": "Trees",
            "Binary Search Trees": "Trees",
            "graph theory": "Graph Algorithms",
            "networks": "Computer Networks",
            "algorithms": "Data Structures",
            "data structures in python": "Data Structures",
            "Swift": "Swift Programming",
            "iOS development": "SwiftUI",
            "react hooks": "React",
            "OS": "Operating Systems",
            "DBMS normalization": "SQL and Databases",
            "probability & statistics": "Probability and Statistics",
            "Machine Learning": "Machine Learning",
        ]
        for (query, topic) in expectations {
            XCTAssertEqual(service.bestMatch(for: query)?.topic, topic, "query: \(query)")
        }
    }

    func testSingleSharedWordIsNotAMatch() {
        // "programming" alone shouldn't pull in Python or Swift.
        XCTAssertNil(makeService().bestMatch(for: "Java programming"))
    }

    func testUnknownTopicUsesClassifierCategory() async throws {
        let service = makeService(classifier: "Math")

        let response = try await service.recommend(for: LearningRequest(topic: "Fourier transforms", level: .beginner))

        XCTAssertEqual(response.topic, "Fourier transforms")
        XCTAssertEqual(response.category, "Math")
        XCTAssertFalse(response.resources.isEmpty)
        XCTAssertTrue(response.isOffline)
    }

    func testUnknownCategoryThrowsEmptyResponse() async {
        let service = makeService(classifier: "Underwater Basket Weaving")

        do {
            _ = try await service.recommend(for: LearningRequest(topic: "zzz", level: .beginner))
            XCTFail("Expected emptyResponse")
        } catch {
            XCTAssertEqual(error as? AppError, .emptyResponse)
        }
    }

    // MARK: Picking

    func testPickMixesTypesAndRespectsLimit() async throws {
        let response = try await makeService().recommend(for: LearningRequest(topic: "Dynamic Programming", level: .beginner))

        XCTAssertLessThanOrEqual(response.resources.count, 10)
        XCTAssertGreaterThanOrEqual(Set(response.resources.map(\.type)).count, 4)
        XCTAssertEqual(Set(response.resources.map(\.title)).count, response.resources.count, "no duplicates")
    }

    func testBeginnerGetsBeginnerResourcesFirstWithinEachType() {
        let resources = [
            Resource(title: "Hard", type: .leetcode, description: "", source: "", difficulty: .advanced),
            Resource(title: "Easy", type: .leetcode, description: "", source: "", difficulty: .beginner),
            Resource(title: "Medium", type: .leetcode, description: "", source: "", difficulty: .intermediate),
        ]

        let picked = OfflineCatalogService.pick(resources, for: .beginner, limit: 2)

        XCTAssertEqual(picked.map(\.title), ["Easy", "Medium"])
    }

    func testAdvancedPrefersHarderResources() {
        let resources = [
            Resource(title: "Easy", type: .notes, description: "", source: "", difficulty: .beginner),
            Resource(title: "Hard", type: .notes, description: "", source: "", difficulty: .advanced),
        ]

        let picked = OfflineCatalogService.pick(resources, for: .advanced, limit: 1)

        XCTAssertEqual(picked.map(\.title), ["Hard"])
    }

    // MARK: Roadmap

    func testRoadmapStagesReferenceRealResources() async throws {
        let response = try await makeService().recommend(for: LearningRequest(topic: "Trees", level: .intermediate))

        XCTAssertFalse(response.roadmap.isEmpty)
        XCTAssertEqual(response.roadmap.map(\.order), Array(1...response.roadmap.count))
        for step in response.roadmap {
            XCTAssertEqual(response.resources(for: step).count, step.resourceTitles.count, step.title)
            XCTAssertGreaterThan(step.estimatedHours, 0)
        }
    }

    func testRoadmapSkipsEmptyStages() {
        let onlyNotes = [Resource(title: "Notes", type: .notes, description: "", source: "", difficulty: .beginner)]

        let roadmap = OfflineCatalogService.makeRoadmap(for: onlyNotes)

        XCTAssertEqual(roadmap.count, 1)
        XCTAssertEqual(roadmap.first?.estimatedHours, 0.5)   // 30-minute default
    }
}
