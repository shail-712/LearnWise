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
            "theodinproject.com", "fullstackopen.com", "hackingwithswift.com", "developers.google.com",
            "fast.ai", "py4e.com", "github.com",
        ]
        static let notes = [
            "geeksforgeeks.org", "developer.apple.com", "docs.python.org", "developer.mozilla.org",
            "w3schools.com", "cp-algorithms.com", "programiz.com", "wikipedia.org", "medium.com",
            "freecodecamp.org", "hackingwithswift.com", "swift.org", "tutorialspoint.com",
            "css-tricks.com", "javascript.info", "react.dev", "scikit-learn.org", "pytorch.org",
            "immersivemath.com", "beej.us", "sqlbolt.com", "realpython.com", "learngitbranching.js.org",
            "atlassian.com", "git-scm.com",
        ]
        static let pdf = [
            "ocw.mit.edu", "nptel.ac.in", "arxiv.org", "opendatastructures.org", "eloquentjavascript.net",
            "statlearning.com", "d2l.ai", "deeplearningbook.org", "axler.net", "openintro.org",
            "greenteapress.com", "systemsapproach.org", "db-book.com", "automatetheboringstuff.com",
            "git-scm.com",
        ]
        /// Accepted for PDFs, courses and notes: university sites are generally trustworthy.
        static let academic = ["edu", "ac.in", "ac.uk"]
    }
}
