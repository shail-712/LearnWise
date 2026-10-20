import Foundation
@testable import LearnWise

/// Stands in for Gemini (or any provider) and returns a fixed result.
struct MockGeminiService: RecommendationProviding {
    var result: Result<RecommendationResponse, AppError>

    static let success = MockGeminiService(result: .success(SampleData.response))

    static func failing(_ error: AppError) -> MockGeminiService {
        MockGeminiService(result: .failure(error))
    }

    func recommend(for request: LearningRequest) async throws -> RecommendationResponse {
        try result.get()
    }
}

/// Pretends to be the YouTube Data API.
struct MockYouTubeService: YouTubeSearching {
    var videoURL = URL(string: "https://www.youtube.com/watch?v=mock123")!

    func firstVideoURL(for query: String) async throws -> URL {
        videoURL
    }
}
