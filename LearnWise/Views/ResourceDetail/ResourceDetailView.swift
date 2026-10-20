import SwiftData
import SwiftUI

struct ResourceDetailView: View {
    let resource: Resource
    let topic: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var isBookmarked = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label(resource.type.displayName, systemImage: resource.type.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)

                    Text(resource.title)
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        DifficultyBadge(level: resource.difficulty)
                        if let duration = resource.durationText {
                            Label(duration, systemImage: "clock")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if !resource.description.isEmpty {
                Section("About") {
                    Text(resource.description)
                }
            }

            Section("Details") {
                if !resource.source.isEmpty {
                    LabeledContent("Source", value: resource.source)
                }
                LabeledContent("Topic", value: topic)
                if let host = resource.resolvedURL?.host() {
                    LabeledContent("Opens", value: host)
                }
            }

            if let url = resource.resolvedURL {
                Section {
                    Button {
                        openURL(url)
                    } label: {
                        Label(openTitle(for: url), systemImage: isSearchLink(url) ? "magnifyingglass" : "safari")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("openResourceButton")
                } footer: {
                    if isSearchLink(url) {
                        Text("LearnWise couldn't verify a direct link for this resource, so this opens a search that finds it.")
                    }
                }
            }
        }
        .navigationTitle(resource.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let url = resource.resolvedURL {
                    ShareLink(item: url, subject: Text(resource.title))
                }
                Button {
                    isBookmarked = modelContext.toggleBookmark(resource, topic: topic)
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .contentTransition(.symbolEffect(.replace))
                }
                .sensoryFeedback(.selection, trigger: isBookmarked)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark")
                .accessibilityIdentifier("detailBookmarkButton")
            }
        }
        .onAppear {
            isBookmarked = modelContext.isBookmarked(resource)
        }
    }

    private func isSearchLink(_ url: URL) -> Bool {
        url.isSearchFallback
    }

    private func openTitle(for url: URL) -> String {
        if isSearchLink(url) {
            return resource.type == .video ? "Search on YouTube" : "Search for it"
        }
        switch resource.type {
        case .video: return "Watch Video"
        case .pdf: return "Open PDF"
        case .course: return "Go to Course"
        case .leetcode: return "Solve on LeetCode"
        case .notes: return "Read"
        }
    }
}

#Preview {
    NavigationStack {
        ResourceDetailView(resource: SampleData.resources[3], topic: "Dynamic Programming")
    }
    .modelContainer(PersistenceController.preview)
}
