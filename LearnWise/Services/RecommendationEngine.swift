import Foundation

/// Ties the pipeline together: ask the primary provider (Gemini), fall back to the offline
/// one if that fails, then make every link safe to open.
struct RecommendationEngine: RecommendationProviding {
    let primary: any RecommendationProviding
    let fallback: (any RecommendationProviding)?
    let resolver: any LinkResolving

    init(
        primary: any RecommendationProviding,
        fallback: (any RecommendationProviding)? = nil,
        resolver: any LinkResolving = LinkResolver()
    ) {
        self.primary = primary
        self.fallback = fallback
        self.resolver = resolver
    }

    func recommend(for request: LearningRequest) async throws -> RecommendationResponse {
        try request.validate()

        var response: RecommendationResponse
        do {
            response = try await primary.recommend(for: request)
        } catch let error as AppError {
            guard error.allowsFallback, let fallback else { throw error }
            response = try await fallback.recommend(for: request)
            response.isOffline = true
        }

        response.resources = await resolver.resolve(response.resources)
        return response
    }
}
