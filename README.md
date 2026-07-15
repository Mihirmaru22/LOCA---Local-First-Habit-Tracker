# LOCA — Local-First Habit Tracker

A high-performance, local-first multiplatform habit tracker for iOS 17+ and macOS 14+. Inspired by Ripples. Built with SwiftUI, SwiftData, and CloudKit — no custom backend, no REST APIs.

---

## Philosophy

**The device is the server.** All data lives locally in a SQLite store managed by SwiftData. CloudKit acts as a silent, asynchronous sync layer. The UI never awaits a network response to update.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (view-driven state, no thick MVVM) |
| Data | SwiftData + NSPersistentCloudKitContainer |
| Sync | CloudKit (silent background sync) |
| Widgets | WidgetKit + AppIntentConfiguration |
| Shortcuts | App Intents |
| Platforms | iOS 17+, macOS 14+ |
| Language | Swift 6 (strict concurrency) |
| Shared Store | App Group SQLite via ModelContainerFactory |

---

## Architecture Overview

```
LOCA/
├── App/                        # Entry point, CloudKit coordinator, widget refresh
├── Core/
│   ├── Models/                 # HabitBoard, LogEntry (@Model, CloudKit-safe)
│   ├── Persistence/            # ModelContainerFactory, DebugSeeder
│   ├── Analytics/              # HeatmapDataProvider, StreakCalculator
│   └── Extensions/             # ColorPalette, Animation springs, Date helpers
├── Features/
│   ├── Dashboard/              # HabitCardView, DashboardView
│   ├── HabitDetail/            # HabitDetailView, HeatmapView, AnalyticsCardsView, JournalTimelineView
│   ├── CheckIn/                # CheckInButton (Phase 6.1), CheckInSheet (Phase 6.2)
│   └── Navigation/             # RootNavigationView, HabitSidebarView
└── Docs/
    ├── ENGINEERING_PRINCIPLES.md
    └── ADRs/                   # ADR-001 through ADR-010+
```

### CloudKit Schema Constraints
All `@Model` types follow strict CloudKit compatibility rules:
- **No `@Attribute(.unique)`** — CloudKit forbids uniqueness constraints
- **All properties have defaults or are optional** — no non-optional properties without a default
- **All relationships are optional** — `[LogEntry]?`, `HabitBoard?`
- **Denormalized `boardID: UUID`** on `LogEntry` — enables safe `#Predicate` filtering (ADR-003)

---

## Data Model

### HabitBoard
Represents a single tracked habit (e.g., "Running", "Meditate").

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary identity |
| `name` | `String` | Display name |
| `metricType` | `Int` | `0` = binary, `1` = quantitative |
| `targetValue` | `Double?` | Daily goal (`1.0` for binary) |
| `unitLabel` | `String?` | e.g., `"mi"`, `"mins"` |
| `colorIndex` | `Int` | Index into `ColorPalette` |
| `currentStreak` | `Int` | Cached, updated on every check-in |
| `longestStreak` | `Int` | Cached, updated on every check-in |
| `logs` | `[LogEntry]?` | Cascade-delete relationship |

### LogEntry
A single check-in event.

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary identity |
| `timestamp` | `Date` | Exact time of check-in |
| `value` | `Double` | `1.0` for binary; measured amount for quantitative |
| `note` | `String?` | Optional journal entry |
| `boardID` | `UUID` | Denormalized — enables safe `#Predicate` (ADR-003) |
| `board` | `HabitBoard?` | Inverse relationship |

---

## Implementation Roadmap

| Phase | Scope | Status |
|---|---|---|
| **Phase 0** | Project scaffolding, engineering principles, ADRs, naming conventions | ✅ Complete |
| **Phase 1** | Data layer — `HabitBoard`, `LogEntry`, `ModelContainerFactory`, CloudKit compliance | ✅ Complete |
| **Phase 2** | Compute layer — `HeatmapDataProvider`, `StreakCalculator`, `LogSnapshot` | ✅ Complete |
| **Phase 3** | Navigation shell — `RootNavigationView`, `HabitSidebarView`, iOS/macOS split | ✅ Complete |
| **Phase 4** | Dashboard — `DashboardView`, `HabitCardView`, streak display | ✅ Complete |
| **Phase 5** | Heatmap & detail — `HabitDetailView` (List-based), `HeatmapView`, `AnalyticsCardsView`, `JournalTimelineView` | ✅ Complete |
| **Phase 6** | Check-in flow — `CheckInButton`, `CheckInSheet`, `WidgetRefreshCoordinator` | 🔄 In Progress |
| **Phase 7** | Habit management — create, edit, delete `HabitBoard` | ⏳ Planned |
| **Phase 8** | App Intents — `LogHabitIntent`, Siri/Shortcuts integration | ⏳ Planned |
| **Phase 9** | WidgetKit — interactive home screen widgets with heatmap and check-in button | ⏳ Planned |
| **Phase 10** | QA & polish — accessibility audit, performance profiling, final review | ⏳ Planned |

### Phase 6 Detail

| Subphase | Scope | Status |
|---|---|---|
| **6.1** | `Animation+Extensions`, `WidgetRefreshCoordinator`, `CheckInButton` (binary path), `HabitDetailView` integration | ✅ Pushed — awaiting runtime validation |
| **6.2** | `CheckInSheet` (quantitative value + note entry), `CheckInButton` quantitative branch | ⏳ Pending 6.1 validation |

---

## Key Architectural Decisions

| ADR | Decision |
|---|---|
| ADR-001 | Append-only `LogEntry` at check-in path; user-initiated delete exempted |
| ADR-002 | `ColorPalette` indexed array instead of per-board hex strings (CloudKit safe) |
| ADR-003 | Denormalized `boardID` on `LogEntry` for `#Predicate` safety on iOS 17 |
| ADR-004 | App Group shared `ModelContainer`; widget/main app target membership rules |
| ADR-009 | `#if LOCAL_DEVELOPMENT` compile-time switch for personal team builds |
| ADR-010 | Analytics window (30 days) independent from heatmap window (365 days) |

Full ADR index in `Docs/ADRs/`.

---

## Engineering Standards

All implementation follows `Docs/ENGINEERING_PRINCIPLES.md`. Key rules:

- **One-build → one-root-cause-fix**: each compiler error gets its own isolated fix
- **No `@Attribute(.unique)`**: CloudKit hard constraint
- **No unbounded `@Query` on `LogEntry`**: all predicates must include a date-range bound (§5.2)
- **`#Predicate` uses `boardID`, not `board?.id`**: iOS 17 SwiftData limitation (ADR-003)
- **SF Pro Rounded** for all numeric values in analytics (§3)
- **`Animation.rippleConfirm`** for all check-in press interactions (§7.1)
- **`UIImpactFeedbackGenerator(style: .rigid)`** on log confirmation, gated on `#if canImport(UIKit)` (§7.2)
- **`accessibilityReduceMotion`** respected at every animation site (§6.3)
- **Preview helper pattern**: all `#Preview` fixture setup in `@MainActor` helper functions

---

## Build Configuration

### Standard Build
Requires an active Apple Developer account with CloudKit and App Group entitlements configured.

### Local Development Build
Set the `LOCAL_DEVELOPMENT` Swift compiler flag to bypass CloudKit and App Group entitlements for personal team / simulator builds (ADR-009):

```
Build Settings → Swift Compiler — Custom Flags → Active Compilation Conditions → LOCAL_DEVELOPMENT
```

The `ModelContainerFactory` switches to an in-memory or App Group-less container automatically when this flag is active.

---

## Project Structure Rules

- All new Swift files must be registered in `LOCA.xcodeproj/project.pbxproj` before commit
- Run the **Xcode Project Verification Checklist** after every pbxproj modification
- Widget Extension target membership: `Core/Extensions/*`, `Core/Models/*`, `Core/Analytics/*`, `Core/Persistence/ModelContainerFactory.swift` only — never `Features/*` or `App/*`

---

## Local Development

```bash
git clone https://github.com/Mihirmaru22/LOCA---Local-First-Habit-Tracker.git
cd LOCA---Local-First-Habit-Tracker
open LOCA.xcodeproj
```

Select the `LOCA` scheme, set `LOCAL_DEVELOPMENT` flag if needed, build and run on simulator or device.

The `DebugSeeder` populates two boards ("Meditate" binary, "Running" quantitative) with 90 days of sample data on first launch in debug builds.
