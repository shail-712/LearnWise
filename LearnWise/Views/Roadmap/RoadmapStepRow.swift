import SwiftUI

/// A numbered step with a timeline line. Becomes a checkbox once the roadmap is saved.
struct RoadmapStepRow: View {
    let step: RoadmapStep
    var isLast = false
    var isCompleted = false
    var canTrack = false
    var onToggle: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            marker

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                    .strikethrough(isCompleted, color: .secondary)
                Text(step.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(step.durationText, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step.order): \(step.title)")
        .accessibilityValue(canTrack ? (isCompleted ? "Done" : "Not done") : "")
        .accessibilityAddTraits(canTrack ? .isButton : [])
    }

    @ViewBuilder
    private var marker: some View {
        if canTrack, let onToggle {
            Button(action: onToggle) {
                circle
            }
            .buttonStyle(.borderless)
            .sensoryFeedback(.success, trigger: isCompleted) { _, done in done }
            .accessibilityIdentifier("stepToggle\(step.order)")
        } else {
            circle
        }
    }

    private var circle: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? Color.green : Color.accentColor.opacity(0.15))
                .frame(width: 32, height: 32)
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
            } else {
                Text("\(step.order)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.tint)
            }
        }
        .overlay(alignment: .top) {
            // The connecting line runs down to the next step.
            if !isLast {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 2, height: 24)
                    .offset(y: 36)
            }
        }
        .contentShape(Circle())
    }
}

#Preview {
    List {
        RoadmapStepRow(step: SampleData.roadmap[0], isCompleted: true, canTrack: true) {}
        RoadmapStepRow(step: SampleData.roadmap[1], canTrack: true) {}
        RoadmapStepRow(step: SampleData.roadmap[2], isLast: true)
    }
}
