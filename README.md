# 🪐 PLUTO (formerly LOCA) — Local-First Habit Tracker & Life OS

> **A private, local-first personal habit tracker, day planner, and life operating system built natively for macOS, iOS, and Android.**

All personal data lives strictly on-device with zero required backend, zero cloud lock-in, and offline-first speed. In V3.5, PLUTO introduces an **invisible, privacy-first Alpha Telemetry engine** paired with a real-time **Creator Analytics Web Dossier**.

---

## 🌟 The 6 Core Pillars Architecture

PLUTO is structured around 6 cohesive, deeply integrated pillars:

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

1. **Habits** (`checkmark.circle`): Keystone habit boards, interactive check rings, flame streaks, customizable metrics (binary check-off vs quantitative amounts), and 365-day GitHub-style heatmaps.
2. **Today** (`sun.max`): 
   - **Plan**: Chronological time-blocked day-planner timeline with free-gap indicators and unscheduled tray.
   - **List**: GTD-style task backlog inventory (Today / Upcoming / Anytime) with priorities (`High`, `Med`, `Low`) and interactive subtasks.
3. **Time** (`timer`):
   - **Pomodoro Studio**: Configurable work/break focus sprints with visual progress rings.
   - **3D Spatial Soundscapes**: High-fidelity background audio (Rain & Thunder, Forest Birds, Deep Space White Noise).
   - **Stopwatch & Countdown**: Flexible timers for deep work blocks.
4. **Journal** (`book.closed`):
   - **Today's Log**: Daylight Flow Routines (Cold Shower, Magnesium, Sleep Skin Care, 10k Steps, Dinner).
   - **Sleep Tracker**: Wake/bedtime log, duration tracking, and quality ratings.
   - **Daily Reflection**: Structured prompt notes and clarity levels.
   - **Analyse**: 30-day consistency index and habit correlation matrices.
5. **Life** (`binoculars`): Multi-year life horizon benchmarks, milestone checkpoints, and interactive bucket list items with achievement badges.
6. **Audit** (`slider.horizontal.3`): Quarterly and annual strategic life audits with progress bars and horizon goal calibration.

---

## 🛰️ Private Alpha Telemetry & Creator Analytics (V3.5)

For private alpha testing, PLUTO includes a non-intrusive background telemetry pipeline that streams tester interactions directly to a live web analytics dashboard:

* **Live Web Dashboard**: [https://mihirmaru22.github.io/Plut0/](https://mihirmaru22.github.io/Plut0/)
* **Direct PostgREST Ingestion**: Outbound HTTPS requests to Supabase tables (`alpha_testers`, `alpha_events`, `alpha_state_snapshots`) with zero intermediary edge latency.
* **Invisible Engine**: Operates 100% silently in background threads (`Task.detached`) with zero UI impact, zero popups, and zero blocking of user flows.
* **Local-First Disk Queue**: Queues events to sandboxed storage with automatic backpressure management (5,000 events / 25 MB cap) and offline retry backoff.
* **Dynamic Tester Switcher**: The creator dashboard automatically recognizes new testers and streams their real-time 6-pillar dossier.

---

## 📁 Repository Structure

```
LOCA---Local-First-Habit-Tracker/
├── dashboard/               # Creator Analytics Web Dashboard (HTML5 / Vanilla CSS / JS)
├── docs/                    # GitHub Pages live build mirror (https://mihirmaru22.github.io/Plut0/)
├── ios/                     # Native Swift / SwiftUI Xcode Project (macOS + iOS)
│   ├── LOCA/               # Shared SwiftData Models & iOS Views
│   │   ├── Core/Models/    # HabitBoard, TodoItem, JournalNote, SleepEntry, UserProfile
│   │   └── Persistence/    # ModelContainerFactory, PlutoDataResetManager, DebugSeeder
│   ├── Loca_Mac/           # Native macOS 14+ Sonoma NavigationSplitView Application
│   │   ├── Habits/         # 3 Layout Variants (Bento Rings, Horizon Strips, Progress Matrix)
│   │   ├── Todo/           # Day Planner Timeline + GTD List Backlog + Block Editor
│   │   ├── Journal/        # Daylight Flow Routines + Sleep Card + Reflections
│   │   ├── Platform/       # PlutoTelemetryEngine, PlutoTelemetryStorage, PlutoTelemetrySyncEngine
│   │   └── Loca_Mac.entitlements # Outbound network client permissions
│   └── LOCA.xcodeproj     # Xcode Project Configuration
├── android/                 # Kotlin Multiplatform (KMP) Android Project
│   ├── androidApp/          # Jetpack Compose UI
│   └── shared/              # Pure Kotlin domain logic & Room SQLite persistence
└── README.md
```

---

## 💻 macOS Application (Pluto for Mac)

### Requirements
* **macOS 14.0+ (Sonoma / Sequoia)**
* **Xcode 16.0+**

### Quick Start (Build & Run)
1. Open `ios/LOCA.xcodeproj` in Xcode.
2. In the scheme dropdown (top toolbar), select **`Loca_Mac`** and destination **`My Mac`**.
3. Press **`⌘ + R`** to compile and launch **Pluto**.

### Distributing as a `.dmg`
1. In Xcode: Select target **`Loca_Mac`** ➔ **Product ➔ Archive**.
2. In the Organizer window: Click **Distribute App ➔ Direct Distribution / Copy App**.
3. Package the exported `Pluto.app` into `Pluto.dmg` via Disk Utility or the terminal:
   ```bash
   hdiutil create -volname "Pluto" -srcfolder "path/to/Pluto.app" -ov -format UDZO "Pluto.dmg"
   ```

---

## 📱 Android Application

### Quick Start (Build APK)
```bash
# Debug APK (default)
./build_android.sh

# Release APK
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

## 📋 Engineering Sprint Status

| Sprint | Feature Scope | Platform | Status |
|---|---|---|---|
| **S1** | **6-Pillar Desktop App** (Habits, Today Plan/List, Time Focus, Journal Flow, Life, Audit) | macOS / iOS | ✅ Done |
| **S2** | **Invisible Alpha Telemetry Engine** & Local Disk Queue | macOS | ✅ Done |
| **S3** | **Live Creator Analytics Dossier** & GitHub Pages Deployment | Web / Supabase | ✅ Done |
| **S4** | **Sandbox Network Entitlements** (`Loca_Mac.entitlements`) & PostgREST FK Integrity | macOS | ✅ Done |
| **S5** | **App Branding & Name Transition to Pluto** | macOS / System | ✅ Done |
| **S6** | **DMG Packaging & Alpha Distribution** (`Pluto.dmg`) | macOS | ✅ Done |

---

## 🔒 Privacy & Architecture Principles

* **Local-First Ground Truth**: SwiftData (macOS/iOS) and Room (Android) serve as the authoritative single source of truth. The app functions 100% offline with zero network dependency.
* **Invisible Telemetry Isolation**: Telemetry engines are isolated to diagnostic layers. If network is unreachable, events buffer safely on disk without altering or delaying user workflows.
* **Zero Unique Identifiers Synced to CloudKit**: Unique constraints are avoided to support frictionless, multi-device peer synchronization.

---

## 📄 License

Copyright © 2024–2026 Mihir Maru. All rights reserved.
