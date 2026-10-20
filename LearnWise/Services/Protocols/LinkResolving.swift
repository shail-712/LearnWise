import Foundation

/// Fills in `Resource.resolvedURL` with a link that's safe to open.
protocol LinkResolving: Sendable {
    func resolve(_ resources: [Resource]) async -> [Resource]
}

/// Finds a real YouTube video for a search query (YouTube Data API v3).
protocol YouTubeSearching: Sendable {
    func firstVideoURL(for query: String) async throws -> URL
}
