import Foundation

/// One recommended learning resource.
struct Resource: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    let title: String
    let type: ResourceType
    let description: String
    let source: String              // "YouTube", "LeetCode", "MIT OCW"…
    let difficulty: SkillLevel
    let estimatedMinutes: Int?
    let url: String?                // Suggested by the model. Untrusted, see LinkResolver.
    let searchQuery: String?        // Used to build a safe search link
    let leetcodeSlug: String?       // e.g. "climbing-stairs"
    var resolvedURL: URL?           // Set by LinkResolver; this is what the UI opens

    init(
        id: UUID = UUID(),
        title: String,
        type: ResourceType,
        description: String,
        source: String,
        difficulty: SkillLevel,
        estimatedMinutes: Int? = nil,
        url: String? = nil,
        searchQuery: String? = nil,
        leetcodeSlug: String? = nil,
        resolvedURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.description = description
        self.source = source
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.url = url
        self.searchQuery = searchQuery
        self.leetcodeSlug = leetcodeSlug
        self.resolvedURL = resolvedURL
    }

    /// Text for a search link when there's no trusted URL.
    var effectiveSearchQuery: String {
        searchQuery?.nilIfBlank ?? title
    }

    /// "45 min", "1h 30m", or nil.
    var durationText: String? {
        guard let minutes = estimatedMinutes, minutes > 0 else { return nil }
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
    }
}

extension Resource {
    enum CodingKeys: String, CodingKey {
        case id, title, type, description, source, difficulty
        case estimatedMinutes, url, searchQuery, leetcodeSlug, resolvedURL
    }

    // Gemini doesn't send `id` or `resolvedURL`; cached responses do.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        type = try container.decode(ResourceType.self, forKey: .type)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
        difficulty = try container.decodeIfPresent(SkillLevel.self, forKey: .difficulty) ?? .beginner
        estimatedMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        searchQuery = try container.decodeIfPresent(String.self, forKey: .searchQuery)
        leetcodeSlug = try container.decodeIfPresent(String.self, forKey: .leetcodeSlug)
        resolvedURL = try container.decodeIfPresent(URL.self, forKey: .resolvedURL)
    }
}
