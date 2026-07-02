# LOCA — Local-First Habit Tracker

A high-performance, multiplatform habit tracking app for iOS 17+ and macOS 14+.  
Built with SwiftData, CloudKit, WidgetKit, and App Intents. No custom backend. No REST APIs.

---

## What Is LOCA?

LOCA is a local-first habit tracker where the device is the primary server. All data lives in a shared SwiftData store on-device, syncing silently and asynchronously via CloudKit. The UI never waits for a network response.

The core visual interface is a calendar heatmap — a grid of the last 100–365 days rendered as small coloured squares whose intensity encodes daily completion relative to each habit's target.

---

## Platform Targets

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 17.0+          |
| macOS    | 14.0+          |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Data | SwiftData (`NSPersistentCloudKitContainer`) |
| Sync | CloudKit (silent, asynchronous, local-first) |
| Widgets | WidgetKit (`AppIntentConfiguration`) |
| Siri / Shortcuts | App Intents |
| Concurrency | Swift 6 strict mode (`async/await`, actors) |
| Persistence sharing | App Group (`group.com.yourdomain.ripples`) |

---

## Architecture

### Local-First Paradigm
The device SQLite store is the source of truth. CloudKit is a background sync layer — not a primary data source. All writes complete instantly and locally; sync happens asynchronously without blocking the UI.

### Key Architectural Decisions

| ADR | Decision | Rationale |
|-----|---------|-----------|
| [ADR-001](Docs/ADR/ADR-001-soft-delete.md) | Soft delete via `archivedAt: Date?` | CloudKit does not guarantee deletion order; cascade deletes produce orphaned records |
| [ADR-002](Docs/ADR/ADR-002-colorindex.md) | `colorIndex: Int` over `colorHex: String` | Eliminates hex parse cost in the heatmap's 365-cell render path |
| [ADR-003](Docs/ADR/ADR-003-boardid-denorm.md) | `boardID: UUID` denormalized on `LogEntry` | Works around SwiftData iOS 17 relationship keypath predicate bug |
| [ADR-004](Docs/ADR/ADR-004-target-membership.md) | Xcode target membership over local SPM package | Avoids `@Model` schema visibility issues and Preview resolution degradation |
| [ADR-005](Docs/ADR/ADR-005-actor-isolated-provider.md) | Actor-isolated `HeatmapDataProvider` | Keeps 365-day aggregation off the main thread |
| [ADR-006](Docs/ADR/ADR-006-unified-navigationsplitview.md) | Single `NavigationSplitView` for all platforms | `NavigationSplitView`'s adaptive collapsing handles iPhone/iPad/Mac in one code path — no parallel `NavigationStack` tree |
| [ADR-007](Docs/ADR/ADR-007-selection-state-id-not-reference.md) | Selection state holds `HabitBoard.id`, not a live reference | Avoids stale-reference risk from CloudKit merges or archival while selected |

### Shared Target Files
Files in `LOCA/Core/` (Models, Persistence, Extensions) and `LOCA/Intents/` are added to **both** the Main App target and the Widget Extension target via Xcode target membership — one file on disk, two compile targets.

---

## Project Structure

```
LOCA/
├── App/                                # Phase 0 ✅
│   └── LOCAApp.swift                   # @main entry point, single ModelContainerFactory call site
│   └── CloudKitSyncCoordinator.swift   # NSPersistentCloudKitContainerEvent observer
├── Core/                              # ⊕ Shared: Main App + Widget Extension
│   ├── Models/
│   │   ├── HabitBoard.swift           # @Model — primary habit entity
│   │   ├── LogEntry.swift             # @Model — append-only log record
│   │   └── VersionedSchema.swift      # SchemaV1 + MigrationPlan
│   ├── Persistence/
│   │   ├── ModelContainerFactory.swift # App Group + CloudKit container factory
│   │   └── PersistenceError.swift     # Domain error type
│   └── Extensions/
│       ├── Date+Calendar.swift        # DST-aware day boundary helpers
│       ├── ColorPalette.swift         # Indexed colour system (ADR-002)
│       └── Double+Clamp.swift         # Heatmap intensity clamping
├── Analytics/                         # ⊕ Shared — Phase 2 ✅
│   ├── StreakCalculator.swift
│   └── HeatmapDataProvider.swift
├── Features/                          # Main App only
│   ├── Navigation/                    # Phase 3 ✅
│   │   ├── RootNavigationView.swift
│   │   └── HabitSidebarView.swift
│   ├── HabitDetail/                    # Phase 3 ✅ (placeholder only)
│   │   └── HabitDetailView.swift
│   ├── Dashboard/
│   ├── CheckIn/
│   └── HabitCreation/
├── Haptics/                           # Main App only
│   └── HapticEngine.swift
└── Intents/                           # ⊕ Shared: Main App + Widget Extension — Phase 8
    ├── HabitBoardEntity.swift
    ├── LogHabitIntent.swift
    └── AppShortcutsProvider.swift

LOCAWidget/                            # Widget Extension Target — Phase 9
Docs/
├── ENGINEERING_PRINCIPLES.md
├── ADR/
└── Reports/
```

---

## Implementation Roadmap

| Phase | Name | Status |
|-------|------|--------|
| 0 | Project Scaffolding | ✅ Complete — reviewed, H1 fixed |
| **1** | **Data Layer** | **✅ Complete — reviewed, bugs fixed** |
| **2** | **Compute Layer** | **✅ Complete — reviewed, all High findings fixed** |
| **3** | **Navigation Shell** | **✅ Complete — reviewed, all High findings + M1 fixed** |
| **4** | **Dashboard** | **✅ Complete — reviewed, M1 + M2 fixed** |
| 5 | Heatmap & Detail | ⏳ Ready to begin |
| 6 | Check-In Flow | ⏳ Pending |
| 7 | Habit Management | ⏳ Pending |
| 8 | App Intents | ⏳ Pending |
| 9 | WidgetKit | ⏳ Pending |
| 10 | QA & Polish | ⏳ Pending |

**Phase 0 executed after Phase 3's approval, before Phase 4**, exactly as scheduled:
Phases 1–3 were deliberately built and reviewed entirely against
`ModelContainerFactory.makeInMemoryContainer()` via SwiftUI Previews, deferring
Xcode-project and entitlement ceremony until it was actually load-bearing. See
[`Docs/Phase0-ProjectScaffolding.md`](Docs/Phase0-ProjectScaffolding.md) for the
full scope and rationale, and
[`Docs/Reports/Phase0-ProjectScaffolding.md`](Docs/Reports/Phase0-ProjectScaffolding.md)
for the completed phase report.

## Phase 0 Summary

Phase 0 delivered runtime integration: `LOCAApp.swift` (the `@main` entry point, single `ModelContainerFactory.makeSharedContainer()` call site), `CloudKitSyncCoordinator.swift` (observes `NSPersistentCloudKitContainerEvent`, flags active boards for streak recalculation after CloudKit imports), App Group/CloudKit entitlements, and migration of every internal identifier from the project's original working-title placeholders to LOCA's naming convention. A review focused on app lifecycle, actor isolation, and Apple platform conventions found one High finding — a per-window `.task` binding an app-scoped coordinator, which macOS's default "New Window" command would have duplicated — resolved with an idempotency guard.

See the full report: [`Docs/Reports/Phase0-ProjectScaffolding.md`](Docs/Reports/Phase0-ProjectScaffolding.md)

---

## Phase 1 Summary

Phase 1 delivered the complete SwiftData schema, persistence factory, and shared utility extensions. It was reviewed by an Apple Frameworks-level critique session that identified 14 findings across 4 severity levels. All Critical (3) and High (5) findings were resolved before merge.

See the full report: [`Docs/Reports/Phase1-DataLayer.md`](Docs/Reports/Phase1-DataLayer.md)

## Phase 2 Summary

Phase 2 delivered the pure compute layer — `StreakCalculator` and `HeatmapDataProvider` — with zero dependency on SwiftUI, WidgetKit, App Intents, or `ModelContext`. A second Apple Frameworks-level review identified 14 findings across 3 severity levels (zero Critical). All 6 High findings were resolved, including a floating-point epsilon bug in goal-completion checks, a future-dated-entry streak-suppression bug, and a performance fix splitting the aggregation kernel so the heatmap no longer pays for DST grace-window computation it never uses.

See the full report: [`Docs/Reports/Phase2-ComputeLayer.md`](Docs/Reports/Phase2-ComputeLayer.md)

## Phase 3 Summary

Phase 3 delivered the navigation shell — a single `NavigationSplitView` adapting across iPhone, iPad, and Mac, a selectable sidebar of active habits, and a placeholder detail column for Phase 5 to build inside. A Correctness/Engineering/Experience review identified 10 findings (zero Critical). All 3 High findings were resolved — missing native sidebar styling, a non-idiomatic empty-state pattern embedded inside a selectable list, and missing auto-selection on iPad/Mac split-view layouts — plus one Medium finding (contradictory empty-state copy on first run) folded into the same fix pass since it was cheap and Phase-3-owned.

See the full report: [`Docs/Reports/Phase3-NavigationShell.md`](Docs/Reports/Phase3-NavigationShell.md)

## Phase 4 Summary

Phase 4 delivered the Dashboard: `DashboardView`/`HabitCardView` replace `HabitSidebarView`/`HabitSidebarRow` as `NavigationSplitView`'s sidebar content (ADR-008), displaying per-habit streak, best-streak, today's progress (via a native `Gauge`), and daily target — all from cached values or a simple filter over already-loaded logs, with zero new `StreakCalculator`/`HeatmapDataProvider` calls. Review found two Medium findings, both fixed: a redundant double computation of today's total per render, and an unclamped progress value that could go out of `Gauge`'s valid range on corrupted data. `HabitSidebarView.swift` remains in the repo, now unused, pending an explicit decision to remove it.

---

## Setup

### Prerequisites
- Xcode 16 or later
- Apple Developer account with iCloud capability
- App Group identifier configured on both targets

### Configuration
Before building, update the following in `ModelContainerFactory.swift`:
```swift
static let appGroupIdentifier = "group.com.yourdomain.ripples"  // ← your App Group
```

And in your CloudKit entitlement, confirm the container identifier matches `cloudKitDatabase: .automatic` in `ModelContainerFactory.makeSharedContainer()`.

### Build Targets
- **LOCA** — Main App (iOS + macOS)
- **LOCAWidget** — Widget Extension

---

## Engineering Standards

All code is governed by [`Docs/ENGINEERING_PRINCIPLES.md`](Docs/ENGINEERING_PRINCIPLES.md), which covers Swift 6 style, naming conventions, concurrency rules, performance budgets, accessibility requirements, animation standards, testing strategy, documentation expectations, and the PR review checklist.

Key hard limits:
- Heatmap render (365 cells): < 16ms
- App launch to first frame: < 400ms
- Widget timeline generation: < 200ms
- Main thread synchronous work: < 1ms per call

---

## Performance Budgets

| Metric | Budget |
|--------|--------|
| App launch → first frame | < 400ms |
| Heatmap grid render (365 cells) | < 16ms |
| Single `@Query` result set | ≤ 10,000 records |
| Main thread synchronous work | < 1ms |
| Widget timeline generation | < 200ms |
| Peak RSS (heatmap + chart) | < 100MB |

---

## Licence

Copyright 2025 Mihirmaru22

Licensed under the [Apache License, Version 2.0](LICENSE).
