import Foundation

/// Returns `SampleData.response` after a short pause. Used by SwiftUI previews and by
/// UI tests (launch argument `-UITestMockAI`), so neither needs a network or an API key.
struct SampleRecommendationProvider: RecommendationProviding {
    var delay: Duration = .milliseconds(800)

    func recommend(for request: LearningRequest) async throws -> RecommendationResponse {
        try request.validate()
        try await Task.sleep(for: delay)
        return SampleData.response
    }
}
