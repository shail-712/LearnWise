import Foundation

enum Constants {
    static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta"
    static let defaultGeminiModel = "gemini-3.8-flash"
    static let youtubeSearchEndpoint = "https://www.googleapis.com/youtube/v3/search"

    static let maxTopicLength = 100
    static let maxGoalLength = 200
    static let maxHistoryItems = 50

    static let suggestedTopics = [
        "Data Structures",
        "Dynamic Programming",
        "SwiftUI",
        "Machine Learning",
        "SQL",
        "Operating Systems",
    ]

    /// Domains whose links from the model we show as-is. Anything else becomes a search link.
    /// A domain also matches its subdomains (e.g. "coursera.org" matches "www.coursera.org").
    enum AllowedHosts {
        static let video = ["youtube.com", "youtu.be"]
        static let leetcode = ["leetcode.com"]
        static let course = [
            "coursera.org", "edx.org", "nptel.ac.in", "swayam.gov.in", "freecodecamp.org",
            "udemy.com", "khanacademy.org", "ocw.mit.edu", "codecademy.com", "developer.apple.com",
        ]
        static let notes = [
            "geeksforgeeks.org", "developer.apple.com", "docs.python.org", "developer.mozilla.org",
            "w3schools.com", "cp-algorithms.com", "programiz.com", "wikipedia.org", "medium.com",
            "freecodecamp.org", "hackingwithswift.com", "swift.org", "tutorialspoint.com",
        ]
        static let pdf = ["ocw.mit.edu", "nptel.ac.in", "arxiv.org", "cs.cmu.edu", "stanford.edu"]
        /// Accepted for PDFs and notes: university sites are generally trustworthy.
        static let academic = ["edu", "ac.in", "ac.uk"]
    }
}
