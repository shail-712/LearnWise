import Foundation
import SwiftData

@Model
final class BookmarkedResource {
    /// "\(type)-\(title)", which stops the same resource being saved twice.
    @Attribute(.unique) var key: String
    var title: String
    var typeRaw: String
    var summary: String
    var source: String
    var difficultyRaw: String
    var urlString: String
    var topic: String
    var createdAt: Date

    init(resource: Resource, topic: String, createdAt: Date = .now) {
        key = Self.key(for: resource)
        title = resource.title
        typeRaw = resource.type.rawValue
        summary = resource.description
        source = resource.source
        difficultyRaw = resource.difficulty.rawValue
        urlString = (resource.resolvedURL ?? .googleSearch(resource.effectiveSearchQuery)).absoluteString
        self.topic = topic
        self.createdAt = createdAt
    }

    static func key(for resource: Resource) -> String {
        "\(resource.type.rawValue)-\(resource.title.lowercased())"
    }

    var type: ResourceType { ResourceType(rawValue: typeRaw) ?? .notes }
    var difficulty: SkillLevel { SkillLevel(rawValue: difficultyRaw) ?? .beginner }
    var url: URL? { URL(string: urlString) }

    /// Rebuilds a `Resource` so bookmarks can reuse the same cards and detail screen.
    func toResource() -> Resource {
        Resource(
            title: title,
            type: type,
            description: summary,
            source: source,
            difficulty: difficulty,
            resolvedURL: url
        )
    }
}
