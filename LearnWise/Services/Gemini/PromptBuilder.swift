import Foundation

/// Builds the prompt and JSON schema sent to Gemini.
enum PromptBuilder {
    static let temperature = 0.4

    static let systemInstruction = """
    You are LearnWise, an expert study advisor for university students.
    Recommend high-quality, free-first learning resources.

    Rules:
    - Return 8-15 resources covering these types where relevant: video, pdf, course, leetcode, notes.
    - Only include "leetcode" items for programming or DSA topics, and use real LeetCode problem slugs.
    - Match difficulty to the student's level. For beginners, prefer fundamentals.
    - Prefer well-known sources: freeCodeCamp, MIT OpenCourseWare, NPTEL, Coursera, edX, \
    GeeksforGeeks, official documentation, and popular YouTube educators.
    - For every resource, give a "searchQuery" that would find it on its platform.
    - Only give a "url" if you are highly confident it is correct and still online. Otherwise use null.
    - Build a roadmap of 4-8 ordered steps. Each step lists the exact titles of the resources it uses.
    - Keep descriptions to one or two sentences.
    - Output only JSON that matches the provided schema.
    """

    static func userPrompt(for request: LearningRequest) -> String {
        """
        Topic: \(request.topic)
        Skill level: \(request.level.rawValue)
        Goal: \(request.goal ?? "General understanding")
        """
    }

    static func makeRequest(for request: LearningRequest) -> GeminiRequest {
        GeminiRequest(
            systemInstruction: GeminiContent(parts: [GeminiPart(text: systemInstruction)]),
            contents: [GeminiContent(role: "user", parts: [GeminiPart(text: userPrompt(for: request))])],
            generationConfig: .init(
                temperature: temperature,
                responseMimeType: "application/json",
                responseSchema: responseSchema
            )
        )
    }

    // MARK: Response schema

    static let responseSchema: JSONValue = object(
        [
            "topic": field("STRING"),
            "category": field("STRING"),
            "resources": array(of: resourceSchema),
            "roadmap": array(of: roadmapStepSchema),
            "tips": array(of: field("STRING")),
        ],
        required: ["topic", "category", "resources", "roadmap"]
    )

    private static let resourceSchema: JSONValue = object(
        [
            "title": field("STRING"),
            "type": field("STRING", enumValues: ResourceType.allCases.map(\.rawValue)),
            "description": field("STRING"),
            "source": field("STRING"),
            "difficulty": field("STRING", enumValues: SkillLevel.allCases.map(\.rawValue)),
            "estimatedMinutes": field("INTEGER", nullable: true),
            "url": field("STRING", nullable: true),
            "searchQuery": field("STRING"),
            "leetcodeSlug": field("STRING", nullable: true),
        ],
        required: ["title", "type", "description", "source", "difficulty", "searchQuery"]
    )

    private static let roadmapStepSchema: JSONValue = object(
        [
            "order": field("INTEGER"),
            "title": field("STRING"),
            "summary": field("STRING"),
            "resourceTitles": array(of: field("STRING")),
            "estimatedHours": field("NUMBER"),
        ],
        required: ["order", "title", "summary", "resourceTitles", "estimatedHours"]
    )

    private static func field(_ type: String, nullable: Bool = false, enumValues: [String]? = nil) -> JSONValue {
        var schema: [String: JSONValue] = ["type": .string(type)]
        if nullable {
            schema["nullable"] = .bool(true)
        }
        if let enumValues {
            schema["enum"] = .array(enumValues.map(JSONValue.string))
        }
        return .object(schema)
    }

    private static func array(of items: JSONValue) -> JSONValue {
        .object(["type": .string("ARRAY"), "items": items])
    }

    private static func object(_ properties: [String: JSONValue], required: [String]) -> JSONValue {
        .object([
            "type": .string("OBJECT"),
            "properties": .object(properties),
            "required": .array(required.map(JSONValue.string)),
        ])
    }
}
