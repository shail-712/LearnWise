import SwiftUI

/// A basic version: shows whether the AI is set up. Phase 9 adds clear-data and about.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Gemini API key") {
                        Label(
                            environment.config.hasGeminiKey ? "Configured" : "Missing",
                            systemImage: environment.config.hasGeminiKey ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundStyle(environment.config.hasGeminiKey ? Color.green : Color.red)
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
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppEnvironment.preview)
}
