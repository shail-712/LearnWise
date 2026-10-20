import SwiftUI

/// Screens pushed onto a NavigationStack.
enum Route: Hashable {
    case results(LearningRequest, RecommendationResponse)
    case detail(Resource, topic: String)
    case roadmap(RecommendationResponse, level: SkillLevel)
}

extension View {
    /// Registers the destination for every `Route`, so each tab's stack handles them the same way.
    func learnWiseRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .results(let request, let response):
                ResultsView(request: request, response: response)
            case .detail(let resource, let topic):
                ResourceDetailView(resource: resource, topic: topic)
            case .roadmap(let response, let level):
                RoadmapView(response: response, level: level)
            }
        }
    }
}
