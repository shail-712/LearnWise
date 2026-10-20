import SwiftData
import SwiftUI

@main
struct LearnWiseApp: App {
    @State private var environment = AppEnvironment.forLaunch()

    // UI tests start from an empty, throwaway store every time.
    private let container = AppEnvironment.isUITesting
        ? PersistenceController.makeContainer(inMemory: true)
        : PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(environment)
        }
        .modelContainer(container)
    }
}
