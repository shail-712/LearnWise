import XCTest
@testable import LearnWise

final class RecommendationEngineTests: XCTestCase {
    private let request = LearningRequest(topic: "Dynamic Programming", level: .beginner)

    private let offlineResponse = RecommendationResponse(
        topic: "Dynamic Programming",
        category: "DSA",
        resources: [Resource(title: "Offline DP Notes", type: .notes, description: "", source: "Catalog", difficulty: .beginner)],
        roadmap: []
    )

    func testUsesPrimaryWhenItSucceeds() async throws {
        let engine = RecommendationEngine(
            primary: MockGeminiService.success,
            fallback: MockGeminiService(result: .success(offlineResponse))
        )

        let response = try await engine.recommend(for: request)

        XCTAssertFalse(response.isOffline)
        XCTAssertEqual(response.resources.count, SampleData.resources.count)
    }

    func testFallsBackWhenRateLimited() async throws {
        let engine = RecommendationEngine(
            primary: MockGeminiService.failing(.rateLimited(retryAfter: nil)),
            fallback: MockGeminiService(result: .success(offlineResponse))
        )

        let response = try await engine.recommend(for: request)

        XCTAssertTrue(response.isOffline)
        XCTAssertEqual(response.resources.first?.title, "Offline DP Notes")
    }

    func testFallsBackWhenAPIKeyIsMissing() async throws {
        let engine = RecommendationEngine(
            primary: GeminiService(apiKey: nil, model: Constants.defaultGeminiModel),
            fallback: MockGeminiService(result: .success(offlineResponse))
        )

        let response = try await engine.recommend(for: request)

        XCTAssertTrue(response.isOffline)
    }

    func testDoesNotFallBackWhenBlockedBySafety() async {
        let engine = RecommendationEngine(
            primary: MockGeminiService.failing(.blockedBySafety),
            fallback: MockGeminiService(result: .success(offlineResponse))
        )

        await assertThrows(.blockedBySafety) { try await engine.recommend(for: self.request) }
    }

    func testRethrowsWhenThereIsNoFallback() async {
        let engine = RecommendationEngine(primary: MockGeminiService.failing(.emptyResponse))

        await assertThrows(.emptyResponse) { try await engine.recommend(for: self.request) }
    }

    func testRejectsBlankTopic() async {
        let engine = RecommendationEngine(primary: MockGeminiService.success)
        let blank = LearningRequest(topic: "   ", level: .beginner)

        do {
            _ = try await engine.recommend(for: blank)
            XCTFail("Expected invalidInput")
        } catch {
            guard case .invalidInput = error as? AppError else {
                return XCTFail("Expected AppError.invalidInput, got \(error)")
            }
        }
    }

    func testEveryResourceGetsAResolvedURL() async throws {
        let unresolved = SampleData.resources.map { resource in
            var copy = resource
            copy.resolvedURL = nil
            return copy
        }
        let primary = MockGeminiService(result: .success(RecommendationResponse(
            topic: "Dynamic Programming",
            category: "DSA",
            resources: unresolved,
            roadmap: []
        )))
        let engine = RecommendationEngine(primary: primary)

        let response = try await engine.recommend(for: request)

        XCTAssertTrue(response.resources.allSatisfy { $0.resolvedURL != nil })
    }

    private func assertThrows(
        _ expected: AppError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> RecommendationResponse
    ) async {
        do {
            _ = try await body()
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AppError, expected, file: file, line: line)
        }
    }
}
