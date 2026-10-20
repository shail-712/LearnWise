import Foundation
import Observation

/// Builds the services once at launch and hands them to views through `.environment(...)`.
@MainActor
@Observable
final class AppEnvironment {
    /// Launch argument that swaps Gemini for sample data and uses an in-memory store.
    static let uiTestArgument = "-UITestMockAI"

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestArgument)
    }

    let config: AppConfig
    let recommendationEngine: any RecommendationProviding

    init(config: AppConfig = .live, useSampleData: Bool = false) {
        self.config = config

        let primary: any RecommendationProviding
        if useSampleData {
            primary = SampleRecommendationProvider()
        } else {
            primary = GeminiService(apiKey: config.geminiKey, model: config.geminiModel)
        }
        let youtube = config.youtubeKey.map { YouTubeService(apiKey: $0) }

        recommendationEngine = RecommendationEngine(
            primary: primary,
            fallback: OfflineCatalogService(),
            resolver: LinkResolver(youtube: youtube)
        )
    }

    static func forLaunch() -> AppEnvironment {
        AppEnvironment(useSampleData: isUITesting)
    }

    static let preview = AppEnvironment(config: .mock, useSampleData: true)
}
