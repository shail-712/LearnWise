import XCTest
@testable import LearnWise

final class LinkResolverTests: XCTestCase {
    private let resolver = LinkResolver()

    private func makeResource(
        _ type: ResourceType,
        url: String? = nil,
        slug: String? = nil,
        query: String = "dynamic programming"
    ) -> Resource {
        Resource(
            title: "Test",
            type: type,
            description: "",
            source: "",
            difficulty: .beginner,
            url: url,
            searchQuery: query,
            leetcodeSlug: slug
        )
    }

    // MARK: LeetCode

    func testLeetCodeSlugBuildsProblemURL() async {
        let url = await resolver.url(for: makeResource(.leetcode, slug: "climbing-stairs"))
        XCTAssertEqual(url.absoluteString, "https://leetcode.com/problems/climbing-stairs/")
    }

    func testLeetCodeSlugIsSanitized() {
        XCTAssertEqual(LinkResolver.sanitizedSlug("Climbing Stairs"), "climbing-stairs")
        XCTAssertEqual(LinkResolver.sanitizedSlug("problems/two-sum/"), "two-sum")
        XCTAssertEqual(LinkResolver.sanitizedSlug("<script>"), "script")
    }

    func testLeetCodeWithoutSlugFallsBackToSearch() async {
        let url = await resolver.url(for: makeResource(.leetcode, query: "house robber"))
        XCTAssertEqual(url.host(), "leetcode.com")
        XCTAssertEqual(url.path(), "/problemset/")
        XCTAssertEqual(queryValue(url, "search"), "house robber")
    }

    // MARK: Video

    func testVideoIgnoresModelURLAndSearchesYouTube() async {
        let url = await resolver.url(for: makeResource(.video, url: "https://www.youtube.com/watch?v=madeUp", query: "dp tutorial"))
        XCTAssertEqual(url.host(), "www.youtube.com")
        XCTAssertEqual(url.path(), "/results")
        XCTAssertEqual(queryValue(url, "search_query"), "dp tutorial")
    }

    func testVideoUsesYouTubeServiceWhenAvailable() async {
        let resolver = LinkResolver(youtube: MockYouTubeService())
        let url = await resolver.url(for: makeResource(.video))
        XCTAssertEqual(url.absoluteString, "https://www.youtube.com/watch?v=mock123")
    }

    // MARK: Allow-list

    func testTrustedCourseURLIsKept() async {
        let link = "https://www.coursera.org/specializations/algorithms"
        let url = await resolver.url(for: makeResource(.course, url: link))
        XCTAssertEqual(url.absoluteString, link)
    }

    func testUntrustedCourseURLBecomesGoogleSearch() async {
        let url = await resolver.url(for: makeResource(.course, url: "https://random-course-site.xyz/dp"))
        XCTAssertEqual(url.host(), "www.google.com")
    }

    func testLookalikeDomainIsRejected() async {
        let url = await resolver.url(for: makeResource(.course, url: "https://coursera.org.evil.com/learn"))
        XCTAssertEqual(url.host(), "www.google.com")
    }

    func testPlainHTTPIsRejected() async {
        let url = await resolver.url(for: makeResource(.notes, url: "http://www.geeksforgeeks.org/dp"))
        XCTAssertEqual(url.host(), "www.google.com")
    }

    func testAcademicPDFIsKept() async {
        let link = "https://web.stanford.edu/class/cs161/notes/dp.pdf"
        let url = await resolver.url(for: makeResource(.pdf, url: link))
        XCTAssertEqual(url.absoluteString, link)
    }

    func testPDFFallbackSearchesForPDFs() async {
        let url = await resolver.url(for: makeResource(.pdf, query: "dp notes"))
        XCTAssertEqual(queryValue(url, "q"), "dp notes filetype:pdf")
    }

    // MARK: Encoding and batch

    func testPlusSignIsEncoded() async {
        let url = await resolver.url(for: makeResource(.video, query: "C++ dp"))
        XCTAssertTrue(url.absoluteString.contains("C%2B%2B"), url.absoluteString)
    }

    func testResolveFillsEveryResource() async {
        let resolved = await resolver.resolve(SampleData.resources)
        XCTAssertEqual(resolved.count, SampleData.resources.count)
        XCTAssertTrue(resolved.allSatisfy { $0.resolvedURL?.isHTTPS == true })
    }

    private func queryValue(_ url: URL, _ name: String) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
