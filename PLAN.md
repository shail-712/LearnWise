# LearnWise: Development Plan

## 1. Problem Statement
Students waste time searching scattered platforms (YouTube, PDFs, MOOCs, LeetCode, blogs) for material that matches their **level** and **goal**. LearnWise takes a topic, a skill level, and an optional goal, and uses AI to return a **curated, grouped, level-appropriate** set of resources plus an ordered **learning roadmap**.

## 2. Objectives
1. Build a native iOS app in **SwiftUI** following **MVVM**.
2. Use the **Google Gemini API** (free tier) to generate structured recommendations.
3. Present resources grouped by type: Videos, PDFs, Courses, LeetCode, Notes.
4. Generate a step-by-step **learning roadmap**.
5. Persist **bookmarks**, **search history**, and **roadmaps** with **SwiftData**.
6. Provide an **offline fallback**, optionally powered by a **Core ML** topic classifier.

## 3. Scope

### MVP (must have)
- [ ] Input screen: topic, skill level, optional goal
- [ ] Gemini integration with structured JSON output
- [ ] Results screen grouped by resource type
- [ ] Open resources in the in-app Safari view
- [ ] Bookmarks (add / remove / list)
- [ ] Search history (list / re-run / delete)
- [ ] Learning roadmap view + save
- [ ] Loading / empty / error states

### Stretch (nice to have)
- [ ] Offline catalog fallback
- [ ] Core ML `TopicClassifier`
- [ ] YouTube Data API lookups for real video links
- [ ] Roadmap progress tracking (tick off steps)
- [ ] Share a roadmap (`ShareLink`)
- [ ] Widget for the "next step"

### Out of scope
- User accounts / cloud sync
- Backend server

---

## 4. Milestones

### Phase 0: Project Setup
- [x] `LearnWise.xcodeproj` generated with XcodeGen (three targets, iOS 17, Swift 5 mode, Info.plist keys, xcconfig wiring, resources); 65/65 Swift files checked as included
- [x] App icon + accent color in `Assets.xcassets`
- [x] `Config/LearnWise.xcconfig` (committed) optionally includes `Secrets.xcconfig` (gitignored), so the project builds with or without a key
- [ ] _(Mac)_ Copy `Secrets.example.xcconfig` → `Secrets.xcconfig`, paste your key, open `LearnWise.xcodeproj` (README → Getting Started)

> **Legend:** ✍️ = written on Windows. Change it to `[x]` after it builds and its tests pass in Xcode.
>
> **Verified on Windows (Swift 6.0 compiler, Linux/Docker):** all non-UI code (models, utilities, services, view models, AppEnvironment/AppRouter: 32 files) compiles, and **64 unit tests pass** (1 skipped until the Core ML model is added). Not compilable off a Mac: the SwiftUI views, the SwiftData models/persistence, `PersistenceTests` and the UI tests.

### Phase 1: Models and Persistence ✍️
- [ ] ✍️ `SkillLevel`, `ResourceType`, `LearningRequest`, `Resource`, `RoadmapStep`, `RecommendationResponse`
- [ ] ✍️ SwiftData `@Model`s: `BookmarkedResource`, `SearchHistoryItem`, `SavedRoadmap`
- [ ] ✍️ `PersistenceController` with an in-memory preview container + `ModelContext` helpers
- [ ] ✍️ `SampleData` for SwiftUI previews
- [ ] ✍️ Unit test: decode `gemini_sample_response.json` (`RecommendationDecodingTests`)

### Phase 2: Home / Input UI ✍️
- [ ] ✍️ `LearnWiseApp` + `AppEnvironment` (Gemini → offline fallback → LinkResolver; `-UITestMockAI` uses sample data and an in-memory store)
- [ ] ✍️ `RootTabView` with 4 tabs (Bookmarks/History are placeholders until Phases 5–6; Settings shows key status)
- [ ] ✍️ `HomeView`: topic `TextField`, segmented `SkillLevelPicker`, goal `TextField`, primary button
- [ ] ✍️ Suggested topic chips
- [ ] ✍️ `LoadingView` with elapsed timer + Cancel (free-tier Gemini takes 1.5–3 min), `ErrorStateView` with Retry
- [ ] ✍️ `HomeViewModel` with validation, `ViewState`, cancellation + `HomeViewModelTests`
- [ ] ✍️ Searches are saved to history; a basic `ResultsView` + `ResourceCard` show the results (Phase 4 extends them)
- [ ] ✍️ `RecommendationFlowUITests` (search → results, suggestion chips)
- [ ] Check in the simulator: layout, dark mode, keyboard behaviour

### Phase 3: Gemini Integration ✍️
- [ ] ✍️ `AppConfig` reads the keys from the Info.plist
- [ ] ✍️ `PromptBuilder` (system prompt, user prompt, `responseSchema`)
- [ ] ✍️ `GeminiService` (`URLSession`, request/response DTOs, retry/backoff, error mapping)
- [ ] ✍️ `RecommendationEngine` (primary → fallback → resolver) + `RecommendationEngineTests`
- [x] Prompt tested against the live Gemini API on Windows (`gemini-3.8-flash`: 10 resources, 5 steps, every field the app needs present)
- [ ] Test with a real key on the simulator. Log the raw JSON in DEBUG builds.

### Phase 4: Results and Link Resolution ✍️
- [ ] ✍️ `ResultsView` with sections per `ResourceType` (`ResourceSectionView`), a filter chip bar, and `ResultsViewModel` + tests
- [ ] ✍️ `ResourceCard` (title, source, difficulty badge, duration, bookmark button with haptic)
- [ ] ✍️ `ResourceDetailView` (open/share/bookmark; says when a link is a search rather than a direct link)
- [ ] ✍️ `LinkResolver` with allow-lists and search fallbacks (+ optional `YouTubeService`)
- [ ] ✍️ `SafariView` + `.opensLinksInApp()`: every http(s) link in the app opens in an in-app sheet
- [ ] ✍️ `LinkResolverTests`, `PersistenceTests`, UI test: results → detail → bookmark

### Phase 5: Bookmarks
- [ ] ✍️ Toggle bookmarks from `ResourceCard` and the detail screen (de-duplicated by `key`), done in Phase 4
- [ ] ✍️ `BookmarksView` ("Saved" tab) using `@Query(sort: \.createdAt, order: .reverse)`, grouped by topic, searchable
- [ ] ✍️ Swipe-to-delete, empty states; a Resources / Roadmaps segment

### Phase 6: Search History ✍️
- [ ] ✍️ Save a `SearchHistoryItem` (with cached JSON) after each successful search (duplicates replaced, max 50)
- [ ] ✍️ `HistoryView`: list, tap to reopen from cache (instant, no Gemini call), "Search Again" swipe → Discover via `AppRouter`, swipe-to-delete, "Clear" with confirmation

### Phase 7: Learning Roadmap ✍️
- [ ] ✍️ `RoadmapView`: vertical timeline of `RoadmapStepRow`s with linked resources
- [ ] ✍️ Total estimated hours in the header
- [ ] ✍️ "Save Roadmap" → `SavedRoadmap` (one per topic + level)
- [ ] ✍️ Checkboxes for completed steps + a progress bar (after saving)
- [ ] ✍️ Share the roadmap as text (`ShareLink`)

### Phase 8: Offline + Core ML ✍️
> Moved up from "stretch": free-tier Gemini took 1.5–3 minutes and sometimes returned 503s in testing, so the offline mode keeps the demo working.
- [x] Write `resources_catalog.json` (20 topics, 141 resources; validated, and 53 of 54 URLs load. realpython.com blocks scripts but works in a browser.)
- [ ] ✍️ `OfflineCatalogService` keyword matching + rule-based roadmap + `OfflineCatalogServiceTests`
- [x] Prepare `CreateML/topics_training.csv` (255 rows, ≥ 30 per label)
- [ ] ✍️ `TopicClassifier` wrapper (Core ML or keyword rules) + `TopicClassifierTests`
- [ ] Train `LearnWiseTopicClassifier.mlmodel` in Create ML _(Mac)_ and add it to the target (ARCHITECTURE §6.2)
- [ ] ✍️ Wire `OfflineCatalogService` in as the engine's `fallback` in `AppEnvironment`
- [ ] ✍️ Offline banner in `ResultsView`

### Phase 9: Polish and Testing
- [ ] App icon + accent color _(Mac: Assets.xcassets → AppIcon, one 1024×1024 PNG)_
- [ ] ✍️ System colors and materials only (dark mode should just work), Dynamic Type fonts, VoiceOver labels on icon buttons and roadmap steps
- [ ] Check dark mode, the largest Dynamic Type size and VoiceOver in the simulator _(Mac)_
- [ ] ✍️ Haptics on bookmark and step completion (`.sensoryFeedback`)
- [ ] ✍️ `SettingsView` (key status, model, offline catalog + classifier status, clear data per type, about)
- [ ] Unit tests: ~75 written across Models, Services, ViewModels and Persistence. Check coverage in Xcode _(Mac)_.
- [ ] ✍️ UI tests for the main flows (search, detail + bookmark, roadmap save, history) with `-UITestMockAI`
- [ ] Screenshots for the README _(Mac)_

### Phase 10: Submission
- [ ] ✍️ README updated with final features, architecture summary and the demo script
- [ ] Add screenshots to the README _(Mac)_
- [ ] Demo video (screen recording from the simulator)
- [ ] Project report / PPT
- [ ] Push to GitHub

---

## 5. Windows-Now / Mac-Later Checklist

Development is split because no Mac is available right now.

| Task | Windows (now) | Mac (later) |
|---|:---:|:---:|
| Write `.swift` source files | ✅ | |
| Write `resources_catalog.json`, `topics_training.csv`, sample Gemini JSON | ✅ | |
| Write the README / ARCHITECTURE / PLAN | ✅ | |
| Test Gemini prompts and the schema (Google AI Studio in a browser, or `curl`) | ✅ | |
| Create the `.xcodeproj`, wire the xcconfig + Info.plist keys, app icon | ✅ (XcodeGen) | |
| Compile + unit-test the non-UI code | ✅ (Swift 6 on Linux, 64 tests pass) | |
| Train the Core ML model in Create ML | | ✅ |
| Build the SwiftUI/SwiftData code, run on the simulator | | ✅ |
| SwiftUI previews, UI tuning | | ✅ |
| Run XCTest / XCUITest | | ✅ |

### First Mac session, step by step
1. **Clone** the repo and add your key (README → Getting Started), then open `LearnWise.xcodeproj`.
2. **⌘B.** The SwiftUI and SwiftData files couldn't be compiled on Windows. If Xcode reports an error, it shows the exact line.
3. **⌘U.** Run the tests. `OfflineCatalogServiceTests.testBundledCatalogLoads` confirms the catalog is in the app target.
4. **⌘R** on an iPhone simulator. Try a real Gemini search, then Airplane Mode for the offline mode.
5. **Create ML** _(optional)_: train `LearnWiseTopicClassifier.mlmodel` from `CreateML/topics_training.csv` (ARCHITECTURE §6.2), drag it into `LearnWise/Resources/` (tick the LearnWise target), and check that Settings shows "Core ML model".
6. **Polish:** check dark mode and large text, take screenshots for the README, and record the demo (README → Demo Script).

---

## 6. Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Gemini returns fake or broken URLs | Bad user experience | `LinkResolver` allow-lists + search-link fallbacks; optional YouTube Data API |
| Free-tier rate limits (HTTP 429) | Requests fail during the demo | Backoff retry, cached history, offline catalog |
| Malformed JSON from the model | App crash / empty screen | `responseSchema` + `responseMimeType`, `do/catch` decoding → `AppError.decoding` |
| No Mac during development | Compile errors found late | Keep code simple, avoid uncommon APIs, budget 1–2 Mac sessions for fixing |
| API key leaked on GitHub | Key abuse | xcconfig + `.gitignore`; regenerate the key if it leaks |
| Free-tier model name changes | 404 errors | Model name is configurable in `Secrets.xcconfig` |

---

## 7. Timeline (suggested, 6 weeks)

| Week | Work |
|---|---|
| 1 | Phases 0–1: docs, models, test Gemini prompts with curl, write the catalog JSON |
| 2 | Phases 2–3: Home UI, Gemini service, engine |
| 3 | Phase 4: Results, link resolver, Safari view |
| 4 | Phases 5–7: Bookmarks, History, Roadmap |
| 5 | Phase 8: Offline + Core ML (stretch); first full Mac build and fixes |
| 6 | Phases 9–10: polish, tests, screenshots, report, demo |

---

## 8. Deliverables
- Xcode project source (GitHub repo)
- `README.md`, `ARCHITECTURE.md`, `PLAN.md`
- Demo video + screenshots
- Mini-project report and presentation
