import SwiftUI

/// Placeholder until Phase 5 (bookmarks).
struct BookmarksView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Bookmarks Yet",
                systemImage: "bookmark",
                description: Text("Resources you bookmark will appear here.")
            )
            .navigationTitle("Bookmarks")
        }
    }
}

#Preview {
    BookmarksView()
}
