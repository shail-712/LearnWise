import SwiftUI

/// Recommendations grouped by resource type.
/// Phase 4 adds the type filter, bookmarks, the in-app browser and the detail screen.
struct ResultsView: View {
    let request: LearningRequest
    let response: RecommendationResponse

    var body: some View {
        List {
            Section {
                ResultsHeader(request: request, response: response)
            }

            ForEach(response.availableTypes) { type in
                Section {
                    ForEach(response.resources(of: type)) { resource in
                        ResourceCard(resource: resource)
                    }
                } header: {
                    Label(type.displayName, systemImage: type.systemImage)
                }
            }

            if !response.tips.isEmpty {
                Section("Tips") {
                    ForEach(response.tips, id: \.self) { tip in
                        Label(tip, systemImage: "lightbulb")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(response.topic)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ResultsHeader: View {
    let request: LearningRequest
    let response: RecommendationResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(response.category)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.tint.opacity(0.15), in: Capsule())
                Text(request.level.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(response.resources.count) resources")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let goal = request.goal {
                Label(goal, systemImage: "target")
                    .font(.subheadline)
            }

            if response.isOffline {
                Label("Showing offline suggestions. Gemini couldn't be reached.", systemImage: "wifi.slash")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("offlineBanner")
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ResultsView(request: SampleData.request, response: SampleData.response)
    }
}
