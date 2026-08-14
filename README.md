# 🪐 PLUTO (formerly LOCA) — Local-First Habit Tracker & Life OS

> **"Does it let me *see* my life, or does it just *show me data* about my life?"**  
> — *The Central Question, PLUTO Engineering Manifesto*

PLUTO is a **local-first personal habit tracker, day planner, and life operating system** with two fully independent, native platform implementations:
1. **macOS & iOS**: Built with Swift 6, SwiftUI, SwiftData, AppKit/UIKit, and CloudKit.
2. **Android**: Built with Kotlin Multiplatform (KMP), Jetpack Compose, Material 3, and Room SQLite.

All personal user data lives strictly on-device — no mandatory backend, no cloud lock-in, zero network dependency for core functionality. In V3.5, PLUTO introduces an **invisible, privacy-first Alpha Telemetry engine** paired with a real-time **Creator Analytics Web Dossier**.

---

## 🌟 The 6 Core Pillars Architecture

PLUTO unifies all personal productivity and intentional living into 6 core pillars, organized to match the natural rhythm of human focus:

```
                  ┌──────────────────────────────────────────────┐
                  │              🪐 PLUTO LIFE OS                │
                  └──────┬───────┬───────┬───────┬───────┬───────┘
                         │       │       │       │       │       │
       ┌─────────────────┘       │       │       │       │       └─────────────────┐
       ▼                         ▼       ▼       ▼       ▼                         ▼
┌──────────────┐         ┌──────────────┐┌──────────────┐┌──────────────┐   ┌──────────────┐
│  1. HABITS   │         │  2. TODAY    ││  3. TIME     ││  4. JOURNAL  │   │  5. LIFE     │
│  Keystone    │         │  Plan & List ││  Focus/Pomo  ││  Daylight    │   │  Bucket List │
│  Heatmaps    │         │  Timeline    ││  3D Audio    ││  Sleep/Refl. │   │  Benchmarks  │
└──────────────┘         └──────────────┘└──────────────┘└──────────────┘   └──────────────┘
                                                │
                                                ▼
                                         ┌──────────────┐
                                         │  6. AUDIT    │
                                         │  Milestones  │
                                         │  Horizons    │
                                         └──────────────┘
```

### 1. Habits (`checkmark.circle`)
* **Keystone Habit Boards**: Configurable habits with custom icons, color indices, and daily targets.
* **Metric Modes**: Binary check-off (`MetricType.binary`) vs quantitative cumulative amounts (`MetricType.quantitative`, e.g. miles, minutes, pages).
* **365-Day Heatmap Matrix**: GitHub-style historical completion grids with O(1) palette lookup and DST grace-window aggregation.
* **Streak Dynamics**: Real-time streak accumulation, longest streak caching, and flame badges (`🔥 1d`).

### 2. Today (`sun.max`)
* **Plan (Time-Blocking Timeline)**: Chronological vertical timeline rendering scheduled blocks with duration bubbles, free-gap duration labels, and an unscheduled backlog tray.
* **List (GTD Backlog Inventory)**: Categorized task inventory (Today / Upcoming / Anytime) with priorities (`High`, `Med`, `Low`), due dates, and rich interactive subtasks with progress rings.
* **Notion-Style Block Editor**: Slash-command (`/`) rich text workspace supporting headings, checklist blocks, dividers, quotes, and child tasks.

### 3. Time (`timer`)
* **Pomodoro Studio**: Dedicated focus sprints with configurable work/break intervals and smooth circular progress animations.
* **3D Spatial Soundscapes**: High-fidelity procedural audio engine (Rain & Thunder, Forest Birds, Deep Space White Noise).
* **Stopwatch & Countdown**: Flexible precision timers for deep work blocks.

### 4. Journal (`book.closed`)
* **Today's Log (Daylight Flow Routines)**: Morning and evening intentional rituals (Cold Shower, Magnesium, Sleep Skin Care, 10k Steps, Dinner).
* **Sleep Tracker**: Wake/bedtime log, duration tracking, quality metrics, and overnight sleep debt estimation.
* **Daily Reflection**: Structured prompt notes, clarity ratings (`Calm`, `Clear`, `Scattered`), and gratitude logging.
* **Analyse**: 30-day consistency indices, monthly heatmaps, and habit correlation matrices.

### 5. Life (`binoculars`)
* **Personal Life Model**: Multi-tier inference engine deriving States (energy, stress, focus, mood) from signals, detecting Life Events, segmenting Chapters, and constructing a personal Relationship Graph.
* **Bucket List & Benchmarks**: Multi-horizon dreams, milestone goals, and achievement badges (`🏆 Achieved` / `⏳ Target`).

### 6. Audit (`slider.horizontal.3`)
* **Strategic Life Audits**: Quarterly and annual review horizons for long-term calibration.
* **Milestone Checkpoints**: Quantitative progress bars and horizon goal adjustment.

---

## 🛰️ Private Alpha Telemetry & Creator Analytics Dossier

For private alpha distribution, PLUTO includes an invisible background telemetry pipeline that streams tester interactions directly to a real-time Creator Web Dossier:

* **Live Web Dashboard**: [https://mihirmaru22.github.io/Plut0/](https://mihirmaru22.github.io/Plut0/)
* **Direct PostgREST Supabase Ingestion**: Outbound HTTPS calls to `/rest/v1/alpha_testers`, `/rest/v1/alpha_events`, and `/rest/v1/alpha_state_snapshots`.
* **Invisible Background Pipeline**: Operates asynchronously in background threads (`Task.detached`) with zero UI blocking, zero popups, and zero user-facing performance overhead.
* **Local-First Disk Queue**: Queues events to sandboxed storage with automatic backpressure management (5,000 events / 25 MB disk cap) and offline exponential backoff retries.
* **Dynamic Tester Switching**: The creator dashboard automatically identifies unique testers and renders their live 6-pillar dossier in real time.

---

## 📁 Repository Structure

```
LOCA---Local-First-Habit-Tracker/
├── dashboard/                     # Creator Analytics Web Dossier (HTML5 / CSS / Vanilla JS)
├── docs/                          # GitHub Pages live deployment mirror
├── ios/                           # Native Swift / SwiftUI macOS + iOS Project
│   ├── LOCA/                     # Shared SwiftData Models & iOS Views
│   │   ├── Core/Models/          # HabitBoard, TodoItem, JournalNote, SleepEntry, UserProfile
│   │   └── Persistence/          # ModelContainerFactory, PlutoDataResetManager, DebugSeeder
│   ├── Loca_Mac/                 # Native macOS 14+ Sonoma NavigationSplitView Application
│   │   ├── Habits/               # 3 Layouts: Bento Rings, Horizon Strips, Progress Matrix
│   │   ├── Todo/                 # Day Planner Timeline + GTD List Backlog + Block Editor
│   │   ├── Time/                 # Pomodoro Timer View + Spatial Soundscape Studio
│   │   ├── Journal/              # Daylight Flow Routines + Sleep Card + Reflections
│   │   ├── Life/                 # Life Horizon Matrix & Bucket List Detail Column
│   │   ├── Audit/                # Strategic Life Audit Horizon Detail & Goal Editor
│   │   ├── Settings/             # Mac Settings Studio & Notification Router
│   │   ├── Platform/             # TelemetryEngine, TelemetryStorage, TelemetrySyncEngine
│   │   ├── Menus/                # LOCACommands (macOS Menu Bar Commands & Keyboard Shortcuts)
│   │   └── Loca_Mac.entitlements # Outbound network client permissions
│   ├── Docs/                     # Architectural Decision Records, Manifesto & Specifications
│   └── LOCA.xcodeproj           # Xcode Project Configuration
├── android/                       # Kotlin Multiplatform (KMP) Android Project
│   ├── androidApp/                # Jetpack Compose UI
│   └── shared/                    # Pure Kotlin domain logic & Room SQLite persistence
├── build_android.sh               # One-command Android APK build script
└── README.md
```

---

## 💻 macOS Application (Pluto for Mac)

### Requirements
* **macOS 14.0+ (Sonoma / Sequoia)**
* **Xcode 16.0+**

### Quick Start (Build & Run)
1. Open `ios/LOCA.xcodeproj` in Xcode 16+.
2. In the top scheme dropdown, select **`Loca_Mac`** and destination **`My Mac`**.
3. Press **`⌘ + R`** to compile and run **Pluto**.

### Distributing as a `.dmg`
1. In Xcode: Select target **`Loca_Mac`** ➔ **Product ➔ Archive**.
2. In the Organizer window: Click **Distribute App ➔ Direct Distribution / Copy App**.
3. Package the exported `Pluto.app` into `Pluto.dmg`:
   ```bash
   hdiutil create -volname "Pluto" -srcfolder "path/to/Pluto.app" -ov -format UDZO "Pluto.dmg"
   ```

---

## 📱 Android Application

### Quick Start (Build APK)
```bash
# Build Debug APK
./build_android.sh

# Build Release APK
./build_android.sh release
```

The compiled APK lands at:
```
android/androidApp/build/outputs/apk/debug/androidApp-debug.apk
```

Install to a connected Android device:
```bash
adb install -r android/androidApp/build/outputs/apk/debug/androidApp-debug.apk
```

### Tech Stack
* **Language**: Kotlin Multiplatform (KMP)
* **UI**: Jetpack Compose + Material 3
* **Persistence**: Room (SQLite)
* **Health Data**: Health Connect API
* **Min SDK**: Android 8.0 (API 26) / Target SDK: API 35

---

## 🏛️ Engineering Principles & Invariants

* **Local-First Ground Truth**: SwiftData (macOS/iOS) and Room (Android) serve as the authoritative single source of truth. The app functions 100% offline with zero network dependency.
* **Strict Concurrency**: Built with Swift 6 strict concurrency (`@MainActor`, `Sendable`, isolated background tasks).
* **Zero Unique Attributes for CloudKit**: Avoids `@Attribute(.unique)` to allow conflict-free multi-device peer synchronization.
* **Append-Only Completion Pattern**: Task and habit completions mutate timestamps (`completedAt = Date()` / `completedAt = nil`) without destructive deletes.
* **Soft Delete Architecture**: Entity deletions set `archivedAt = Date()`, preserving historical referential integrity.

---

## 📄 License

Copyright © 2024–2026 Mihir Maru. All rights reserved.
