import Foundation

/// One step in the learning roadmap.
struct RoadmapStep: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    let order: Int
    let title: String
    let summary: String
    let resourceTitles: [String]    // Matches `Resource.title`
    let estimatedHours: Double

    init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        summary: String,
        resourceTitles: [String] = [],
        estimatedHours: Double
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.summary = summary
        self.resourceTitles = resourceTitles
        self.estimatedHours = estimatedHours
    }
}

extension RoadmapStep {
    enum CodingKeys: String, CodingKey {
        case id, order, title, summary, resourceTitles, estimatedHours
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        order = try container.decode(Int.self, forKey: .order)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        resourceTitles = try container.decodeIfPresent([String].self, forKey: .resourceTitles) ?? []
        estimatedHours = try container.decodeIfPresent(Double.self, forKey: .estimatedHours) ?? 0
    }
}
