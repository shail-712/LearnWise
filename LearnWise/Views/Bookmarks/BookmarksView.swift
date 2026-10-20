import SwiftData
import SwiftUI

/// The "Saved" tab: bookmarked resources and saved roadmaps.
struct BookmarksView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case resources = "Resources"
        case roadmaps = "Roadmaps"
        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedResource.createdAt, order: .reverse) private var bookmarks: [BookmarkedResource]
    @Query(sort: \SavedRoadmap.createdAt, order: .reverse) private var roadmaps: [SavedRoadmap]
    @State private var segment = Segment.resources
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Show", selection: $segment) {
                        ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch segment {
                case .resources: resourceSections
                case .roadmaps: roadmapSection
                }

                // Shown as a row (not an overlay) so it never covers the segment picker.
                emptyState
                    .listRowBackground(Color.clear)
            }
            .navigationTitle("Saved")
            .searchable(text: $searchText, prompt: segment == .resources ? "Search bookmarks" : "Search roadmaps")
            .learnWiseRoutes()
        }
    }

    // MARK: Resources

    private var filteredBookmarks: [BookmarkedResource] {
        let query = searchText.trimmed
        guard !query.isEmpty else { return bookmarks }
        return bookmarks.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.topic.localizedCaseInsensitiveContains(query)
        }
    }

    @ViewBuilder
    private var resourceSections: some View {
        ForEach(filteredBookmarks.grouped(by: \.topic)) { group in
            Section(group.key) {
                ForEach(group.items) { bookmark in
                    NavigationLink(value: Route.detail(bookmark.toResource(), topic: bookmark.topic)) {
                        ResourceCard(resource: bookmark.toResource(), isBookmarked: true) {
                            withAnimation { modelContext.delete(bookmark) }
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(group.items[index])
                    }
                }
            }
        }
    }

    // MARK: Roadmaps

    private var filteredRoadmaps: [SavedRoadmap] {
        let query = searchText.trimmed
        guard !query.isEmpty else { return roadmaps }
        return roadmaps.filter { $0.topic.localizedCaseInsensitiveContains(query) }
    }

    @ViewBuilder
    private var roadmapSection: some View {
        if !filteredRoadmaps.isEmpty {
            Section {
                ForEach(filteredRoadmaps) { roadmap in
                    if let response = roadmap.response {
                        NavigationLink(value: Route.roadmap(response, level: roadmap.level)) {
                            SavedRoadmapRow(roadmap: roadmap)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(filteredRoadmaps[index])
                    }
                }
            }
        }
    }

    // MARK: Empty states

    @ViewBuilder
    private var emptyState: some View {
        let isEmpty = segment == .resources ? filteredBookmarks.isEmpty : filteredRoadmaps.isEmpty
        if isEmpty {
            if !searchText.trimmed.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if segment == .resources {
                ContentUnavailableView(
                    "No Bookmarks Yet",
                    systemImage: "bookmark",
                    description: Text("Tap the bookmark icon on any resource to save it here.")
                )
            } else {
                ContentUnavailableView(
                    "No Saved Roadmaps",
                    systemImage: "map",
                    description: Text("Open a roadmap from your results and tap Save Roadmap to track your progress.")
                )
            }
        }
    }
}

private struct SavedRoadmapRow: View {
    let roadmap: SavedRoadmap

    var body: some View {
        let total = roadmap.steps.count
        let done = Set(roadmap.completedStepOrders).count

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(roadmap.topic)
                    .font(.headline)
                Spacer()
                DifficultyBadge(level: roadmap.level)
            }
            ProgressView(value: roadmap.progress)
                .tint(roadmap.progress >= 1 ? Color.green : Color.accentColor)
            Text(roadmap.progress >= 1 ? "Completed 🎉" : "\(done) of \(total) steps done")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookmarksView()
        .modelContainer(PersistenceController.preview)
}
