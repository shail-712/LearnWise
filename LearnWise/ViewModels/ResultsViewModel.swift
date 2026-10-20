import Foundation
import Observation

@MainActor
@Observable
final class ResultsViewModel {
    let request: LearningRequest
    let response: RecommendationResponse
    /// nil means "All".
    var selectedType: ResourceType?

    init(request: LearningRequest, response: RecommendationResponse) {
        self.request = request
        self.response = response
    }

    /// Filter chips: only types that have results.
    var filterTypes: [ResourceType] {
        response.availableTypes
    }

    /// The sections to show under the current filter.
    var visibleTypes: [ResourceType] {
        guard let selectedType, filterTypes.contains(selectedType) else { return filterTypes }
        return [selectedType]
    }

    func count(of type: ResourceType) -> Int {
        response.resources(of: type).count
    }

    /// Tapping the selected chip again goes back to "All".
    func toggleFilter(_ type: ResourceType?) {
        selectedType = (selectedType == type) ? nil : type
    }
}
