import Foundation

/// Optional: finds a real video with the YouTube Data API v3 instead of opening a search page.
///
/// Each search costs 100 units of the free 10,000/day quota, so about 100 lookups a day.
struct YouTubeService: YouTubeSearching {
    let apiKey: String
    var session: URLSession = .shared

    func firstVideoURL(for query: String) async throws -> URL {
        guard var components = URLComponents(string: Constants.youtubeSearchEndpoint) else {
            throw AppError.unknown
        }
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "1"),
            URLQueryItem(name: "safeSearch", value: "strict"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: apiKey),
        ]
        guard let url = components.url else { throw AppError.unknown }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.server(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }
        let result = try JSONDecoder().decode(SearchResponse.self, from: data)
        guard let videoID = result.items.first?.id.videoId,
              let videoURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)") else {
            throw AppError.emptyResponse
        }
        return videoURL
    }

    private struct SearchResponse: Decodable {
        let items: [Item]

        struct Item: Decodable {
            let id: ID
        }

        struct ID: Decodable {
            let videoId: String?
        }
    }
}
