import Foundation

extension URL {
    static func youtubeSearch(_ query: String) -> URL {
        searchURL(base: "https://www.youtube.com/results", queryName: "search_query", query: query)
    }

    static func leetcodeSearch(_ query: String) -> URL {
        searchURL(base: "https://leetcode.com/problemset/", queryName: "search", query: query)
    }

    static func googleSearch(_ query: String) -> URL {
        searchURL(base: "https://www.google.com/search", queryName: "q", query: query)
    }

    static func leetcodeProblem(slug: String) -> URL? {
        URL(string: "https://leetcode.com/problems/\(slug)/")
    }

    /// True for the search links LinkResolver builds when it can't trust a direct link
    /// (YouTube results, Google search, the LeetCode problem list).
    var isSearchFallback: Bool {
        let urlPath = path()
        return (isHosted(on: ["youtube.com"]) && urlPath == "/results")
            || (isHosted(on: ["google.com"]) && urlPath == "/search")
            || (isHosted(on: ["leetcode.com"]) && urlPath == "/problemset/")
    }

    var isHTTPS: Bool {
        scheme?.lowercased() == "https"
    }

    /// True if the host is one of `domains` or a subdomain of one.
    /// "www.coursera.org" matches "coursera.org"; "coursera.org.evil.com" does not.
    func isHosted(on domains: [String]) -> Bool {
        guard let host = host()?.lowercased() else { return false }
        return domains.contains { host == $0 || host.hasSuffix("." + $0) }
    }

    private static func searchURL(base: String, queryName: String, query: String) -> URL {
        // The base strings are constants, so these force unwraps can't fail.
        var components = URLComponents(string: base)!
        components.queryItems = [URLQueryItem(name: queryName, value: query)]
        // URLQueryItem leaves "+" alone, but servers read it as a space ("C++" → "C  ").
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url!
    }
}
