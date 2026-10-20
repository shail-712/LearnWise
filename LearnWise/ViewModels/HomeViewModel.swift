import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var topic = ""
    var level: SkillLevel = .beginner
    var goal = ""

    private(set) var state: ViewState<RecommendationResponse> = .idle
    /// Shown under the topic field: a problem the student can fix before searching.
    private(set) var validationMessage: String?
    private(set) var searchStartedAt: Date?

    private let provider: any RecommendationProviding
    private var searchTask: Task<Void, Never>?
    /// Bumped on every search and cancel. A finished task only updates state if it's still the latest.
    private var searchID = 0

    init(provider: any RecommendationProviding) {
        self.provider = provider
    }

    var canSubmit: Bool {
        !topic.trimmed.isEmpty && !state.isLoading
    }

    var request: LearningRequest {
        LearningRequest(topic: topic, level: level, goal: goal)
    }

    /// Starts a search. `onSuccess` runs on the main actor once results arrive.
    /// Returns the task so tests can wait for it.
    @discardableResult
    func search(onSuccess: @escaping @MainActor (LearningRequest, RecommendationResponse) -> Void) -> Task<Void, Never>? {
        let request = self.request
        do {
            try request.validate()
        } catch {
            validationMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
            return nil
        }

        validationMessage = nil
        searchTask?.cancel()
        searchID += 1
        let id = searchID
        state = .loading
        searchStartedAt = .now

        let task = Task {
            let result: ViewState<RecommendationResponse>
            do {
                let response = try await provider.recommend(for: request)
                result = response.resources.isEmpty ? .empty : .loaded(response)
            } catch is CancellationError {
                return
            } catch let error as AppError {
                result = .failed(error)
            } catch {
                result = .failed(.unknown)
            }

            guard id == searchID, !Task.isCancelled else { return }
            state = result
            searchStartedAt = nil
            if case .loaded(let response) = result {
                onSuccess(request, response)
            }
        }
        searchTask = task
        return task
    }

    func cancel() {
        searchTask?.cancel()
        searchTask = nil
        searchID += 1
        searchStartedAt = nil
        state = .idle
    }

    func useSuggestion(_ suggestion: String) {
        topic = suggestion
        validationMessage = nil
    }

    /// Fills the form from an earlier search (used by History).
    func prefill(from request: LearningRequest) {
        topic = request.topic
        level = request.level
        goal = request.goal ?? ""
        validationMessage = nil
    }

    func dismissError() {
        if state.error != nil || state == .empty {
            state = .idle
        }
    }
}
