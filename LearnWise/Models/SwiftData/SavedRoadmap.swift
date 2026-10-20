import Foundation
import SwiftData

@Model
final class SavedRoadmap {
    var topic: String
    var levelRaw: String
    var createdAt: Date
    /// The whole JSON-encoded response, so a saved roadmap can still link to its resources.
    @Attribute(.externalStorage) var responseData: Data
    var completedStepOrders: [Int]

    init(response: RecommendationResponse, level: SkillLevel, createdAt: Date = .now) {
        topic = response.topic
        levelRaw = level.rawValue
        self.createdAt = createdAt
        responseData = (try? JSONEncoder().encode(response)) ?? Data()
        completedStepOrders = []
    }

    var level: SkillLevel { SkillLevel(rawValue: levelRaw) ?? .beginner }

    var response: RecommendationResponse? {
        try? JSONDecoder().decode(RecommendationResponse.self, from: responseData)
    }

    var steps: [RoadmapStep] { response?.roadmap ?? [] }

    /// Share of steps completed, from 0 to 1.
    var progress: Double {
        let total = steps.count
        guard total > 0 else { return 0 }
        return Double(Set(completedStepOrders).count) / Double(total)
    }

    func isCompleted(_ step: RoadmapStep) -> Bool {
        completedStepOrders.contains(step.order)
    }

    func toggleCompletion(of step: RoadmapStep) {
        if let index = completedStepOrders.firstIndex(of: step.order) {
            completedStepOrders.remove(at: index)
        } else {
            completedStepOrders.append(step.order)
        }
    }
}
