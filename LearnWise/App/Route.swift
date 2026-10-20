import SwiftUI

/// Screens pushed onto a NavigationStack. The roadmap route is added in Phase 7.
enum Route: Hashable {
    case results(LearningRequest, RecommendationResponse)
    case detail(Resource, topic: String)
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
            }
        }
    }
}
