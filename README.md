# LOCA — Local-First Habit Tracker

A high-performance, local-first habit tracker for iOS 17+ and macOS 14+. Built with SwiftUI, SwiftData, and CloudKit — no custom backend, no REST APIs, no network dependency for core functionality.

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
| Shared Store | App Group SQLite via `ModelContainerFactory` |

---

## Architecture Overview

```
LOCA/
├── App/
│   ├── LOCAApp.swift                  # Entry point, container init, CloudKit coordinator
│   ├── CloudKitSyncCoordinator.swift  # NSPersistentCloudKitContainerEvent observer
│   └── WidgetRefreshCoordinator.swift # WidgetKit timeline invalidation
├── Core/
│   ├── Models/
│   │   ├── HabitBoard.swift           # Primary habit entity (@Model, CloudKit-safe)
│   │   ├── LogEntry.swift             # Append-only check-in record (@Model)
│   │   └── VersionedSchema.swift      # RippleSchemaV1 + RippleMigrationPlan
│   ├── Persistence/
│   │   ├── ModelContainerFactory.swift # Production / local dev / in-memory containers
│   │   ├── PersistenceError.swift     # Typed error domain
│   │   └── DebugSeeder.swift          # Sample data (DEBUG only)
│   ├── Analytics/
│   │   ├── HeatmapDataProvider.swift  # Off-thread heatmap aggregation
│   │   └── StreakCalculator.swift     # Full historical streak recalculation
│   ├── DesignSystem/
│   │   ├── DS.swift                   # Token namespace (spacing, radius, motion)
│   │   ├── DS+Color.swift             # Semantic color tokens
│   │   ├── DS+Typography.swift        # Font scale
│   │   └── DSComponents.swift         # LOCACard, SectionHeader, ValueText
│   └── Extensions/
│       ├── ColorPalette.swift         # Indexed color array (ADR-002)
│       ├── View+PlatformAdaptations.swift # Cross-platform shims
│       ├── Date+Calendar.swift
│       ├── Animation+Extensions.swift
│       └── Double+Clamp.swift
├── Features/
│   ├── Dashboard/
│   │   ├── TodayView.swift            # Root view, NavigationStack host
│   │   ├── HabitListView.swift        # Layout router (list / grid / timeline)
│   │   ├── HabitListLayoutView.swift  # Zone-based list (To Do / In Progress / Done)
│   │   ├── HabitGridLayoutView.swift  # 2-col grid with 8-week mini heatmap
│   │   ├── HabitTimelineLayoutView.swift # Chronological timeline
│   │   ├── HabitCardView.swift        # Single habit row
│   │   ├── HabitListRow.swift
│   │   ├── ArcProgressView.swift
│   │   └── SettingsMenuView.swift     # Layout picker, app settings
│   ├── HabitDetail/
│   │   ├── HabitDetailView.swift      # 4-tab detail: summary / check-ins / journal / analytics
│   │   ├── HabitCheckInsView.swift    # Check-in history (grouped, swipe actions)
│   │   ├── HabitJournalView.swift     # Journal surface (wraps JournalTimelineView)
│   │   ├── JournalTimelineView.swift  # Day-grouped entry list
│   │   ├── AddCheckInSheetView.swift  # New check-in modal
│   │   ├── EditCheckInSheetView.swift # Edit existing check-in modal
│   │   ├── HabitAnalyticsView.swift   # Full analytics tab (Canvas charts + heatmap hero)
│   │   ├── HeatmapView.swift          # Scrollable 365-day grid (used by HabitAnalyticsView)
│   │   ├── TimelineChartView.swift    # Canvas-based 7/30/90/All chart
│   │   ├── StreaksChartView.swift     # 12-month bar timeline
│   │   ├── YearComparisonChartView.swift
│   │   ├── ConsistencyChartView.swift
│   │   └── WeekdaysChartView.swift
│   └── HabitManagement/
│       ├── HabitFormView.swift        # Create / edit habit sheet
│       ├── HabitBoardDraft.swift      # Form staging state
│       └── UnitOption.swift           # Picker-backed unit catalogue
├── Intents/
│   ├── LogHabitIntent.swift
│   ├── HabitBoardEntity.swift
│   └── LOCAShortcuts.swift
└── LOCAWidget/ (Extension target)
    └── ...
```

---

## Data Model

### HabitBoard
Represents a single tracked habit (e.g. "Running", "Meditate"). Owns all configuration and log history.

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Stable identity — join key for `LogEntry.boardID` |
| `name` | `String` | Display name |
| `metricType` | `Int` | `0` = binary, `1` = quantitative (CloudKit-safe raw value) |
| `targetValue` | `Double?` | Daily goal; `nil` for binary (effective default `1.0`) |
| `unitLabel` | `String?` | e.g. `"mi"`, `"mins"`, `"L"` |
| `colorIndex` | `Int` | Index into `ColorPalette` (ADR-002) |
| `emoji` | `String?` | Optional card prefix emoji (e.g. `"🏃"`) |
| `useColorBackground` | `Bool` | Tinted card background toggle |
| `currentStreak` | `Int` | Cached; updated incrementally on every check-in |
| `longestStreak` | `Int` | Cached; updated when `currentStreak` exceeds it |
| `lastCheckedDate` | `Date?` | Day boundary for incremental streak logic |
| `needsStreakRecalculation` | `Bool` | CloudKit merge invalidation flag |
| `archivedAt` | `Date?` | Soft-delete marker; `nil` = active |
| `createdAt` | `Date` | Creation timestamp |
| `logs` | `[LogEntry]?` | Owned relationship (`.nullify` delete rule) |

### LogEntry
A single check-in event. Append-only at the check-in path; user-initiated delete is permitted.

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Stable identity |
| `timestamp` | `Date` | Exact datetime of the check-in |
| `value` | `Double` | `1.0` for binary; measured amount for quantitative |
| `note` | `String?` | Optional journal text |
| `boardID` | `UUID` | Denormalized copy of `board.id` — safe `#Predicate` target (ADR-003) |
| `board` | `HabitBoard?` | Optional to tolerate transient CloudKit orphan states |

### Schema & Migrations
- **Schema:** `RippleSchemaV1` (`HabitBoard` + `LogEntry`)
- **Migration plan:** `RippleMigrationPlan` (no stages in v1 — cleanly established)
- **Versioning:** Add `RippleSchemaV2` + a `MigrationStage` for any future property additions

---

## Persistence

| Concern | Implementation |
|---|---|
| Storage | App Group SQLite via `ModelContainerFactory.makeSharedContainer()` |
| CloudKit | `.private("iCloud.com.mihirmaru.loca")` explicit binding; `.none` in `LOCAL_DEVELOPMENT` builds |
| Soft delete | `HabitBoard.archive(in:)` — sets `archivedAt`, never calls `modelContext.delete()` |
| Hard delete | `LogEntry` only — explicit user action in check-in history and journal |
| Save errors | Every site: `do/try/catch + modelContext.rollback()` + non-blocking alert |
| Streak cache | Incremental `updateStreak()` on insert; `StreakCalculator` for full recalculation |
| Widget sharing | Widget Extension reads same SQLite via same App Group identifier |
| Seed data | `DebugSeeder.seedIfNeeded()` — 2 boards × 60 days, DEBUG builds only, no-op if data exists |

---

## Feature Status

| Feature | Status |
|---|---|
| Habit creation (name, type, goal, unit, color, emoji) | ✅ Complete |
| Habit editing | ✅ Complete |
| Habit soft-delete (archive) | ✅ Complete |
| Dashboard — list layout (zone-based) | ✅ Complete |
| Dashboard — grid layout (8-week heatmap cards) | ✅ Complete |
| Dashboard — timeline layout | ✅ Complete |
| Layout switching (list / grid / timeline) | ✅ Complete |
| Binary check-in (tap to log) | ✅ Complete |
| Quantitative check-in (sheet with amount) | ✅ Complete |
| Detail view — summary tab (heatmap card + streak + consistency + month) | ✅ Complete |
| Detail view — check-in history tab | ✅ Complete |
| Detail view — journal tab | ✅ Complete |
| Detail view — full analytics tab (Canvas charts + 365-day heatmap) | ✅ Complete |
| Add check-in (date, time, amount, notes) | ✅ Complete |
| Edit check-in (pre-filled, in-place mutation) | ✅ Complete |
| Delete check-in | ✅ Complete |
| Duplicate check-in | ✅ Complete |
| Quick log (inline amount input in history) | ✅ Complete |
| Streak calculation (current + longest, cached) | ✅ Complete |
| Consistency metric (days completed / days elapsed) | ✅ Complete |
| Current month total + weekly bar chart | ✅ Complete |
| 52-week heatmap (detail view) | ✅ Complete |
| Canvas analytics charts (timeline, streaks, year, consistency, weekdays) | ✅ Complete (tab 3) |
| Journal timeline (day-grouped, swipe-to-delete) | ✅ Complete |
| CloudKit sync | ✅ Complete |
| Widget (WidgetKit + AppIntentConfiguration) | ✅ Complete |
| App Intents / Siri Shortcuts | ✅ Complete |
| Cross-platform (iOS + macOS) via platform shims | ✅ Complete |

---

## Key Architectural Decisions

| ADR | Decision |
|---|---|
| ADR-001 | `LogEntry` append-only at check-in path; user-initiated delete is a separate, permitted action |
| ADR-002 | `ColorPalette` indexed array instead of per-board hex strings — O(1) `Color` construction, CloudKit safe |
| ADR-003 | Denormalized `boardID: UUID` on `LogEntry` — `#Predicate` on `board?.id` silently fails on iOS 17 |
| ADR-004 | Shared App Group SQLite; widget and main app address the same file via matching identifier |
| ADR-005 | Snapshot pattern for analytics computation — prevents in-flight mutation during aggregation |
| ADR-009 | `#if LOCAL_DEVELOPMENT` compile-time switch — personal team builds, no entitlements required |

---

## Known Compiler Patterns (Bug Catalogue)

Patterns encountered and resolved during development — documented to prevent recurrence:

| # | Pattern | Fix |
|---|---|---|
| 1 | `some View` in protocol | Use `associatedtype Body: View` |
| 2 | `let` bindings in `@ViewBuilder` | Use computed properties |
| 3 | `.onTapGesture` + `NavigationLink` | Gesture swallows tap — use `.buttonStyle(.borderless)` |
| 5 | `accessibilityHint(... : nil)` | Conditionally omit the modifier |
| 6 | `Color(.systemBackground)` | `#if canImport(UIKit)` branch |
| 7 | `@Query` key path | Explicit root type: `\HabitBoard.createdAt` |
| 8 | `.navigationBarTitleDisplayMode` | Use `inlineNavigationTitleDisplay()` shim |
| 9 | Canvas closure | `{ context, size in ... }` (both params required) |
| 10 | `stride` in `ForEach` | `Array(stride(from:to:by:))` |
| 13 | `@Query` makes synthesized init private | Add explicit `init() {}` |
| 14 | Double `NavigationStack` | One root only — child views must not embed their own |
| 15 | Bare `import UIKit` | `#if canImport(UIKit)` |
| 16 | `keyboardType(.decimalPad)` raw | Use `decimalKeyboard()` shim |
| 17 | `.tabViewStyle(.page(...))` raw | Use `pagedTabView()` shim |
| 19 | `try? voidThrowingCall()` | `do/catch + rollback()` |
| 20 | `Double.random()` | No zero-arg overload — always `Double.random(in: 0...1)` |
| — | Nested ternary in `String(format:)` | Exceeds Swift type-checker complexity — extract to `let` |
| — | Large `body` with many closures | Break into private `@ViewBuilder` computed properties |
| — | `.navigationBarTrailing` on macOS | Use `.confirmationAction` (cross-platform) |

---

## Build Configuration

### Requirements
- Xcode 15.3+
- iOS 17+ / macOS 14+ SDK
- Apple Developer account (paid) for CloudKit + App Group entitlements

### Local Development (Personal Team / Simulator)
Add `LOCAL_DEVELOPMENT` to Active Compilation Conditions:

```
Build Settings → Swift Compiler — Custom Flags → Active Compilation Conditions
→ Add: LOCAL_DEVELOPMENT
```

This bypasses App Group and CloudKit entitlement requirements. Data persists to the app's own sandboxed Application Support directory across launches.

### Clone & Run

```bash
git clone https://github.com/Mihirmaru22/LOCA---Local-First-Habit-Tracker.git
cd LOCA---Local-First-Habit-Tracker
open LOCA.xcodeproj
```

Select the `LOCA` scheme → set `LOCAL_DEVELOPMENT` if on a personal team → build and run.

`DebugSeeder` seeds two sample habits ("Meditate" binary, "Running" quantitative) with 60 days of log history on first launch in DEBUG builds. It is a no-op if any active board already exists, and entirely absent from Release builds.

---

## Platform Shims (`View+PlatformAdaptations.swift`)

| Shim | iOS | macOS |
|---|---|---|
| `.inlineNavigationTitleDisplay()` | `.navigationBarTitleDisplayMode(.inline)` | no-op |
| `.largeNavigationTitleDisplay()` | `.navigationBarTitleDisplayMode(.large)` | no-op |
| `.decimalKeyboard()` | `.keyboardType(.decimalPad)` | no-op |
| `.groupedInsetList()` | `.listStyle(.insetGrouped)` | `.listStyle(.inset)` |
| `.pagedTabView()` | `.tabViewStyle(.page(indexDisplayMode: .never))` | no-op |

---

## Testing

### Manual Test Checklist
- [ ] Create binary and quantitative habits with different units, colors, and emoji
- [ ] Log check-ins via grid card button (binary = direct, quantitative = sheet)
- [ ] Log via `+` button on detail view
- [ ] Edit a check-in (swipe → Edit in history tab)
- [ ] Delete a check-in (swipe → Delete)
- [ ] Duplicate a check-in (swipe → Duplicate)
- [ ] Switch between list / grid / timeline layouts
- [ ] Open each detail tab (summary / check-ins / journal / full analytics)
- [ ] Verify heatmap updates immediately after check-in
- [ ] Verify streak increments correctly at midnight rollover
- [ ] Test on macOS — all layouts, no iOS-only crashes
- [ ] Add widget to Home Screen, tap check-in button, verify sync to app

### Accessibility
- Dynamic Type: test at maximum scale
- VoiceOver: all interactive elements reachable and labelled
- Reduce Motion: all animations disabled gracefully

---

## Versioning

`MAJOR.MINOR.PATCH` via Build Settings → Product Version.

**Current: 1.0.0**

---

## License

Copyright © 2024 Mihir Maru. All rights reserved.
