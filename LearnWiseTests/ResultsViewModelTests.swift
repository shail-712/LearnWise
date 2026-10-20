import XCTest
@testable import LearnWise

@MainActor
final class ResultsViewModelTests: XCTestCase {
    private func makeViewModel() -> ResultsViewModel {
        ResultsViewModel(request: SampleData.request, response: SampleData.response)
    }

    func testShowsAllTypesByDefault() {
        let viewModel = makeViewModel()

        XCTAssertNil(viewModel.selectedType)
        XCTAssertEqual(viewModel.visibleTypes, SampleData.response.availableTypes)
    }

    func testFilterShowsOneType() {
        let viewModel = makeViewModel()

        viewModel.toggleFilter(.leetcode)

        XCTAssertEqual(viewModel.visibleTypes, [.leetcode])
        XCTAssertEqual(viewModel.count(of: .leetcode), 2)
    }

    func testTappingSelectedFilterAgainShowsAll() {
        let viewModel = makeViewModel()

        viewModel.toggleFilter(.video)
        viewModel.toggleFilter(.video)

        XCTAssertNil(viewModel.selectedType)
        XCTAssertEqual(viewModel.visibleTypes.count, SampleData.response.availableTypes.count)
    }

    func testAllChipClearsFilter() {
        let viewModel = makeViewModel()

        viewModel.toggleFilter(.pdf)
        viewModel.toggleFilter(nil)

        XCTAssertNil(viewModel.selectedType)
    }

    func testOnlyTypesWithResultsAreFilters() {
        let response = RecommendationResponse(
            topic: "X",
            category: "General",
            resources: [Resource(title: "A", type: .notes, description: "", source: "", difficulty: .beginner)],
            roadmap: []
        )
        let viewModel = ResultsViewModel(request: SampleData.request, response: response)

        XCTAssertEqual(viewModel.filterTypes, [.notes])
    }
}
