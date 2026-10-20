import Foundation
import NaturalLanguage

/// Guesses a broad category ("DSA", "Web", "ML"…) for a topic the catalog doesn't know.
protocol TopicClassifying: Sendable {
    func category(for topic: String) -> String
}

/// Uses the Create ML text classifier when it's in the app bundle, and keyword rules otherwise.
///
/// The model is loaded by name rather than through Xcode's generated class, so the app
/// still builds before the model has been trained. See ARCHITECTURE.md §6.2.
final class TopicClassifier: TopicClassifying, @unchecked Sendable {
    // @unchecked: `model` is set once in init and only read afterwards.

    static let modelName = "LearnWiseTopicClassifier"
    static let labels = ["DSA", "Web", "iOS", "ML", "Math", "Systems", "Databases", "General"]

    private let model: NLModel?

    var usesMLModel: Bool { model != nil }

    convenience init(bundle: Bundle = .main) {
        let url = bundle.url(forResource: Self.modelName, withExtension: "mlmodelc")
        self.init(model: url.flatMap { try? NLModel(contentsOf: $0) })
    }

    init(model: NLModel?) {
        self.model = model
    }

    func category(for topic: String) -> String {
        if let model, let label = model.predictedLabel(for: topic), Self.labels.contains(label) {
            return label
        }
        return Self.keywordCategory(for: topic) ?? "General"
    }

    // MARK: Keyword fallback

    /// Phrases are matched on whole words, after the same normalisation as the catalog.
    private static let keywordRules: [(category: String, phrases: [String])] = [
        ("DSA", ["algorithm", "data structure", "dsa", "array", "linked list", "stack", "queue", "heap",
                 "hash", "tree", "graph", "bfs", "dfs", "dp", "dynamic programming", "recursion",
                 "backtracking", "greedy", "sorting", "binary search", "trie", "leetcode", "competitive programming"]),
        ("Web", ["html", "css", "javascript", "js", "typescript", "react", "angular", "vue", "node",
                 "express", "frontend", "backend", "web", "api", "rest", "next js", "tailwind", "django", "flask"]),
        ("iOS", ["swift", "swiftui", "ios", "uikit", "xcode", "iphone", "ipad", "swiftdata", "core data", "watchos", "macos app"]),
        ("ML", ["machine learning", "ml", "deep learning", "neural network", "ai", "artificial intelligence",
                "nlp", "computer vision", "cnn", "rnn", "transformer", "llm", "pytorch", "tensorflow",
                "regression", "classification", "clustering", "data science", "pandas", "numpy"]),
        ("Math", ["math", "mathematics", "calculus", "algebra", "linear algebra", "matrix", "probability",
                  "statistic", "discrete", "combinatorics", "number theory", "geometry", "differential equation", "logic"]),
        ("Systems", ["operating system", "os", "network", "networking", "tcp", "linux", "unix", "computer architecture",
                     "compiler", "distributed system", "cloud", "docker", "kubernetes", "process", "thread", "memory management"]),
        ("Databases", ["sql", "database", "dbms", "mysql", "postgresql", "postgres", "mongodb", "nosql",
                       "normalization", "query", "index", "transaction", "join"]),
    ]

    static func keywordCategory(for topic: String) -> String? {
        let text = TopicText.padded(topic)
        var best: (category: String, score: Int)?
        for rule in keywordRules {
            // Longer phrases are stronger evidence: "linear algebra" beats a stray "algebra".
            let score = rule.phrases
                .map(TopicText.padded)
                .filter { text.contains($0) }
                .reduce(0) { $0 + $1.count }
            if score > 0, score > (best?.score ?? 0) {
                best = (rule.category, score)
            }
        }
        return best?.category
    }
}
