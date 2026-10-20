import Foundation

/// How experienced the student already is with the topic.
enum SkillLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    /// Used to sort resources from easiest to hardest.
    var rank: Int {
        switch self {
        case .beginner: 0
        case .intermediate: 1
        case .advanced: 2
        }
    }
}

extension SkillLevel {
    // An unexpected value from the model shouldn't fail the whole response.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SkillLevel(rawValue: raw.lowercased()) ?? .beginner
    }
}
