import Foundation
import SwiftData

enum PersistenceController {
    static var schema: Schema {
        Schema([BookmarkedResource.self, SearchHistoryItem.self, SavedRoadmap.self])
    }

    /// The on-disk store used by the app.
    @MainActor static let shared = makeContainer(inMemory: false)

    /// In-memory store with sample data, for SwiftUI previews.
    @MainActor static let preview: ModelContainer = {
        let container = makeContainer(inMemory: true)
        SampleData.insert(into: container.mainContext)
        return container
    }()

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
    }
}
