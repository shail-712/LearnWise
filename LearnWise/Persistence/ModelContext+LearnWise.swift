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
        defer { try? save() }
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
        try? save()
    }

    /// Keeps the newest `limit` searches.
    /// Sorting and trimming happen in Swift on purpose: SwiftData applies `fetchOffset` only to
    /// saved rows, so a just-inserted (unsaved) search would be returned and deleted.
    func trimHistory(to limit: Int) {
        let items = ((try? fetch(FetchDescriptor<SearchHistoryItem>())) ?? [])
            .sorted { $0.searchedAt > $1.searchedAt }
        for item in items.dropFirst(limit) {
            delete(item)
        }
    }

    func clearHistory() {
        deleteAll(SearchHistoryItem.self)
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
        try? save()
        return roadmap
    }

    // MARK: Clearing data (Settings)

    func clearBookmarks() {
        deleteAll(BookmarkedResource.self)
    }

    func clearSavedRoadmaps() {
        deleteAll(SavedRoadmap.self)
    }

    /// Deletes one by one rather than with `delete(model:)`: the batch delete bypasses the
    /// context, so `@Query` lists already on screen may not update until the app restarts.
    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        for item in (try? fetch(FetchDescriptor<T>())) ?? [] {
            delete(item)
        }
        try? save()
    }
}
