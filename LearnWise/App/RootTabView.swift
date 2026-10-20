import SwiftUI

enum AppTab: Hashable {
    case discover, bookmarks, history, settings
}

struct RootTabView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var router = AppRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView(provider: environment.recommendationEngine)
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }
                .tag(AppTab.discover)

            BookmarksView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
                .tag(AppTab.bookmarks)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(AppTab.history)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .environment(router)
        .opensLinksInApp()
    }
}

#Preview {
    RootTabView()
        .environment(AppEnvironment.preview)
        .modelContainer(PersistenceController.preview)
}
