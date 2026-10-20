import SwiftUI

/// Placeholder until Phase 6 (search history). Searches are already being saved by HomeView.
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Searches Yet",
                systemImage: "clock.arrow.circlepath",
                description: Text("Your past searches will appear here.")
            )
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
