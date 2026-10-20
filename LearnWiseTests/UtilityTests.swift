import XCTest
@testable import LearnWise

final class UtilityTests: XCTestCase {

    func testGroupedKeepsFirstAppearanceOrder() {
        let words = ["apple", "banana", "avocado", "cherry", "blueberry"]

        let groups = words.grouped { $0.first! }

        XCTAssertEqual(groups.map(\.key), ["a", "b", "c"])
        XCTAssertEqual(groups[0].items, ["apple", "avocado"])
        XCTAssertEqual(groups[1].items, ["banana", "blueberry"])
    }

    func testGroupedEmpty() {
        XCTAssertTrue([String]().grouped { $0 }.isEmpty)
    }

    func testHoursText() {
        XCTAssertEqual(RoadmapStep.hoursText(0.5), "30 min")
        XCTAssertEqual(RoadmapStep.hoursText(3), "3 h")
        XCTAssertEqual(RoadmapStep.hoursText(2.5), "2.5 h")
        XCTAssertEqual(RoadmapStep.hoursText(0), "—")
    }

    func testResourceDurationText() {
        func duration(_ minutes: Int?) -> String? {
            Resource(title: "", type: .notes, description: "", source: "", difficulty: .beginner, estimatedMinutes: minutes).durationText
        }
        XCTAssertEqual(duration(45), "45 min")
        XCTAssertEqual(duration(120), "2h")
        XCTAssertEqual(duration(90), "1h 30m")
        XCTAssertNil(duration(nil))
        XCTAssertNil(duration(0))
    }

    @MainActor
    func testRouterSearchAgainSwitchesToDiscover() {
        let router = AppRouter()
        router.selectedTab = .history

        router.searchAgain(SampleData.request)

        XCTAssertEqual(router.selectedTab, .discover)
        XCTAssertEqual(router.pendingSearch, SampleData.request)
    }
}
