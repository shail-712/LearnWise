import SwiftUI

/// One section of results (e.g. "LeetCode Problems"). Each row opens the detail screen.
struct ResourceSectionView: View {
    let type: ResourceType
    let resources: [Resource]
    let topic: String
    let bookmarkedKeys: Set<String>
    let onToggleBookmark: (Resource) -> Void

    var body: some View {
        Section {
            ForEach(resources) { resource in
                let isBookmarked = bookmarkedKeys.contains(BookmarkedResource.key(for: resource))
                NavigationLink(value: Route.detail(resource, topic: topic)) {
                    ResourceCard(resource: resource, isBookmarked: isBookmarked) {
                        onToggleBookmark(resource)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        onToggleBookmark(resource)
                    } label: {
                        Label(isBookmarked ? "Remove" : "Bookmark", systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
                    }
                    .tint(.accentColor)
                }
                .contextMenu {
                    if let url = resource.resolvedURL {
                        Link(destination: url) {
                            Label("Open", systemImage: "safari")
                        }
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        } header: {
            Label(type.displayName, systemImage: type.systemImage)
        }
    }
}
