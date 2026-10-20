import Foundation

/// One topic in resources_catalog.json.
struct CatalogEntry: Decodable, Sendable {
    let topic: String
    let category: String
    let keywords: [String]
    let resources: [Resource]
}

/// Answers from the bundled, hand-picked catalog when Gemini can't (no network, no key,
/// rate limits). Picks the closest catalog topic; if none fits, uses the topic's category.
struct OfflineCatalogService: RecommendationProviding {
    static let catalogFileName = "resources_catalog"

    let entries: [CatalogEntry]
    let classifier: any TopicClassifying
    var maxResources = 10

    init(entries: [CatalogEntry], classifier: any TopicClassifying = TopicClassifier()) {
        self.entries = entries
        self.classifier = classifier
    }

    init(bundle: Bundle = .main, classifier: any TopicClassifying = TopicClassifier()) {
        self.init(entries: Self.loadEntries(from: bundle), classifier: classifier)
    }

    static func loadEntries(from bundle: Bundle) -> [CatalogEntry] {
        guard let url = bundle.url(forResource: catalogFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CatalogEntry].self, from: data) else {
            assertionFailure("\(catalogFileName).json is missing or invalid. Is it in the app target?")
            return []
        }
        return entries
    }

    func recommend(for request: LearningRequest) async throws -> RecommendationResponse {
        try request.validate()

        if let entry = bestMatch(for: request.topic) {
            let resources = Self.pick(entry.resources, for: request.level, limit: maxResources)
            return Self.makeResponse(topic: entry.topic, category: entry.category, resources: resources)
        }

        // Unknown topic: offer the best resources from its category instead.
        let category = classifier.category(for: request.topic)
        let pool = entries.filter { $0.category == category }.flatMap(\.resources)
        guard !pool.isEmpty else { throw AppError.emptyResponse }
        let resources = Self.pick(pool, for: request.level, limit: maxResources)
        return Self.makeResponse(topic: request.topic, category: category, resources: resources)
    }

    // MARK: Matching

    /// The catalog entry that best fits the query, or nil if nothing fits well enough.
    func bestMatch(for query: String) -> CatalogEntry? {
        let scored = entries
            .map { (entry: $0, score: Self.score($0, query: query)) }
            .filter { $0.score >= Self.minimumScore }
        return scored.max { $0.score < $1.score }?.entry
    }

    static let minimumScore = 20

    /// 100 for an exact name, 60+ when a whole keyword appears in the query, 50 when the query
    /// is part of a keyword, and 10 per shared word otherwise. One shared word (e.g. "programming"
    /// for "Java programming") isn't enough on its own.
    static func score(_ entry: CatalogEntry, query: String) -> Int {
        let queryTokens = TopicText.tokens(query)
        guard !queryTokens.isEmpty else { return 0 }
        let queryText = " " + queryTokens.joined(separator: " ") + " "
        let querySet = Set(queryTokens)

        var best = 0
        for name in [entry.topic] + entry.keywords {
            let nameTokens = TopicText.tokens(name)
            guard !nameTokens.isEmpty else { continue }
            let nameText = " " + nameTokens.joined(separator: " ") + " "

            if nameTokens == queryTokens {
                return 100
            } else if queryText.contains(nameText) {
                best = max(best, 60 + 5 * nameTokens.count)
            } else if nameText.contains(queryText) {
                best = max(best, 50)
            } else {
                best = max(best, 10 * querySet.intersection(nameTokens).count)
            }
        }
        return best
    }

    // MARK: Picking and roadmap

    /// Mixes resource types (one video, one note, one problem…) and puts the closest difficulty first.
    static func pick(_ resources: [Resource], for level: SkillLevel, limit: Int) -> [Resource] {
        func distance(_ resource: Resource) -> Int {
            let gap = resource.difficulty.rank - level.rank
            // A slightly harder resource is more useful than a much easier one.
            return gap < 0 ? -gap * 2 : gap
        }

        var queues = ResourceType.allCases.map { type in
            resources.filter { $0.type == type }.sorted { distance($0) < distance($1) }
        }

        var picked: [Resource] = []
        var seenTitles = Set<String>()
        while picked.count < limit, queues.contains(where: { !$0.isEmpty }) {
            for index in queues.indices where !queues[index].isEmpty && picked.count < limit {
                let next = queues[index].removeFirst()
                if seenTitles.insert(next.title.lowercased()).inserted {
                    picked.append(next)
                }
            }
        }
        return picked.sorted { $0.difficulty.rank < $1.difficulty.rank }
    }

    private struct Stage {
        let title: String
        let summary: String
        let types: Set<ResourceType>
    }

    private static let stages = [
        Stage(title: "Build the foundations",
              summary: "Start with the videos and notes to understand the core ideas.",
              types: [.video, .notes]),
        Stage(title: "Go deeper",
              summary: "Follow a structured course or book to fill in the details.",
              types: [.course, .pdf]),
        Stage(title: "Practise",
              summary: "Solve problems to make the ideas stick. Start easy and work up.",
              types: [.leetcode]),
    ]

    /// A simple rule-based roadmap: learn → study → practise, skipping empty stages.
    static func makeRoadmap(for resources: [Resource]) -> [RoadmapStep] {
        var steps: [RoadmapStep] = []
        for stage in stages {
            let included = resources.filter { stage.types.contains($0.type) }
            guard !included.isEmpty else { continue }
            let minutes = included.reduce(0) { $0 + ($1.estimatedMinutes ?? 30) }
            steps.append(RoadmapStep(
                order: steps.count + 1,
                title: stage.title,
                summary: stage.summary,
                resourceTitles: included.map(\.title),
                estimatedHours: (Double(minutes) / 60 * 2).rounded() / 2   // nearest half hour
            ))
        }
        return steps
    }

    private static func makeResponse(topic: String, category: String, resources: [Resource]) -> RecommendationResponse {
        RecommendationResponse(
            topic: topic,
            category: category,
            resources: resources,
            roadmap: makeRoadmap(for: resources),
            tips: ["These are offline picks from LearnWise's built-in catalog. Connect to the internet for personalised recommendations."],
            isOffline: true
        )
    }
}
