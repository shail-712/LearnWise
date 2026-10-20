import XCTest
@testable import LearnWise

@MainActor
final class HomeViewModelTests: XCTestCase {

    func testBlankTopicShowsValidationMessageAndDoesNotSearch() {
        let viewModel = HomeViewModel(provider: MockGeminiService.success)
        viewModel.topic = "   "

        let task = viewModel.search { _, _ in XCTFail("Should not search") }

        XCTAssertNil(task)
        XCTAssertNotNil(viewModel.validationMessage)
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testSuccessfulSearchLoadsAndCallsBack() async {
        let viewModel = HomeViewModel(provider: MockGeminiService.success)
        viewModel.topic = "  Dynamic   Programming "
        viewModel.level = .intermediate
        viewModel.goal = "Interviews"
        var received: LearningRequest?

        await viewModel.search { request, _ in received = request }?.value

        XCTAssertEqual(viewModel.state, .loaded(SampleData.response))
        XCTAssertEqual(received, LearningRequest(topic: "Dynamic Programming", level: .intermediate, goal: "Interviews"))
        XCTAssertNil(viewModel.searchStartedAt)
    }

    func testFailureIsShown() async {
        let viewModel = HomeViewModel(provider: MockGeminiService.failing(.blockedBySafety))
        viewModel.topic = "Something"

        await viewModel.search { _, _ in XCTFail("Should not succeed") }?.value

        XCTAssertEqual(viewModel.state, .failed(.blockedBySafety))
    }

    func testEmptyResultsShowEmptyState() async {
        let empty = RecommendationResponse(topic: "X", category: "General", resources: [], roadmap: [])
        let viewModel = HomeViewModel(provider: MockGeminiService(result: .success(empty)))
        viewModel.topic = "X"

        await viewModel.search { _, _ in XCTFail("Should not navigate") }?.value

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testCancelReturnsToIdle() async {
        let viewModel = HomeViewModel(provider: SampleRecommendationProvider(delay: .seconds(5)))
        viewModel.topic = "Graphs"

        let task = viewModel.search { _, _ in XCTFail("Cancelled search should not call back") }
        XCTAssertTrue(viewModel.state.isLoading)
        XCTAssertFalse(viewModel.canSubmit)

        viewModel.cancel()
        await task?.value

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.searchStartedAt)
    }

    func testNewSearchAfterCancelIsNotOverwrittenByOldTask() async {
        let viewModel = HomeViewModel(provider: SampleRecommendationProvider(delay: .milliseconds(200)))
        viewModel.topic = "Graphs"

        let first = viewModel.search { _, _ in }
        viewModel.cancel()
        let second = viewModel.search { _, _ in }
        await first?.value

        XCTAssertTrue(viewModel.state.isLoading, "the cancelled task must not reset the new search")
        await second?.value
        XCTAssertEqual(viewModel.state, .loaded(SampleData.response))
    }

    func testPrefillAndSuggestion() {
        let viewModel = HomeViewModel(provider: MockGeminiService.success)

        viewModel.prefill(from: LearningRequest(topic: "SQL", level: .advanced, goal: "Exams"))
        XCTAssertEqual(viewModel.topic, "SQL")
        XCTAssertEqual(viewModel.level, .advanced)
        XCTAssertEqual(viewModel.goal, "Exams")

        viewModel.useSuggestion("SwiftUI")
        XCTAssertEqual(viewModel.topic, "SwiftUI")
    }
}
