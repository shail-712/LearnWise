import SwiftData
import XCTest
@testable import LearnWise

/// Tests the ModelContext helpers against a fresh in-memory store.
@MainActor
final class PersistenceTests: XCTestCase {
    // XCTest makes a new instance per test, so each test gets an empty store.
    // The container is kept as a property because a context doesn't keep it alive.
    private let container = PersistenceController.makeContainer(inMemory: true)
    private var context: ModelContext { container.mainContext }

    private func count<T: PersistentModel>(_ type: T.Type) -> Int {
        (try? context.fetchCount(FetchDescriptor<T>())) ?? -1
    }

    // MARK: Bookmarks

    func testToggleBookmarkAddsThenRemoves() {
        let resource = SampleData.resources[0]

        XCTAssertTrue(context.toggleBookmark(resource, topic: "DP"))
        XCTAssertTrue(context.isBookmarked(resource))
        XCTAssertEqual(count(BookmarkedResource.self), 1)

        XCTAssertFalse(context.toggleBookmark(resource, topic: "DP"))
        XCTAssertFalse(context.isBookmarked(resource))
        XCTAssertEqual(count(BookmarkedResource.self), 0)
    }

    func testSameResourceFromAnotherSearchCountsAsBookmarked() {
        // A new search gives the same resource a new UUID; bookmarks match on type and title.
        var sameResource = SampleData.resources[0]
        sameResource.id = UUID()

        context.toggleBookmark(SampleData.resources[0], topic: "DP")

        XCTAssertTrue(context.isBookmarked(sameResource))
    }

    func testBookmarkRoundTripsToResource() {
        let original = SampleData.resources[3]
        let bookmark = BookmarkedResource(resource: original, topic: "DP")

        let rebuilt = bookmark.toResource()

        XCTAssertEqual(rebuilt.title, original.title)
        XCTAssertEqual(rebuilt.type, original.type)
        XCTAssertEqual(rebuilt.difficulty, original.difficulty)
        XCTAssertEqual(rebuilt.resolvedURL, original.resolvedURL)
    }

    // MARK: History

    func testRecordSearchReplacesIdenticalSearch() {
        context.recordSearch(SampleData.request, response: SampleData.response)
        context.recordSearch(SampleData.request, response: SampleData.response)

        XCTAssertEqual(count(SearchHistoryItem.self), 1)
    }

    func testDifferentGoalIsASeparateSearch() {
        context.recordSearch(SampleData.request, response: SampleData.response)
        let otherGoal = LearningRequest(topic: SampleData.request.topic, level: SampleData.request.level, goal: "Exams")
        context.recordSearch(otherGoal, response: SampleData.response)

        XCTAssertEqual(count(SearchHistoryItem.self), 2)
    }

    func testHistoryIsTrimmedToLimit() throws {
        for index in 0..<(Constants.maxHistoryItems + 5) {
            context.recordSearch(LearningRequest(topic: "Topic \(index)", level: .beginner), response: SampleData.response)
        }
        try context.save()

        XCTAssertEqual(count(SearchHistoryItem.self), Constants.maxHistoryItems)
    }

    func testCachedResponseDecodes() throws {
        context.recordSearch(SampleData.request, response: SampleData.response)
        let item = try XCTUnwrap(context.fetch(FetchDescriptor<SearchHistoryItem>()).first)

        XCTAssertEqual(item.cached, SampleData.response)
        XCTAssertEqual(item.request, SampleData.request)
    }

    // MARK: Roadmaps

    func testSaveRoadmapTwiceKeepsOneCopy() {
        let first = context.saveRoadmap(SampleData.response, level: .beginner)
        let second = context.saveRoadmap(SampleData.response, level: .beginner)

        XCTAssertTrue(first === second)
        XCTAssertEqual(count(SavedRoadmap.self), 1)
        XCTAssertNotNil(context.savedRoadmap(topic: SampleData.response.topic, level: .beginner))
        XCTAssertNil(context.savedRoadmap(topic: SampleData.response.topic, level: .advanced))
    }

    func testSavedRoadmapKeepsResourceLinks() throws {
        let roadmap = context.saveRoadmap(SampleData.response, level: .beginner)
        let response = try XCTUnwrap(roadmap.response)
        let step = try XCTUnwrap(response.roadmap.first)

        XCTAssertFalse(response.resources(for: step).isEmpty)
    }

    func testClearingData() throws {
        context.toggleBookmark(SampleData.resources[0], topic: "DP")
        context.recordSearch(SampleData.request, response: SampleData.response)
        context.saveRoadmap(SampleData.response, level: .beginner)
        try context.save()

        context.clearBookmarks()
        context.clearHistory()
        context.clearSavedRoadmaps()

        XCTAssertEqual(count(BookmarkedResource.self), 0)
        XCTAssertEqual(count(SearchHistoryItem.self), 0)
        XCTAssertEqual(count(SavedRoadmap.self), 0)
    }

    func testSavedRoadmapTracksProgress() throws {
        let roadmap = SavedRoadmap(response: SampleData.response, level: .beginner)
        context.insert(roadmap)
        let firstStep = try XCTUnwrap(roadmap.steps.first)

        XCTAssertEqual(roadmap.progress, 0)
        roadmap.toggleCompletion(of: firstStep)
        XCTAssertTrue(roadmap.isCompleted(firstStep))
        XCTAssertEqual(roadmap.progress, 1.0 / Double(roadmap.steps.count), accuracy: 0.001)
        roadmap.toggleCompletion(of: firstStep)
        XCTAssertFalse(roadmap.isCompleted(firstStep))
    }
}
