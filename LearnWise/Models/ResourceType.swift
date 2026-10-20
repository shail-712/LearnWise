import Foundation

enum ResourceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case video      // YouTube
    case pdf
    case course     // Coursera, edX, NPTEL, freeCodeCamp…
    case leetcode   // LeetCode / practice problems
    case notes      // Articles, docs, blogs, GeeksforGeeks…

    var id: String { rawValue }

    /// Section title on the results screen.
    var displayName: String {
        switch self {
        case .video: "YouTube Videos"
        case .pdf: "PDFs"
        case .course: "Courses"
        case .leetcode: "LeetCode Problems"
        case .notes: "Notes & Articles"
        }
    }

    /// SF Symbol name.
    var systemImage: String {
        switch self {
        case .video: "play.rectangle.fill"
        case .pdf: "doc.richtext"
        case .course: "graduationcap.fill"
        case .leetcode: "chevron.left.forwardslash.chevron.right"
        case .notes: "note.text"
        }
    }
}

extension ResourceType {
    // An unexpected value from the model ("article", "podcast"…) becomes notes.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ResourceType(rawValue: raw.lowercased()) ?? .notes
    }
}
