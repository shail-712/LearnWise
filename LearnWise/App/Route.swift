import SwiftUI

/// Screens pushed onto a NavigationStack. Roadmap and detail routes are added in Phases 4 and 7.
enum Route: Hashable {
    case results(LearningRequest, RecommendationResponse)
}

extension View {
    /// Registers the destination for every `Route`, so each tab's stack handles them the same way.
    func learnWiseRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .results(let request, let response):
                ResultsView(request: request, response: response)
            }
        }
    }
}
