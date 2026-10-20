import SwiftUI

/// Full-screen loading overlay. Shows elapsed time, because free-tier Gemini can take minutes.
struct LoadingView: View {
    let message: String
    var detail: String?
    var startedAt: Date?
    var cancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let startedAt {
                Text(startedAt, style: .timer)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Time elapsed")
            }

            if let cancel {
                Button("Cancel", role: .cancel, action: cancel)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("cancelSearchButton")
            }
        }
        .padding(32)
        .frame(maxWidth: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.15))
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    LoadingView(
        message: "Finding the best resources for Dynamic Programming…",
        detail: "This can take a minute or two.",
        startedAt: .now,
        cancel: {}
    )
}
