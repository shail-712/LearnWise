import SwiftUI

/// One resource row. Tapping it opens the resolved link.
struct ResourceCard: View {
    let resource: Resource
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = resource.resolvedURL {
                openURL(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(resource.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if !resource.description.isEmpty {
                    Text(resource.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 8) {
                    DifficultyBadge(level: resource.difficulty)
                    if !resource.source.isEmpty {
                        Text(resource.source)
                            .lineLimit(1)
                    }
                    if let duration = resource.durationText {
                        Label(duration, systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(resource.resolvedURL == nil)
        .accessibilityHint("Opens the resource")
    }
}

struct DifficultyBadge: View {
    let level: SkillLevel

    var body: some View {
        Text(level.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch level {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
    }
}

#Preview {
    List(SampleData.resources) { resource in
        ResourceCard(resource: resource)
    }
}
