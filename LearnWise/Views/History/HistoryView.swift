import SwiftData
import SwiftUI

/// Past searches. Tapping one reopens its cached results instantly, with no Gemini call.
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \SearchHistoryItem.searchedAt, order: .reverse) private var items: [SearchHistoryItem]
    @State private var confirmingClear = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    row(for: item)
                        .swipeActions(edge: .leading) {
                            Button {
                                router.searchAgain(item.request)
                            } label: {
                                Label("Search Again", systemImage: "arrow.clockwise")
                            }
                            .tint(.accentColor)
                        }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(items[index])
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) {
                            confirmingClear = true
                        }
                        .accessibilityIdentifier("clearHistoryButton")
                    }
                }
            }
            .confirmationDialog("Clear all search history?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) {
                    withAnimation { modelContext.clearHistory() }
                }
            } message: {
                Text("Bookmarks and saved roadmaps are kept.")
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Searches Yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Your past searches will appear here.")
                    )
                }
            }
            .learnWiseRoutes()
        }
    }

    @ViewBuilder
    private func row(for item: SearchHistoryItem) -> some View {
        if let cached = item.cached {
            NavigationLink(value: Route.results(item.request, cached)) {
                HistoryRow(item: item, resourceCount: cached.resources.count, isOffline: cached.isOffline)
            }
        } else {
            // Nothing cached (e.g. an older entry): run the search again instead.
            Button {
                router.searchAgain(item.request)
            } label: {
                HistoryRow(item: item, resourceCount: nil, isOffline: false)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct HistoryRow: View {
    let item: SearchHistoryItem
    let resourceCount: Int?
    let isOffline: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.topic)
                    .font(.headline)
                Spacer()
                DifficultyBadge(level: item.level)
            }

            if let goal = item.goal {
                Label(goal, systemImage: "target")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                Text(item.searchedAt, format: .relative(presentation: .named))
                if let resourceCount {
                    Text("· \(resourceCount) resources")
                } else {
                    Text("· Tap to search again")
                }
                if isOffline {
                    Label("Offline", systemImage: "wifi.slash")
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Offline results")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    HistoryView()
        .environment(AppRouter())
        .modelContainer(PersistenceController.preview)
}
