import Foundation

/// The state of a screen that loads something asynchronously.
enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(AppError)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: AppError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

extension ViewState: Equatable where Value: Equatable {}
