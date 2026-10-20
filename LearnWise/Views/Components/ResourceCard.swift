import SwiftUI

/// One resource row: title, description, difficulty, source, duration and a bookmark button.
/// The caller decides what tapping the row does (usually a NavigationLink to the detail screen).
struct ResourceCard: View {
    let resource: Resource
    var isBookmarked = false
    var onToggleBookmark: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(resource.title)
                    .font(.headline)
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
                            .labelStyle(.titleAndIcon)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onToggleBookmark {
                BookmarkButton(isBookmarked: isBookmarked, action: onToggleBookmark)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BookmarkButton: View {
    let isBookmarked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundStyle(.tint)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        // .borderless keeps the button tappable on its own inside a List row / NavigationLink.
        .buttonStyle(.borderless)
        .sensoryFeedback(.selection, trigger: isBookmarked)
        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark")
        .accessibilityIdentifier("bookmarkButton")
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
        ResourceCard(resource: resource, isBookmarked: resource.type == .video) {}
    }
}
