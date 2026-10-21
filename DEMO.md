# LearnWise: Mac Setup & Test Guide

Use this the first time you run LearnWise on a Mac. It takes about 15 minutes, plus Xcode's download time if Xcode isn't installed yet.

> **Status:** all the app logic (models, Gemini, link checking, offline mode, view models) was compiled with Swift 6 and passed 64 unit tests on Windows. The SwiftUI screens and SwiftData storage can only be compiled on a Mac, so **step 4 is the real first check**. If Xcode shows an error there, see [Troubleshooting](#-troubleshooting).

---

## ✅ What You Need

| | |
|---|---|
| Mac | macOS 14 Sonoma or later |
| Xcode | **16 or later** (free on the Mac App Store) |
| Gemini key | The one in your Windows `.env` file (`GEMINI_API_KEY=...`). Copy it somewhere you can paste it on the Mac. |

The first time you open Xcode, let it install its components. If it asks for an **iOS Simulator** runtime, download it (Xcode → Settings → Components → iOS).

---

## 1. Get the Code

Open **Terminal** and run:

```bash
cd ~/Desktop
git clone https://github.com/shail-712/LearnWise.git
cd LearnWise
```

> If you haven't renamed the GitHub repo yet, use `https://github.com/shail-712/Mini-Project.git` instead and `cd Mini-Project`.

## 2. Add Your Gemini Key

```bash
cp LearnWise/Config/Secrets.example.xcconfig LearnWise/Config/Secrets.xcconfig
open -e LearnWise/Config/Secrets.xcconfig
```

In the window that opens, paste your key after the `=` and save (⌘S):

```
GEMINI_API_KEY = AIza...your key...
GEMINI_MODEL = gemini-3.8-flash
YOUTUBE_API_KEY =
```

> This file is gitignored, so it never gets committed. **No key?** Skip this step. The app still runs, using the built-in offline catalog.

## 3. Open the Project

```bash
open LearnWise.xcodeproj
```

In Xcode's toolbar, check that the scheme says **LearnWise**, then pick a simulator such as **iPhone 16**.

## 4. Build (⌘B)

Press **⌘B** and wait for **"Build Succeeded"**.

- ✅ **Succeeded:** go on to step 5.
- ❌ **Errors:** open the Issue Navigator (⌘5), click the first red error, and copy the error text and file name. See [Troubleshooting](#-troubleshooting), or paste it to Claude to fix.

> Yellow **warnings** are fine and don't stop the app running.

## 5. Run the Tests (⌘U)

Press **⌘U**. This runs about 75 unit tests and 6 UI tests, which open the app and tap through it by themselves.

- See the results in the Test Navigator (⌘6). Everything should be green ✅.
- `testBundledModelPredictsAKnownLabel` shows as **skipped** until you add the Core ML model (step 8). That's expected.

## 6. Run the App (⌘R)

Press **⌘R**. The simulator opens with LearnWise on the **Discover** tab.

First check **Settings** (gear tab):
- **Gemini API key → Configured ✅** means your key was picked up. If it says *Missing*, see Troubleshooting.
- **Catalog → 20 topics** means the offline data is bundled.

---

## 7. Test Every Feature (≈ 10 min)

Work through this checklist and tick each item.

### Discover + AI
- [ ] Tap the **Dynamic Programming** chip, choose **Beginner**, type the goal `Coding interviews`, then tap **Get Recommendations**.
- [ ] A loading card appears with a **timer** and a **Cancel** button. Free-tier Gemini can take **1.5–3 minutes**.
- [ ] The results open, grouped by **Videos / PDFs / Courses / LeetCode / Notes**.

### Results
- [ ] Tap the filter chips (e.g. **LeetCode**). Only that type shows. Tap it again to show **All**.
- [ ] Tap the 🔖 on a card. It fills in, with a small vibration on a real phone.
- [ ] Tap a card to open the **detail screen**, then tap the big button. The page opens **inside the app** (Safari sheet).

### Roadmap
- [ ] On the results, tap **View Learning Roadmap**.
- [ ] Tap **Save Roadmap**. A progress bar appears.
- [ ] Tap the circle of **step 1**. It turns into a green ✓ and the progress bar moves.

### Saved tab
- [ ] **Resources** shows your bookmark, grouped by topic.
- [ ] **Roadmaps** shows the saved roadmap with its progress.
- [ ] Swipe left on an item to delete it.

### History tab
- [ ] Your search is listed. Tap it and the results open **instantly**, with no waiting.
- [ ] Swipe right → **Search Again**. You go back to Discover and the search runs.

### Offline mode
- [ ] Turn off the Mac's Wi-Fi (the simulator uses the Mac's network).
- [ ] Search **trees**. Results appear quickly, with an orange **"Showing offline suggestions"** banner.
- [ ] Turn Wi-Fi back on.

### Settings
- [ ] **Clear Search History** asks for confirmation, then empties the History tab.

If everything above works, the app is done. 🎉

---

## 8. Optional: Train the Core ML Model

The app works without this, using keyword rules. It's a nice extra for the viva.

1. Xcode menu → **Xcode → Open Developer Tool → Create ML**.
2. **New Document → Text Classification** → name it `LearnWiseTopicClassifier`.
3. **Training Data** → choose `CreateML/topics_training.csv` from the project folder.
   - Text column: `text` · Label column: `label`
4. Click **Train**. When it finishes, try topics like "dijkstra" or "react hooks" in the **Preview** tab.
5. **Output** tab → **Get** → save it as **`LearnWiseTopicClassifier.mlmodel`**. Use exactly this name.
6. Drag the file into Xcode under **LearnWise → Resources**. In the dialog, tick **Copy items if needed** and the **LearnWise** target.
7. Run again (⌘R). **Settings → Topic classifier** should now say **Core ML model ✅**.

---

## 9. Record the Demo

- **Screenshots:** in the simulator, press ⌘S. They save to the Desktop.
- **Video:** in the simulator, choose **File → Record Screen**, or run `xcrun simctl io booted recordVideo demo.mov` in Terminal.
- Follow the **Demo Script** in [README.md](README.md#-demo-script--3-minutes).

> **Tip for a live demo:** Gemini is slow on the free tier. Run your searches **before** presenting, then reopen them from **History**. They load instantly.

---

## 🛠 Troubleshooting

| Problem | Fix |
|---|---|
| **Build errors in a SwiftUI or SwiftData file** | These files couldn't be compiled on Windows, so a small fix may be needed. Copy the exact error, file and line from the Issue Navigator (⌘5) and paste it to Claude. |
| `No such module 'SwiftData'`, or `'@Previewable' is unavailable` | Your Xcode is too old. Update to **Xcode 16+**. |
| **"Signing for LearnWise requires a development team"** | This only appears for a real iPhone. Select the **LearnWise** target → **Signing & Capabilities** → **Team** → choose your Apple ID (Add Account if needed). The simulator needs no team. |
| **Settings shows the Gemini key as Missing** | Check that `LearnWise/Config/Secrets.xcconfig` exists and has `GEMINI_API_KEY = yourkey` with no quotes. Then **Product → Clean Build Folder** (⇧⌘K) and run again. |
| **Search fails with a 404 or "model not found"** | Google retired the model name. Change `GEMINI_MODEL` in `Secrets.xcconfig` to a current one, e.g. `gemini-flash-latest`, then Clean Build and run. |
| **"Too many requests" / always offline results** | That's the free-tier rate limit. Wait a minute and try again. Offline results mean the fallback is working. |
| **Search takes minutes** | Normal on the free tier. Use History to reopen results instantly. |
| **Tests fail with "resources_catalog.json is missing"** | Select `LearnWise/Resources/resources_catalog.json` → File Inspector (⌥⌘1) → tick **LearnWise** under Target Membership. |
| **Simulator is stuck or blank** | In the simulator, choose **Device → Erase All Content and Settings**, then run again. |
| **Something else is weird** | Try **Product → Clean Build Folder** (⇧⌘K), quit and reopen Xcode, then build again. |

---

## 💾 Save Your Mac Changes

If you fix anything on the Mac, push it back so Windows gets it too:

```bash
git add -A
git commit -m "Fix build on macOS"
git push
```

(`Secrets.xcconfig` is ignored automatically, so your key never gets pushed.)
