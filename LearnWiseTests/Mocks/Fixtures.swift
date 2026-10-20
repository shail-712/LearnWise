import Foundation
import XCTest

enum Fixtures {
    /// The JSON text Gemini writes (the inner payload, not the whole HTTP body).
    /// Make sure gemini_sample_response.json is ticked for the LearnWiseTests target.
    static func samplePayload() throws -> Data {
        let url = try XCTUnwrap(
            Bundle(for: BundleToken.self).url(forResource: "gemini_sample_response", withExtension: "json"),
            "gemini_sample_response.json is missing from the test bundle"
        )
        return try Data(contentsOf: url)
    }

    /// Wraps model text in a `generateContent` HTTP response body.
    static func geminiEnvelope(text: String, finishReason: String = "STOP") throws -> Data {
        let envelope: [String: Any] = [
            "candidates": [
                [
                    "content": ["role": "model", "parts": [["text": text]]],
                    "finishReason": finishReason,
                ],
            ],
        ]
        return try JSONSerialization.data(withJSONObject: envelope)
    }
}

private final class BundleToken {}
