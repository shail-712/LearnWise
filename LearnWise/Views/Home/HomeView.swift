import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HomeViewModel
    @State private var path: [Route] = []
    @FocusState private var focusedField: Field?

    private enum Field {
        case topic, goal
    }

    init(provider: any RecommendationProviding) {
        _viewModel = State(initialValue: HomeViewModel(provider: provider))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $path) {
            Form {
                Section {
                    TextField("e.g. Dynamic Programming", text: $viewModel.topic)
                        .focused($focusedField, equals: .topic)
                        .submitLabel(.search)
                        .onSubmit { search() }
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("topicField")

                    SuggestedTopicsRow { viewModel.useSuggestion($0) }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } header: {
                    Text("What do you want to learn?")
                } footer: {
                    if let message = viewModel.validationMessage {
                        Text(message).foregroundStyle(.red)
                    }
                }

                Section("Your level") {
                    SkillLevelPicker(selection: $viewModel.level)
                }

                Section {
                    TextField("e.g. Crack coding interviews in 4 weeks", text: $viewModel.goal, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($focusedField, equals: .goal)
                        .accessibilityIdentifier("goalField")
                } header: {
                    Text("Goal (optional)")
                } footer: {
                    Text("A goal helps LearnWise pick resources that fit your purpose and timeline.")
                }

                if let error = viewModel.state.error {
                    Section {
                        ErrorStateView(error: error) { search() }
                    }
                } else if viewModel.state == .empty {
                    Section {
                        ContentUnavailableView(
                            "No Resources Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try a broader or differently worded topic.")
                        )
                    }
                }

                Section {
                    Button {
                        search()
                    } label: {
                        Label("Get Recommendations", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canSubmit)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("searchButton")
                }
            }
            .navigationTitle("LearnWise")
            .disabled(viewModel.state.isLoading)
            .overlay {
                if viewModel.state.isLoading {
                    LoadingView(
                        message: "Finding the best resources for \(viewModel.request.topic)…",
                        detail: "This can take a minute or two.",
                        startedAt: viewModel.searchStartedAt
                    ) {
                        viewModel.cancel()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.default, value: viewModel.state.isLoading)
            .onChange(of: viewModel.topic) {
                viewModel.dismissError()
            }
            .onChange(of: router.pendingSearch) {
                runPendingSearch()
            }
            .onAppear {
                runPendingSearch()
            }
            .learnWiseRoutes()
        }
    }

    /// Handles "Search again" from History.
    private func runPendingSearch() {
        guard let request = router.pendingSearch else { return }
        router.pendingSearch = nil
        path.removeAll()
        viewModel.prefill(from: request)
        search()
    }

    private func search() {
        focusedField = nil
        viewModel.search { request, response in
            modelContext.recordSearch(request, response: response)
            path.append(.results(request, response))
        }
    }
}

/// Horizontally scrolling chips that fill the topic field.
private struct SuggestedTopicsRow: View {
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Constants.suggestedTopics, id: \.self) { topic in
                    Button(topic) { onSelect(topic) }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    HomeView(provider: SampleRecommendationProvider())
        .environment(AppRouter())
        .modelContainer(PersistenceController.preview)
}
