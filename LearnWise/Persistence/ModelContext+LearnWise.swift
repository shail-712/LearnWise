import Foundation
import SwiftData

/// Shared read/write helpers, so ViewModels don't each repeat their own fetch code.
extension ModelContext {

    // MARK: Bookmarks

    func bookmark(for resource: Resource) -> BookmarkedResource? {
        let key = BookmarkedResource.key(for: resource)
        var descriptor = FetchDescriptor<BookmarkedResource>(
            predicate: #Predicate<BookmarkedResource> { $0.key == key }
        )
        descriptor.fetchLimit = 1
        return (try? fetch(descriptor))?.first
    }

    func isBookmarked(_ resource: Resource) -> Bool {
        bookmark(for: resource) != nil
    }

    /// Adds the bookmark if it's missing, or removes it if it exists. Returns the new state.
    @discardableResult
    func toggleBookmark(_ resource: Resource, topic: String) -> Bool {
        if let existing = bookmark(for: resource) {
            delete(existing)
            return false
        }
        insert(BookmarkedResource(resource: resource, topic: topic))
        return true
    }

    // MARK: Search history

    /// Saves a search to history, replacing an identical earlier one and keeping the list short.
    func recordSearch(_ request: LearningRequest, response: RecommendationResponse) {
        let topic = request.topic
        let level = request.level.rawValue
        let duplicates = FetchDescriptor<SearchHistoryItem>(
            predicate: #Predicate<SearchHistoryItem> { $0.topic == topic && $0.levelRaw == level }
        )
        for item in (try? fetch(duplicates)) ?? [] where item.goal == request.goal {
            delete(item)
        }

        insert(SearchHistoryItem(request: request, response: response))
        trimHistory(to: Constants.maxHistoryItems)
    }

    func trimHistory(to limit: Int) {
        var descriptor = FetchDescriptor<SearchHistoryItem>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )
        descriptor.fetchOffset = limit
        for item in (try? fetch(descriptor)) ?? [] {
            delete(item)
        }
    }

    func clearHistory() {
        try? delete(model: SearchHistoryItem.self)
    }

    // MARK: Saved roadmaps

    func savedRoadmap(topic: String, level: SkillLevel) -> SavedRoadmap? {
        let levelRaw = level.rawValue
        var descriptor = FetchDescriptor<SavedRoadmap>(
            predicate: #Predicate<SavedRoadmap> { $0.topic == topic && $0.levelRaw == levelRaw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? fetch(descriptor))?.first
    }

    /// Saves the roadmap, or returns the one already saved for this topic and level.
    @discardableResult
    func saveRoadmap(_ response: RecommendationResponse, level: SkillLevel) -> SavedRoadmap {
        if let existing = savedRoadmap(topic: response.topic, level: level) {
            return existing
        }
        let roadmap = SavedRoadmap(response: response, level: level)
        insert(roadmap)
        return roadmap
    }

    // MARK: Clearing data (Settings)

    func clearBookmarks() {
        try? delete(model: BookmarkedResource.self)
    }

    func clearSavedRoadmaps() {
        try? delete(model: SavedRoadmap.self)
    }
}
