import Foundation

enum AppError: LocalizedError, Equatable, Sendable {
    case invalidInput(String)
    case missingAPIKey
    case invalidAPIKey
    case network(URLError)
    case rateLimited(retryAfter: TimeInterval?)    // HTTP 429
    case server(statusCode: Int, message: String?)
    case decoding(String)
    case emptyResponse
    case blockedBySafety                           // Gemini refused the prompt
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            message
        case .missingAPIKey:
            "No Gemini API key is configured."
        case .invalidAPIKey:
            "The Gemini API key was rejected."
        case .network:
            "Couldn't reach the server. Check your internet connection."
        case .rateLimited:
            "Too many requests right now. Please wait a moment and try again."
        case .server(let statusCode, _):
            "The server returned an error (\(statusCode))."
        case .decoding:
            "The AI response couldn't be read."
        case .emptyResponse:
            "The AI didn't return any recommendations."
        case .blockedBySafety:
            "This topic couldn't be processed. Try rephrasing it."
        case .unknown:
            "Something went wrong."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey, .invalidAPIKey:
            "Add a valid key to Secrets.xcconfig. See the README for setup steps."
        case .network, .rateLimited, .server, .decoding, .emptyResponse, .unknown:
            "Tap Retry to try again."
        case .invalidInput, .blockedBySafety:
            nil
        }
    }

    /// Worth repeating the same request after a short wait.
    var isRetryable: Bool {
        switch self {
        case .rateLimited:
            true
        case .server(let statusCode, _):
            statusCode >= 500
        case .network(let error):
            error.code == .timedOut || error.code == .networkConnectionLost
        default:
            false
        }
    }

    /// The offline catalog can stand in when this error happens.
    var allowsFallback: Bool {
        switch self {
        case .invalidInput, .blockedBySafety:
            false
        default:
            true
        }
    }
}
