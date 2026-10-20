import Foundation

// Request and response bodies for the Gemini `generateContent` REST endpoint.
// https://ai.google.dev/api/generate-content

struct GeminiRequest: Encodable, Sendable {
    let systemInstruction: GeminiContent
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig

    struct GenerationConfig: Encodable, Sendable {
        let temperature: Double
        let responseMimeType: String
        let responseSchema: JSONValue
    }
}

struct GeminiContent: Codable, Sendable {
    var role: String?
    let parts: [GeminiPart]
}

struct GeminiPart: Codable, Sendable {
    let text: String?
}

struct GeminiResponse: Decodable, Sendable {
    let candidates: [Candidate]?
    let promptFeedback: PromptFeedback?

    struct Candidate: Decodable, Sendable {
        let content: GeminiContent?
        let finishReason: String?
    }

    struct PromptFeedback: Decodable, Sendable {
        let blockReason: String?
    }

    /// The text of the first candidate, or nil if it's empty.
    var text: String? {
        let parts = candidates?.first?.content?.parts ?? []
        return parts.compactMap(\.text).joined().nilIfBlank
    }

    var isBlocked: Bool {
        promptFeedback?.blockReason != nil || candidates?.first?.finishReason == "SAFETY"
    }
}

/// The body Gemini sends with a 4xx/5xx status.
struct GeminiErrorResponse: Decodable, Sendable {
    let error: Detail

    struct Detail: Decodable, Sendable {
        let code: Int?
        let message: String?
        let status: String?
    }
}
