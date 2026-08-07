# LOCA — Local-First Habit Tracker

A local-first personal habit tracker and life model with two fully independent platform implementations. All data lives on-device — no backend, no REST APIs, no network dependency for core functionality.

---

## Repository Structure

```
LOCA---Local-First-Habit-Tracker/
├── android/          # Kotlin Multiplatform (KMP) — self-contained Android project
├── ios/              # Swift / SwiftUI — self-contained iOS + macOS project
├── build_android.sh  # One-command APK build script
├── LICENSE
└── README.md
```

Each platform folder is fully independent. You can clone the repo and delete whichever platform you are not working on — the other will continue to work.

---

## Android

### Quick start — build an APK

```bash
# Debug APK (default)
./build_android.sh

# Release APK (unsigned)
./build_android.sh release

# Clean build
CLEAN=1 ./build_android.sh
```

The script auto-detects your Android SDK and writes `local.properties` if needed. The APK lands at:
```
android/androidApp/build/outputs/apk/debug/androidApp-debug.apk
```

Install on a connected device:
```bash
adb install -r android/androidApp/build/outputs/apk/debug/androidApp-debug.apk
```

### Requirements

| Requirement | Version |
|---|---|
| Java | 17+ |
| Android SDK | API 26+ (build target: API 35) |
| `ANDROID_HOME` | Set in env, or the script will search common install paths |

### Tech stack

| Layer | Technology |
|---|---|
| Language | Kotlin (Kotlin Multiplatform) |
| UI | Jetpack Compose + Material 3 |
| Persistence | Room (SQLite) |
| Serialization | kotlinx.serialization |
| Async | kotlinx.coroutines |
| Date/time | kotlinx.datetime |
| Health data | Health Connect |
| Min SDK | API 26 (Android 8.0) |

### Architecture

```
android/
├── androidApp/       # Android application module (Compose UI, Activities)
└── shared/
    ├── commonMain/   # Pure Kotlin — domain logic, derivation, models
    │   └── com/loca/
    │       ├── record/        # Fact record layer (append-only event log)
    │       ├── signal/        # Signal layer (validated, structured facts)
    │       └── derive/
    │           └── habits/    # HabitDeriver — streaks, completion rate, grid
    └── androidMain/  # Android-specific — Room entities, DAOs, database
        └── com/loca/
            ├── record/        # FactEntity, FactDao, RoomRecordStore
            ├── signal/        # SignalEntity, SignalDao, RoomSignalStore
            └── db/            # LOCADatabase (Room)
```

**Layer invariants:**
- `commonMain` has zero Android dependencies — pure Kotlin only
- `HabitDeriver` is a pure function: same signals + same `today` → same output, no side effects
- Facts are append-only; corrections are new facts, not mutations
- The signal layer re-derives state from scratch on replay

### Sprint status

| Sprint | Scope | Status |
|---|---|---|
| A1 | Project scaffold (KMP + Compose shell) | ✅ Done |
| A2 | Record layer (Fact types, RecordStore, InMemory impl) | ✅ Done |
| A3 | Signal layer (SignalPayload, SignalStore, SignalEngine) | ✅ Done |
| A4 | Room persistence (FactEntity/Dao, SignalEntity/Dao, LOCADatabase) | ✅ Done |
| A5 | Habits derivation (streaks, completion rate, 365-day grid) | ✅ Done |
| A6 | Journal derivation | 🔲 Next |
| A7 | Todo derivation | 🔲 Planned |
| A8 | Compose UI (per-pillar screens) | 🔲 Planned |
| A9 | Health Connect integration | 🔲 Planned |

---

## iOS

Open `ios/LOCA.xcodeproj` in Xcode 16+. See `ios/HOW_TO_RUN.md` for setup instructions including signing, App Groups, and CloudKit configuration.

### Tech stack

| Layer | Technology |
|---|---|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI |
| Data | SwiftData + NSPersistentCloudKitContainer |
| Sync | CloudKit (silent background sync) |
| Widgets | WidgetKit + AppIntentConfiguration |
| Shortcuts | App Intents |
| Platforms | iOS 17+, macOS 14+ |

### Feature status

**Habit Engine** — complete: create/edit/archive habits, binary and quantitative check-ins, streak analytics, 365-day heatmap, CloudKit sync, WidgetKit, Siri Shortcuts.

**Personal Life Model** — complete: hourly sensor inference (energy/stress/focus/mood), absence-aware epistemics, life event detection, chapter segmentation, trait inference, person extraction, relationship graph, pattern detection, narrative composition, Present tab.

### Documentation

All iOS documentation is in `ios/Docs/`:

| Document | Purpose |
|---|---|
| `Docs/LOCA-Founding-Manifesto.md` | Purpose, refusals, ontology |
| `Docs/THE-CENTRAL-QUESTION.md` | The one question the product is a bet on |
| `Docs/ENGINEERING_PRINCIPLES.md` | Architectural constraints |
| `Docs/LOCA-Cycle2-Claim-Taxonomy.md` | Authority classification for every stored field |
| `Docs/ADR/` | Architecture decision records |

---

## License

Copyright © 2024 Mihir Maru. All rights reserved.
