import Foundation

/// What the student typed on the Discover screen.
struct LearningRequest: Codable, Hashable, Sendable {
    let topic: String
    let level: SkillLevel
    let goal: String?

    init(topic: String, level: SkillLevel, goal: String? = nil) {
        self.topic = topic.collapsingWhitespace
        self.level = level
        self.goal = goal?.collapsingWhitespace.nilIfBlank
    }

    func validate() throws {
        if topic.isEmpty {
            throw AppError.invalidInput("Please enter a topic you want to learn.")
        }
        if topic.count > Constants.maxTopicLength {
            throw AppError.invalidInput("Topic must be \(Constants.maxTopicLength) characters or fewer.")
        }
        if let goal, goal.count > Constants.maxGoalLength {
            throw AppError.invalidInput("Goal must be \(Constants.maxGoalLength) characters or fewer.")
        }
    }
}
