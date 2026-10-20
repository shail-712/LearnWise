import Foundation

/// Everything shown for one search: resources, roadmap, and tips.
struct RecommendationResponse: Codable, Hashable, Sendable {
    let topic: String
    let category: String            // "DSA", "Web", "ML", "Math"…
    var resources: [Resource]
    let roadmap: [RoadmapStep]
    let tips: [String]
    /// True when the offline catalog answered instead of Gemini.
    var isOffline: Bool

    init(
        topic: String,
        category: String,
        resources: [Resource],
        roadmap: [RoadmapStep],
        tips: [String] = [],
        isOffline: Bool = false
    ) {
        self.topic = topic
        self.category = category
        self.resources = resources
        self.roadmap = roadmap.sorted { $0.order < $1.order }
        self.tips = tips
        self.isOffline = isOffline
    }

    func resources(of type: ResourceType) -> [Resource] {
        resources.filter { $0.type == type }
    }

    /// Resource types that have at least one result, in display order.
    var availableTypes: [ResourceType] {
        ResourceType.allCases.filter { type in resources.contains { $0.type == type } }
    }

    /// The resources a roadmap step refers to (matched by title, ignoring case).
    func resources(for step: RoadmapStep) -> [Resource] {
        let titles = Set(step.resourceTitles.map { $0.lowercased() })
        return resources.filter { titles.contains($0.title.lowercased()) }
    }

    var totalRoadmapHours: Double {
        roadmap.reduce(0) { $0 + $1.estimatedHours }
    }
}

extension RecommendationResponse {
    enum CodingKeys: String, CodingKey {
        case topic, category, resources, roadmap, tips, isOffline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            topic: try container.decode(String.self, forKey: .topic),
            category: try container.decodeIfPresent(String.self, forKey: .category) ?? "General",
            resources: try container.decodeIfPresent([Resource].self, forKey: .resources) ?? [],
            roadmap: try container.decodeIfPresent([RoadmapStep].self, forKey: .roadmap) ?? [],
            tips: try container.decodeIfPresent([String].self, forKey: .tips) ?? [],
            isOffline: try container.decodeIfPresent(Bool.self, forKey: .isOffline) ?? false
        )
    }
}
