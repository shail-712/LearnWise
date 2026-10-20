import Foundation

/// Turns the model's resource descriptions into links that are safe to open.
///
/// LLMs often invent URLs, so a model-suggested URL is only kept if it's HTTPS and on an
/// allow-listed domain (see `Constants.AllowedHosts`). Otherwise the resource gets a search
/// link on the right platform, which always works.
struct LinkResolver: LinkResolving {
    var youtube: (any YouTubeSearching)?

    init(youtube: (any YouTubeSearching)? = nil) {
        self.youtube = youtube
    }

    func resolve(_ resources: [Resource]) async -> [Resource] {
        // One at a time: without a YouTube key this is instant, and with one it's only a few calls.
        var resolved: [Resource] = []
        resolved.reserveCapacity(resources.count)
        for resource in resources {
            var copy = resource
            copy.resolvedURL = await url(for: resource)
            resolved.append(copy)
        }
        return resolved
    }

    func url(for resource: Resource) async -> URL {
        let query = resource.effectiveSearchQuery
        let suggested = resource.url.flatMap { URL(string: $0.trimmed) }

        switch resource.type {
        case .video:
            // Video IDs are what models invent most often, so never trust them. Look up or search.
            if let youtube, let found = try? await youtube.firstVideoURL(for: query) {
                return found
            }
            return .youtubeSearch(query)

        case .leetcode:
            if let rawSlug = resource.leetcodeSlug {
                let slug = Self.sanitizedSlug(rawSlug)
                if !slug.isEmpty, let problem = URL.leetcodeProblem(slug: slug) {
                    return problem
                }
            }
            return trusted(suggested, hosts: Constants.AllowedHosts.leetcode) ?? .leetcodeSearch(query)

        case .pdf:
            return trusted(suggested, hosts: Constants.AllowedHosts.pdf, allowAcademic: true)
                ?? .googleSearch("\(query) filetype:pdf")

        case .course:
            return trusted(suggested, hosts: Constants.AllowedHosts.course, allowAcademic: true)
                ?? .googleSearch("\(query) course")

        case .notes:
            return trusted(suggested, hosts: Constants.AllowedHosts.notes, allowAcademic: true)
                ?? .googleSearch(query)
        }
    }

    private func trusted(_ url: URL?, hosts: [String], allowAcademic: Bool = false) -> URL? {
        guard let url, url.isHTTPS else { return nil }
        if url.isHosted(on: hosts) { return url }
        if allowAcademic, url.isHosted(on: Constants.AllowedHosts.academic) { return url }
        return nil
    }

    /// "Climbing Stairs" → "climbing-stairs"; "problems/two-sum/" → "two-sum".
    static func sanitizedSlug(_ raw: String) -> String {
        let lastComponent = raw.split(separator: "/").last.map(String.init) ?? raw
        return lastComponent
            .trimmed
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { ($0.isASCII && ($0.isLetter || $0.isNumber)) || $0 == "-" }
    }
}
