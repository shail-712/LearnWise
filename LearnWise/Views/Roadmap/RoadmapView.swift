import SwiftData
import SwiftUI

/// The ordered learning path for one search. Saving it unlocks progress tracking.
struct RoadmapView: View {
    let response: RecommendationResponse
    let level: SkillLevel

    @Environment(\.modelContext) private var modelContext
    /// The saved copy of this roadmap, if there is one (matched by topic and level).
    @Query private var saved: [SavedRoadmap]
    @State private var confirmingRemoval = false

    init(response: RecommendationResponse, level: SkillLevel) {
        self.response = response
        self.level = level
        let topic = response.topic
        let levelRaw = level.rawValue
        _saved = Query(
            filter: #Predicate<SavedRoadmap> { $0.topic == topic && $0.levelRaw == levelRaw },
            sort: \.createdAt,
            order: .reverse
        )
    }

    private var savedRoadmap: SavedRoadmap? { saved.first }

    var body: some View {
        List {
            Section {
                RoadmapSummary(
                    response: response,
                    level: level,
                    savedRoadmap: savedRoadmap,
                    save: { _ = modelContext.saveRoadmap(response, level: level) }
                )
            }

            ForEach(response.roadmap) { step in
                Section {
                    RoadmapStepRow(
                        step: step,
                        isLast: step.id == response.roadmap.last?.id,
                        isCompleted: savedRoadmap?.isCompleted(step) ?? false,
                        canTrack: savedRoadmap != nil
                    ) {
                        savedRoadmap?.toggleCompletion(of: step)
                    }

                    ForEach(response.resources(for: step)) { resource in
                        NavigationLink(value: Route.detail(resource, topic: response.topic)) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resource.title)
                                        .font(.subheadline)
                                    Text(resource.source)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: resource.type.systemImage)
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Roadmap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: shareText, subject: Text("\(response.topic) roadmap"))
                if savedRoadmap != nil {
                    Menu {
                        Button("Remove Saved Roadmap", systemImage: "trash", role: .destructive) {
                            confirmingRemoval = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More")
                }
            }
        }
        .confirmationDialog("Remove this saved roadmap and its progress?", isPresented: $confirmingRemoval, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if let savedRoadmap {
                    modelContext.delete(savedRoadmap)
                }
            }
        }
        .overlay {
            if response.roadmap.isEmpty {
                ContentUnavailableView(
                    "No Roadmap",
                    systemImage: "map",
                    description: Text("This search didn't include a learning path.")
                )
            }
        }
    }

    /// Plain-text version for sharing on WhatsApp, Notes and so on.
    private var shareText: String {
        var lines = ["\(response.topic) learning roadmap (\(level.displayName)) from LearnWise", ""]
        for step in response.roadmap {
            lines.append("\(step.order). \(step.title) (\(step.durationText))")
            for resource in response.resources(for: step) {
                let link = resource.resolvedURL?.absoluteString ?? ""
                lines.append("   • \(resource.title) \(link)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

private struct RoadmapSummary: View {
    let response: RecommendationResponse
    let level: SkillLevel
    let savedRoadmap: SavedRoadmap?
    let save: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(response.topic)
                .font(.title2.bold())

            HStack(spacing: 16) {
                Label("\(response.roadmap.count) steps", systemImage: "list.number")
                Label("~\(RoadmapStep.hoursText(response.totalRoadmapHours))", systemImage: "clock")
                Text(level.displayName)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let savedRoadmap {
                let done = Set(savedRoadmap.completedStepOrders).count
                ProgressView(value: savedRoadmap.progress) {
                    Text("\(done) of \(response.roadmap.count) steps done")
                        .font(.footnote)
                }
                .tint(savedRoadmap.progress >= 1 ? Color.green : Color.accentColor)
                .accessibilityIdentifier("roadmapProgress")
            } else if !response.roadmap.isEmpty {
                Button(action: save) {
                    Label("Save Roadmap", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("saveRoadmapButton")

                Text("Save it to tick off steps and find it later in the Saved tab.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RoadmapView(response: SampleData.response, level: .beginner)
            .learnWiseRoutes()
    }
    .modelContainer(PersistenceController.preview)
}
