import Foundation
import SwiftData

/// Fixed data for SwiftUI previews and tests.
enum SampleData {
    static let request = LearningRequest(
        topic: "Dynamic Programming",
        level: .beginner,
        goal: "Prepare for coding interviews"
    )

    static let resources: [Resource] = [
        Resource(
            title: "Dynamic Programming - Learn to Solve Algorithmic Problems",
            type: .video,
            description: "A 5-hour freeCodeCamp course covering memoization and tabulation from scratch.",
            source: "freeCodeCamp (YouTube)",
            difficulty: .beginner,
            estimatedMinutes: 300,
            searchQuery: "freeCodeCamp dynamic programming course"
        ),
        Resource(
            title: "MIT 6.006 Lecture Notes: Dynamic Programming",
            type: .pdf,
            description: "Lecture notes on subproblems, recurrences and memoization.",
            source: "MIT OpenCourseWare",
            difficulty: .intermediate,
            estimatedMinutes: 60,
            searchQuery: "MIT 6.006 dynamic programming lecture notes"
        ),
        Resource(
            title: "Algorithms Specialization",
            type: .course,
            description: "Stanford's course on Coursera; Part 3 covers dynamic programming.",
            source: "Coursera",
            difficulty: .intermediate,
            estimatedMinutes: 900,
            url: "https://www.coursera.org/specializations/algorithms",
            searchQuery: "Stanford algorithms specialization coursera"
        ),
        Resource(
            title: "Climbing Stairs",
            type: .leetcode,
            description: "The classic first DP problem: count the ways to reach the top.",
            source: "LeetCode",
            difficulty: .beginner,
            estimatedMinutes: 20,
            searchQuery: "climbing stairs",
            leetcodeSlug: "climbing-stairs"
        ),
        Resource(
            title: "House Robber",
            type: .leetcode,
            description: "Choose non-adjacent houses to maximise the total.",
            source: "LeetCode",
            difficulty: .intermediate,
            estimatedMinutes: 30,
            searchQuery: "house robber",
            leetcodeSlug: "house-robber"
        ),
        Resource(
            title: "Introduction to Dynamic Programming",
            type: .notes,
            description: "An article on overlapping subproblems and optimal substructure.",
            source: "GeeksforGeeks",
            difficulty: .beginner,
            estimatedMinutes: 15,
            searchQuery: "geeksforgeeks dynamic programming introduction"
        ),
    ].map { resource in
        var resource = resource
        resource.resolvedURL = .googleSearch(resource.effectiveSearchQuery)
        return resource
    }

    static let roadmap: [RoadmapStep] = [
        RoadmapStep(
            order: 1,
            title: "Understand recursion and memoization",
            summary: "Learn how caching overlapping subproblems turns exponential recursion into linear time.",
            resourceTitles: ["Dynamic Programming - Learn to Solve Algorithmic Problems", "Introduction to Dynamic Programming"],
            estimatedHours: 6
        ),
        RoadmapStep(
            order: 2,
            title: "Solve 1-D DP problems",
            summary: "Practise writing the state, the recurrence and the base cases.",
            resourceTitles: ["Climbing Stairs", "House Robber"],
            estimatedHours: 3
        ),
        RoadmapStep(
            order: 3,
            title: "Go deeper with theory",
            summary: "Study formal DP techniques and classic problems.",
            resourceTitles: ["MIT 6.006 Lecture Notes: Dynamic Programming", "Algorithms Specialization"],
            estimatedHours: 12
        ),
    ]

    static let response = RecommendationResponse(
        topic: "Dynamic Programming",
        category: "DSA",
        resources: resources,
        roadmap: roadmap,
        tips: ["Write the recurrence on paper before coding.", "Start with memoization, then convert to tabulation."]
    )

    @MainActor
    static func insert(into context: ModelContext) {
        context.insert(SearchHistoryItem(request: request, response: response))
        context.insert(SearchHistoryItem(
            request: LearningRequest(topic: "SwiftUI", level: .intermediate),
            response: nil,
            searchedAt: .now.addingTimeInterval(-86_400)
        ))
        for resource in resources.prefix(3) {
            context.insert(BookmarkedResource(resource: resource, topic: response.topic))
        }
        context.insert(SavedRoadmap(response: response, level: request.level))
    }
}
