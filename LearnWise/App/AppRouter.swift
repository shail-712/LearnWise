import Foundation
import Observation

/// App-wide navigation state that crosses tabs, e.g. History asking Discover to search again.
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .discover
    /// Set by History; HomeView picks it up, fills the form, runs the search and clears it.
    var pendingSearch: LearningRequest?

    func searchAgain(_ request: LearningRequest) {
        pendingSearch = request
        selectedTab = .discover
    }
}
