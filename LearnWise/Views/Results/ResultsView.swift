import SwiftData
import SwiftUI

/// Recommendations grouped by resource type, with a type filter and bookmarks.
struct ResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [BookmarkedResource]
    @State private var viewModel: ResultsViewModel

    init(request: LearningRequest, response: RecommendationResponse) {
        _viewModel = State(initialValue: ResultsViewModel(request: request, response: response))
    }

    private var bookmarkedKeys: Set<String> {
        Set(bookmarks.map(\.key))
    }

    var body: some View {
        let response = viewModel.response

        List {
            Section {
                ResultsHeader(request: viewModel.request, response: response)

                if !response.roadmap.isEmpty {
                    NavigationLink(value: Route.roadmap(response, level: viewModel.request.level)) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("View Learning Roadmap")
                                    .font(.headline)
                                Text("\(response.roadmap.count) steps · ~\(RoadmapStep.hoursText(response.totalRoadmapHours))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "map.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    .accessibilityIdentifier("roadmapLink")
                }
            }

            if viewModel.filterTypes.count > 1 {
                Section {
                    ResourceFilterBar(viewModel: viewModel)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }

            ForEach(viewModel.visibleTypes) { type in
                ResourceSectionView(
                    type: type,
                    resources: response.resources(of: type),
                    topic: response.topic,
                    bookmarkedKeys: bookmarkedKeys
                ) { resource in
                    toggleBookmark(resource)
                }
            }

            if !response.tips.isEmpty, viewModel.selectedType == nil {
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
        .animation(.default, value: viewModel.selectedType)
    }

    private func toggleBookmark(_ resource: Resource) {
        modelContext.toggleBookmark(resource, topic: viewModel.response.topic)
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

/// "All" plus one chip per resource type that has results.
private struct ResourceFilterBar: View {
    let viewModel: ResultsViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", systemImage: "square.grid.2x2", isSelected: viewModel.selectedType == nil) {
                    viewModel.toggleFilter(nil)
                }
                ForEach(viewModel.filterTypes) { type in
                    chip(
                        "\(type.shortName) \(viewModel.count(of: type))",
                        systemImage: type.systemImage,
                        isSelected: viewModel.selectedType == type
                    ) {
                        viewModel.toggleFilter(type)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func chip(_ title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let label = Label(title, systemImage: systemImage).font(.subheadline)
        if isSelected {
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .accessibilityAddTraits(.isSelected)
        } else {
            Button(action: action) { label }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
}

private extension ResourceType {
    var shortName: String {
        switch self {
        case .video: "Videos"
        case .pdf: "PDFs"
        case .course: "Courses"
        case .leetcode: "LeetCode"
        case .notes: "Notes"
        }
    }
}

#Preview {
    NavigationStack {
        ResultsView(request: SampleData.request, response: SampleData.response)
            .learnWiseRoutes()
    }
    .modelContainer(PersistenceController.preview)
}
