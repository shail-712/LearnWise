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

### Phase 0: Project Setup _(Mac)_
- [ ] Xcode → File → New → Project → iOS **App** → name `LearnWise`, Interface **SwiftUI**, Storage **SwiftData**, include tests
- [ ] Set the deployment target to **iOS 17.0**
- [ ] **Delete the template's `LearnWiseApp.swift`, `ContentView.swift` and `Item.swift`.** Ours replace them; keeping both gives a duplicate `@main` error.
- [ ] Drag the existing `LearnWise/`, `LearnWiseTests/` and `LearnWiseUITests/` folders into Xcode ("Create groups", tick the matching target). Leave `Tools/` out of every target.
- [ ] Check target membership: `resources_catalog.json` → LearnWise; `gemini_sample_response.json` → LearnWiseTests
- [x] Add `Config/Secrets.example.xcconfig` and `.gitignore`
- [ ] Copy it to `Secrets.xcconfig` and add your key
- [ ] Wire the xcconfig to the build configurations and add the Info.plist keys
- [ ] `git init` + first commit

> **Legend:** ✍️ = written on Windows, not yet compiled. Change it to `[x]` after it builds and its tests pass in Xcode.

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
- [ ] Try the prompt on Windows: `.\Tools\test_gemini.ps1` (needs a key)
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
- [ ] `BookmarksView` using `@Query(sort: \.createdAt, order: .reverse)`, grouped by topic
- [ ] Swipe-to-delete, empty state

### Phase 6: Search History
- [ ] Save a `SearchHistoryItem` (with cached JSON) after each successful search
- [ ] `HistoryView`: list, tap to reopen from cache, "Search again" action, swipe-to-delete, "Clear all"

### Phase 7: Learning Roadmap
- [ ] `RoadmapView`: vertical timeline of `RoadmapStepRow`s with linked resources
- [ ] Total estimated hours in the header
- [ ] "Save Roadmap" → `SavedRoadmap`
- [ ] _(Stretch)_ checkboxes for completed steps + a progress bar

### Phase 8: Offline + Core ML ✍️
> Moved up from "stretch": free-tier Gemini took 1.5–3 minutes and sometimes returned 503s in testing, so the offline mode keeps the demo working.
- [x] Write `resources_catalog.json` (20 topics, 141 resources; `validate_catalog.ps1` passes and 53 of 54 URLs load. realpython.com blocks scripts but works in a browser.)
- [ ] ✍️ `OfflineCatalogService` keyword matching + rule-based roadmap + `OfflineCatalogServiceTests`
- [x] Prepare `Tools/CreateML/topics_training.csv` (255 rows, ≥ 30 per label)
- [ ] ✍️ `TopicClassifier` wrapper (Core ML or keyword rules) + `TopicClassifierTests`
- [ ] Train `LearnWiseTopicClassifier.mlmodel` in Create ML _(Mac)_ and add it to the target (ARCHITECTURE §6.2)
- [ ] Wire `OfflineCatalogService` in as the engine's `fallback` in `AppEnvironment` (Phase 2)
- [ ] Offline banner in `ResultsView`

### Phase 9: Polish and Testing
- [ ] App icon + accent color
- [ ] Dark mode check, Dynamic Type, VoiceOver labels
- [ ] Haptics on bookmark
- [ ] `SettingsView` (key status, model name, clear data, about)
- [ ] Unit tests ≥ 70% coverage on Services/ViewModels
- [ ] UI test for the main flow, using the `-UITestMockAI` launch argument
- [ ] Screenshots for the README

### Phase 10: Submission
- [ ] Final README with screenshots
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
| Create the `.xcodeproj` and add the files to the target | | ✅ |
| Wire the xcconfig + Info.plist keys | | ✅ |
| Train the Core ML model in Create ML | | ✅ |
| Build, fix compile errors, run on the simulator | | ✅ |
| SwiftUI previews, UI tuning, app icon | | ✅ |
| Run XCTest / XCUITest | | ✅ |

**Tips for writing Swift on Windows:**
- Install **VS Code + the Swift extension**, or the Swift toolchain for Windows (swift.org). It can syntax-check plain Swift such as models, `PromptBuilder`, and `LinkResolver`, but **not** SwiftUI, SwiftData, or Core ML.
- Keep the pure-logic files (models, prompt, link resolver) free of `import SwiftUI` so they can be checked on Windows.
- Test the Gemini prompt with `curl` now, so the JSON shape is settled before you reach the Mac:
  ```bash
  curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent" \
    -H "x-goog-api-key: $GEMINI_API_KEY" -H "Content-Type: application/json" \
    -d @request.json
  ```
- On the Mac: create the project first, then **drag the existing folders into Xcode** with "Create groups" and the target membership box checked.

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
