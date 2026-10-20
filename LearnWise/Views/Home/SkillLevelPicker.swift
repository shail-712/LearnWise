import SwiftUI

struct SkillLevelPicker: View {
    @Binding var selection: SkillLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Skill level", selection: $selection) {
                ForEach(SkillLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("levelPicker")

            Text(selection.blurb)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .animation(nil, value: selection)
        }
        .padding(.vertical, 4)
    }
}

private extension SkillLevel {
    var blurb: String {
        switch self {
        case .beginner: "New to this topic. Start from the fundamentals."
        case .intermediate: "Know the basics. Ready for depth and practice."
        case .advanced: "Comfortable already. Looking for hard problems and theory."
        }
    }
}

#Preview {
    @Previewable @State var level = SkillLevel.beginner
    Form { SkillLevelPicker(selection: $level) }
}
