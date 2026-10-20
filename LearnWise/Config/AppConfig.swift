import Foundation

/// API keys and model settings, read from Info.plist (which gets them from Secrets.xcconfig).
struct AppConfig: Sendable {
    let geminiKey: String?
    let geminiModel: String
    let youtubeKey: String?

    static let live = AppConfig(bundle: .main)
    static let mock = AppConfig(geminiKey: nil, geminiModel: Constants.defaultGeminiModel, youtubeKey: nil)

    init(geminiKey: String?, geminiModel: String, youtubeKey: String?) {
        self.geminiKey = geminiKey
        self.geminiModel = geminiModel
        self.youtubeKey = youtubeKey
    }

    init(bundle: Bundle) {
        geminiKey = Self.value(for: "GEMINI_API_KEY", in: bundle)
        geminiModel = Self.value(for: "GEMINI_MODEL", in: bundle) ?? Constants.defaultGeminiModel
        youtubeKey = Self.value(for: "YOUTUBE_API_KEY", in: bundle)
    }

    var hasGeminiKey: Bool { geminiKey != nil }

    private static func value(for key: String, in bundle: Bundle) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
        let value = raw.trimmed
        // An unexpanded "$(GEMINI_API_KEY)" means the xcconfig isn't attached to the target.
        if value.isEmpty || value.hasPrefix("$(") { return nil }
        return value
    }
}
