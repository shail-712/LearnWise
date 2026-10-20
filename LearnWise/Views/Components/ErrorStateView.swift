import SwiftUI

struct ErrorStateView: View {
    let error: AppError
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text(error.errorDescription ?? "Something went wrong.")
                .font(.headline)
                .multilineTextAlignment(.center)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retry, canRetry {
                Button("Retry", action: retry)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("retryButton")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// Retrying won't help when the input, the key or the topic itself is the problem.
    private var canRetry: Bool {
        switch error {
        case .invalidInput, .blockedBySafety, .missingAPIKey, .invalidAPIKey: false
        default: true
        }
    }

    private var iconName: String {
        switch error {
        case .network: "wifi.slash"
        case .rateLimited: "hourglass"
        case .missingAPIKey, .invalidAPIKey: "key.slash"
        default: "exclamationmark.triangle"
        }
    }
}

#Preview {
    List {
        ErrorStateView(error: .rateLimited(retryAfter: nil), retry: {})
        ErrorStateView(error: .blockedBySafety)
    }
}
