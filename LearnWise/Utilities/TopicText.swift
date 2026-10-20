import Foundation

/// Turns free-form topic text into comparable words, for catalog matching and keyword rules.
enum TopicText {
    /// Filler words that don't help identify a topic. "learning" is kept on purpose (machine learning).
    private static let stopWords: Set<String> = [
        "a", "an", "and", "the", "of", "in", "for", "to", "with", "on", "how",
        // Plurals are stripped before this check, so "fundamentals" arrives as "fundamental".
        "basic", "intro", "introduction", "fundamental", "learn", "tutorial", "course",
    ]

    /// "Graphs & BFS in C++!" → ["graph", "bfs", "c++"]
    static func tokens(_ text: String) -> [String] {
        let cleaned = text
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .map { $0.isLetter || $0.isNumber || $0 == "+" || $0 == "#" ? $0 : " " }
        return String(cleaned)
            .split(separator: " ")
            .map { singular(String($0)) }
            .filter { !stopWords.contains($0) }
    }

    /// The tokens joined with single spaces and padded, so " linked list " can be found with `contains`.
    static func padded(_ text: String) -> String {
        " " + tokens(text).joined(separator: " ") + " "
    }

    /// Light plural stripping: "graphs" → "graph", "trees" → "tree"; leaves "os" and "css" alone.
    /// It's applied to both the query and the keywords, so odd cases like "dbms" → "dbm" still match.
    private static func singular(_ word: String) -> String {
        guard word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss") else { return word }
        return String(word.dropLast())
    }
}
