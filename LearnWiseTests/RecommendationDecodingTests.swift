import XCTest
@testable import LearnWise

final class RecommendationDecodingTests: XCTestCase {

    func testDecodesSamplePayload() throws {
        let response = try JSONDecoder().decode(RecommendationResponse.self, from: Fixtures.samplePayload())

        XCTAssertEqual(response.topic, "Dynamic Programming")
        XCTAssertEqual(response.category, "DSA")
        XCTAssertEqual(response.resources.count, 8)
        XCTAssertEqual(Set(response.availableTypes), Set(ResourceType.allCases))
        XCTAssertEqual(response.resources(of: .leetcode).count, 3)
        XCTAssertEqual(response.tips.count, 2)
        XCTAssertFalse(response.isOffline)
    }

    func testRoadmapIsSortedByOrder() throws {
        let response = try JSONDecoder().decode(RecommendationResponse.self, from: Fixtures.samplePayload())

        XCTAssertEqual(response.roadmap.map(\.order), [1, 2, 3, 4])
        XCTAssertEqual(response.totalRoadmapHours, 26)
    }

    func testRoadmapStepFindsItsResources() throws {
        let response = try JSONDecoder().decode(RecommendationResponse.self, from: Fixtures.samplePayload())
        let step = try XCTUnwrap(response.roadmap.first { $0.order == 2 })

        XCTAssertEqual(Set(response.resources(for: step).map(\.title)), ["Climbing Stairs", "House Robber"])
    }

    func testParsesGeminiEnvelope() throws {
        let text = String(decoding: try Fixtures.samplePayload(), as: UTF8.self)
        let response = try GeminiService.parse(Fixtures.geminiEnvelope(text: text))

        XCTAssertEqual(response.resources.count, 8)
    }

    func testStripsMarkdownFences() throws {
        let fenced = "```json\n{\"topic\": \"SQL\", \"category\": \"Databases\", \"resources\": [], \"roadmap\": []}\n```"
        let response = try GeminiService.decodePayload(fenced)

        XCTAssertEqual(response.topic, "SQL")
    }

    func testUnknownEnumValuesFallBack() throws {
        let json = """
        {"title": "Some Podcast", "type": "podcast", "description": "", "source": "Spotify", "difficulty": "expert", "searchQuery": "x"}
        """
        let resource = try JSONDecoder().decode(Resource.self, from: Data(json.utf8))

        XCTAssertEqual(resource.type, .notes)
        XCTAssertEqual(resource.difficulty, .beginner)
        XCTAssertNil(resource.resolvedURL)
    }

    func testSafetyBlockThrows() throws {
        let data = try Fixtures.geminiEnvelope(text: "", finishReason: "SAFETY")

        XCTAssertThrowsError(try GeminiService.parse(data)) { error in
            XCTAssertEqual(error as? AppError, .blockedBySafety)
        }
    }

    func testEmptyTextThrows() throws {
        let data = try Fixtures.geminiEnvelope(text: "  ")

        XCTAssertThrowsError(try GeminiService.parse(data)) { error in
            XCTAssertEqual(error as? AppError, .emptyResponse)
        }
    }

    func testMalformedJSONThrowsDecodingError() {
        XCTAssertThrowsError(try GeminiService.decodePayload("{ not json")) { error in
            guard case .decoding = error as? AppError else {
                return XCTFail("Expected AppError.decoding, got \(error)")
            }
        }
    }

    func testCachedResponseRoundTripKeepsClientFields() throws {
        var original = SampleData.response
        original.isOffline = true

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecommendationResponse.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testHTTPStatusMapping() {
        XCTAssertEqual(GeminiService.error(forStatus: 429, data: Data(), retryAfter: "3"), .rateLimited(retryAfter: 3))
        XCTAssertEqual(GeminiService.error(forStatus: 403, data: Data(), retryAfter: nil), .invalidAPIKey)

        let badKey = Data(#"{"error": {"code": 400, "message": "API key not valid. Please pass a valid API key."}}"#.utf8)
        XCTAssertEqual(GeminiService.error(forStatus: 400, data: badKey, retryAfter: nil), .invalidAPIKey)

        XCTAssertEqual(GeminiService.error(forStatus: 503, data: Data(), retryAfter: nil), .server(statusCode: 503, message: nil))
    }

    func testRequestBodyContainsSchemaAndPrompt() throws {
        let service = GeminiService(apiKey: "test-key", model: "gemini-3.8-flash")
        let urlRequest = try service.makeURLRequest(for: SampleData.request, apiKey: "test-key")
        let body = try XCTUnwrap(urlRequest.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let config = try XCTUnwrap(json["generationConfig"] as? [String: Any])

        XCTAssertEqual(urlRequest.url?.absoluteString, "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "x-goog-api-key"), "test-key")
        XCTAssertEqual(config["responseMimeType"] as? String, "application/json")
        XCTAssertNotNil(config["responseSchema"])
        XCTAssertTrue(String(decoding: body, as: UTF8.self).contains("Dynamic Programming"))
    }
}
