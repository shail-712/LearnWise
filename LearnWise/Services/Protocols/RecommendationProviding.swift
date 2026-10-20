import Foundation

/// Anything that can turn a learning request into recommendations:
/// Gemini, the offline catalog, the engine that combines them, or a test mock.
protocol RecommendationProviding: Sendable {
    func recommend(for request: LearningRequest) async throws -> RecommendationResponse
}
