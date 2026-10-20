import Foundation

/// Calls Gemini `generateContent` and decodes its JSON reply into a `RecommendationResponse`.
struct GeminiService: RecommendationProviding {
    let apiKey: String?
    let model: String
    var session: URLSession = .shared
    var maxRetries = 2

    func recommend(for request: LearningRequest) async throws -> RecommendationResponse {
        guard let apiKey, !apiKey.isEmpty else { throw AppError.missingAPIKey }
        try request.validate()
        let urlRequest = try makeURLRequest(for: request, apiKey: apiKey)

        var attempt = 0
        while true {
            do {
                return try await send(urlRequest)
            } catch let error as AppError where error.isRetryable && attempt < maxRetries {
                attempt += 1
                try await Task.sleep(for: .seconds(Self.backoffDelay(for: error, attempt: attempt)))
            }
        }
    }

    func makeURLRequest(for request: LearningRequest, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: "\(Constants.geminiBaseURL)/models/\(model):generateContent") else {
            throw AppError.unknown
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        // Free-tier replies took 1.5–3 minutes in testing (Oct 2026), so allow plenty of time.
        urlRequest.timeoutInterval = 180
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.httpBody = try JSONEncoder().encode(PromptBuilder.makeRequest(for: request))
        return urlRequest
    }

    // MARK: Networking

    private func send(_ urlRequest: URLRequest) async throws -> RecommendationResponse {
        let (data, response) = try await perform(urlRequest)
        guard let http = response as? HTTPURLResponse else { throw AppError.unknown }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(
                forStatus: http.statusCode,
                data: data,
                retryAfter: http.value(forHTTPHeaderField: "Retry-After")
            )
        }
        return try Self.parse(data)
    }

    private func perform(_ urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: urlRequest)
        } catch let error as URLError {
            // Let the cancellation propagate when the user leaves the screen.
            if error.code == .cancelled { throw CancellationError() }
            throw AppError.network(error)
        }
    }

    /// Waits 1 s, then 2 s, or uses the server's Retry-After (capped at 5 s).
    static func backoffDelay(for error: AppError, attempt: Int) -> Double {
        if case .rateLimited(let retryAfter?) = error {
            return min(retryAfter, 5)
        }
        return pow(2, Double(attempt - 1))
    }

    static func error(forStatus status: Int, data: Data, retryAfter: String?) -> AppError {
        let message = (try? JSONDecoder().decode(GeminiErrorResponse.self, from: data))?.error.message
        switch status {
        case 429:
            return .rateLimited(retryAfter: retryAfter.flatMap { TimeInterval($0) })
        case 401, 403:
            return .invalidAPIKey
        case 400 where message?.localizedCaseInsensitiveContains("API key") == true:
            // Gemini answers 400 "API key not valid" for a bad key.
            return .invalidAPIKey
        default:
            return .server(statusCode: status, message: message)
        }
    }

    // MARK: Parsing

    /// Decodes a full `generateContent` response body.
    static func parse(_ data: Data) throws -> RecommendationResponse {
        let envelope: GeminiResponse
        do {
            envelope = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw AppError.decoding(String(describing: error))
        }
        if envelope.isBlocked { throw AppError.blockedBySafety }
        guard let text = envelope.text else { throw AppError.emptyResponse }
        return try decodePayload(text)
    }

    /// Decodes the JSON text the model wrote. Strips ```json fences in case the model adds them.
    static func decodePayload(_ text: String) throws -> RecommendationResponse {
        var json = text.trimmed
        if json.hasPrefix("```"), let firstNewline = json.firstIndex(of: "\n") {
            json = String(json[json.index(after: firstNewline)...]).trimmed
            if json.hasSuffix("```") {
                json = String(json.dropLast(3))
            }
        }
        do {
            return try JSONDecoder().decode(RecommendationResponse.self, from: Data(json.utf8))
        } catch {
            throw AppError.decoding(String(describing: error))
        }
    }
}
