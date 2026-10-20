import Foundation
import SwiftData

@Model
final class SearchHistoryItem {
    var topic: String
    var levelRaw: String
    var goal: String?
    var searchedAt: Date
    /// The JSON-encoded `RecommendationResponse`, so old results open without a network call.
    @Attribute(.externalStorage) var cachedResponse: Data?

    init(request: LearningRequest, response: RecommendationResponse?, searchedAt: Date = .now) {
        topic = request.topic
        levelRaw = request.level.rawValue
        goal = request.goal
        self.searchedAt = searchedAt
        cachedResponse = response.flatMap { try? JSONEncoder().encode($0) }
    }

    var level: SkillLevel { SkillLevel(rawValue: levelRaw) ?? .beginner }

    var request: LearningRequest {
        LearningRequest(topic: topic, level: level, goal: goal)
    }

    var cached: RecommendationResponse? {
        guard let cachedResponse else { return nil }
        return try? JSONDecoder().decode(RecommendationResponse.self, from: cachedResponse)
    }
}
