import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.modelContext) private var modelContext
    @Query private var history: [SearchHistoryItem]
    @Query private var bookmarks: [BookmarkedResource]
    @Query private var roadmaps: [SavedRoadmap]

    @State private var pendingClear: ClearAction?
    // Filled in by .task: both read files from the app bundle.
    @State private var usesMLClassifier = false
    @State private var catalogTopicCount = 0

    private enum ClearAction: String, Identifiable {
        case history = "Search History"
        case bookmarks = "Bookmarks"
        case roadmaps = "Saved Roadmaps"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                aiSection
                offlineSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task {
                usesMLClassifier = TopicClassifier().usesMLModel
                catalogTopicCount = OfflineCatalogService.loadEntries(from: .main).count
            }
            .confirmationDialog(
                "Delete all \(pendingClear?.rawValue.lowercased() ?? "")?",
                isPresented: Binding(get: { pendingClear != nil }, set: { if !$0 { pendingClear = nil } }),
                titleVisibility: .visible,
                presenting: pendingClear
            ) { action in
                Button("Delete \(action.rawValue)", role: .destructive) {
                    clear(action)
                }
            } message: { _ in
                Text("This can't be undone.")
            }
        }
    }

    // MARK: Sections

    private var aiSection: some View {
        Section {
            LabeledContent("Gemini API key") {
                StatusLabel(isOn: environment.config.hasGeminiKey, on: "Configured", off: "Missing")
            }
            LabeledContent("Model", value: environment.config.geminiModel)
            LabeledContent("YouTube lookups", value: environment.config.youtubeKey == nil ? "Off (search links)" : "On")
        } header: {
            Text("AI")
        } footer: {
            if !environment.config.hasGeminiKey {
                Text("Without a key, LearnWise uses its built-in offline catalog. Add GEMINI_API_KEY to Secrets.xcconfig. See the README.")
            }
        }
    }

    private var offlineSection: some View {
        Section {
            LabeledContent("Catalog", value: "\(catalogTopicCount) topics")
            LabeledContent("Topic classifier") {
                StatusLabel(isOn: usesMLClassifier, on: "Core ML model", off: "Keyword rules")
            }
        } header: {
            Text("Offline mode")
        } footer: {
            Text("Used automatically when Gemini is unreachable, rate-limited or not configured.")
        }
    }

    private var dataSection: some View {
        Section("Your data") {
            clearButton(.history, count: history.count)
            clearButton(.bookmarks, count: bookmarks.count)
            clearButton(.roadmaps, count: roadmaps.count)
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
            Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                Label("Get a Gemini API key", systemImage: "key")
            }
        } header: {
            Text("About")
        } footer: {
            Text("LearnWise: AI-based student resource recommendations. iOS Development Mini-Project.")
        }
    }

    // MARK: Helpers

    private func clearButton(_ action: ClearAction, count: Int) -> some View {
        Button(role: .destructive) {
            pendingClear = action
        } label: {
            LabeledContent("Clear \(action.rawValue)", value: "\(count)")
        }
        .disabled(count == 0)
    }

    private func clear(_ action: ClearAction) {
        withAnimation {
            switch action {
            case .history: modelContext.clearHistory()
            case .bookmarks: modelContext.clearBookmarks()
            case .roadmaps: modelContext.clearSavedRoadmaps()
            }
        }
        pendingClear = nil
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct StatusLabel: View {
    let isOn: Bool
    let on: String
    let off: String

    var body: some View {
        Label(isOn ? on : off, systemImage: isOn ? "checkmark.circle.fill" : "minus.circle.fill")
            .foregroundStyle(isOn ? Color.green : Color.secondary)
    }
}

#Preview {
    SettingsView()
        .environment(AppEnvironment.preview)
        .modelContainer(PersistenceController.preview)
}
