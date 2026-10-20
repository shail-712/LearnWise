# LearnWise 📚

> **AI-Based Student Resource Recommendation app for iOS, built with SwiftUI.**
> Tell LearnWise what you want to learn, your skill level, and (optionally) your goal. It recommends YouTube videos, PDFs, courses, LeetCode problems, and notes, and can arrange them into a step-by-step learning roadmap.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.10%20%7C%206-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![AI](https://img.shields.io/badge/AI-Google%20Gemini-4285F4)

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔍 **Smart Recommendations** | Enter a topic, a skill level (Beginner / Intermediate / Advanced), and an optional goal (e.g. "crack FAANG interviews", "university exam"). Gemini returns resources picked for that input. |
| 🗂 **Multi-type Resources** | Results are grouped into **YouTube Videos**, **PDFs**, **Courses**, **LeetCode Problems**, and **Notes / Articles**. |
| 🧭 **Learning Roadmap** | Turns the recommendations into an ordered path (Step 1 → Step N) with time estimates. Save it to tick off steps and track progress, or share it as text. |
| 🔖 **Saved** | Bookmark any resource, grouped by topic and searchable, alongside your saved roadmaps. Stored on the device with SwiftData. |
| 🕘 **Search History** | Past searches reopen **instantly** from a local cache, with no AI wait. Swipe to search again. |
| 🛡 **Safe Links** | AI-suggested URLs are only used if they're HTTPS and on a trusted domain. Otherwise LearnWise builds a search link and says so. |
| 🌐 **In-App Browser** | Every link opens in Safari inside the app (`SFSafariViewController`). |
| 📴 **Offline Fallback** | With no network, no API key or a rate limit, a hand-picked catalog (20 topics, 141 resources) and an optional Core ML topic classifier still return results. |
| 🌗 **Dark Mode & Accessibility** | System colors, Dynamic Type, VoiceOver labels and haptics. |

## 🧠 How It Works

```
Topic + level + goal
      │
      ▼
RecommendationEngine ──► GeminiService (structured JSON via responseSchema)
      │                      │ fails? (offline, 429, no key)
      │                      ▼
      │                 OfflineCatalogService ──► TopicClassifier (Core ML / keyword rules)
      ▼
LinkResolver (allow-list or safe search links)
      ▼
Results ─► Roadmap ─► Saved / History (SwiftData)
```
Full details are in **[ARCHITECTURE.md](ARCHITECTURE.md)**.

## 🎬 Demo Script (≈ 3 minutes)

1. **Discover:** tap the *Dynamic Programming* chip, choose *Beginner*, type the goal "Coding interviews", then tap **Get Recommendations**. Point out the elapsed timer and the Cancel button.
2. **Results:** show the type filter chips, bookmark *Climbing Stairs*, and open a card to show the detail screen and the in-app browser.
3. **Roadmap:** tap *View Learning Roadmap*, then **Save Roadmap**, then tick step 1. The progress bar moves.
4. **Saved tab:** show the bookmark and the saved roadmap with its progress.
5. **History:** reopen the search. It loads instantly from the cache.
6. **Offline:** turn on Airplane Mode and search "trees". You get offline suggestions, with the banner.
7. **Settings:** show the AI status, offline catalog and classifier status, and clearing data.

> Free-tier Gemini can take 1.5–3 minutes. For a live demo, run the first search before presenting, then use **History** to reopen it instantly.

## 📌 Status

All source code for Phases 1–10 has been written, and the tests are in place: about 75 unit tests and 6 UI tests. The project was written on Windows, so the Mac-only steps are still to do: create the Xcode project, build, train the Core ML model, add the app icon and take screenshots. See **[PLAN.md](PLAN.md)** for the checklist.

## 📸 Screenshots

> _To be added after running on the iOS Simulator._

| Discover | Results | Roadmap | Saved |
|---|---|---|---|
| _screenshot_ | _screenshot_ | _screenshot_ | _screenshot_ |

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.10 / Swift 6 |
| UI | SwiftUI (`NavigationStack`, `TabView`, `@Observable`) |
| Architecture | MVVM + Service layer (protocol-based, testable) |
| Concurrency | Swift Concurrency (`async/await`, `Task`) |
| AI / Recommendation | Google **Gemini API** (free tier) via REST `generateContent` with structured JSON output |
| On-device ML (optional) | **Core ML** text classifier trained with **Create ML** |
| Persistence | **SwiftData** (`@Model`, `ModelContainer`) |
| Networking | `URLSession` |
| In-app browser | `SFSafariViewController` |
| Testing | XCTest / Swift Testing, XCUITest |
| Dependencies | None (pure Apple frameworks) |

---

## 📋 Requirements

- macOS 14 Sonoma or later
- **Xcode 16** or later
- iOS **17.0+** Simulator or device
- A free **Gemini API key** from [Google AI Studio](https://aistudio.google.com/app/apikey)
- _(Optional)_ YouTube Data API v3 key, for real video lookups instead of search links

---

## 🚀 Getting Started

The Xcode project (`LearnWise.xcodeproj`) is already in the repo. There's no project setup to do.

### 1. Clone the repo
```bash
git clone https://github.com/shail-712/LearnWise.git
cd LearnWise
```

### 2. Add your Gemini key
```bash
cp LearnWise/Config/Secrets.example.xcconfig LearnWise/Config/Secrets.xcconfig
open -e LearnWise/Config/Secrets.xcconfig
```
Paste your key after `GEMINI_API_KEY =` and save. This file is gitignored, so never commit it.
> Without a key the app still builds and runs, on the offline catalog.

Then open the project:
```bash
open LearnWise.xcodeproj
```

### 3. Run
Select an iPhone simulator (e.g. iPhone 16) and press **⌘R**.
Building for a real iPhone needs your Apple ID: target → **Signing & Capabilities** → choose your **Team**. The simulator needs nothing.

### 4. Run tests
Press **⌘U**, or:
```bash
xcodebuild test -scheme LearnWise -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 📱 How to Use

1. Open the **Discover** tab.
2. Type a **topic**, e.g. `Dynamic Programming`, `SwiftUI`, `Linear Algebra`.
3. Pick your **skill level**: Beginner / Intermediate / Advanced.
4. _(Optional)_ Enter a **goal**, e.g. `Prepare for coding interviews in 4 weeks`.
5. Tap **Get Recommendations**.
6. Browse resources grouped by type, and filter with the chips. Tap a card for details, or tap 🔖 to bookmark it.
7. Tap **View Learning Roadmap** to see an ordered path. **Save Roadmap** lets you tick off steps.
8. Find bookmarks and roadmaps in **Saved**, and old searches in **History**. Swipe a search to run it again.

---

## 📁 Project Structure

```
LearnWise/
├── LearnWise.xcodeproj    # Open this in Xcode
├── LearnWise/
│   ├── App/               # App entry point, root TabView, dependency container
│   ├── Config/            # xcconfig files (Secrets is gitignored)
│   ├── Models/            # Codable DTOs + SwiftData @Model types
│   ├── Views/             # SwiftUI screens and reusable components
│   ├── ViewModels/        # @Observable view models
│   ├── Services/          # Gemini, LinkResolver, RecommendationEngine, Offline, Core ML
│   ├── Persistence/       # SwiftData container setup and helpers
│   ├── Utilities/         # Extensions, constants, AppError
│   └── Resources/         # Assets, resources_catalog.json, LearnWiseTopicClassifier.mlmodel
├── CreateML/              # Training data for the optional Core ML model (not in the app)
├── LearnWiseTests/
├── LearnWiseUITests/
├── README.md
├── ARCHITECTURE.md
└── PLAN.md
```
See **[ARCHITECTURE.md](ARCHITECTURE.md)** for the full design and **[PLAN.md](PLAN.md)** for the development roadmap.

---

## ⚠️ Notes on the Gemini Free Tier

- The free tier has **per-minute and per-day request limits**. LearnWise caches the last results and shows a friendly message on HTTP `429` responses.
- AI-generated links can be wrong. LearnWise does **not trust raw URLs** from the model. The `LinkResolver` checks or rebuilds every link (see ARCHITECTURE.md → *Link Resolution*).
- Calling an LLM API directly from the app exposes the key inside the app bundle. That's fine for a college project, but a production app should route requests through a small backend proxy.

---

## 👥 Team

| Name | Roll No. | Role |
|---|---|---|
| _Your Name_ | _xxxx_ | iOS Developer |

**Course:** iOS Development Mini-Project, Final Year (LY)
**Institute:** K. J. Somaiya

---

## 📄 License

This project was made for academic purposes. MIT License.
