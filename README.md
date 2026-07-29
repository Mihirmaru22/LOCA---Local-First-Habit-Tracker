# LOCA — Local-First Habit Tracker + Personal Life Model

A high-performance, local-first habit tracker and personal life intelligence system for iOS 17+ and macOS 14+. Built with SwiftUI, SwiftData, and CloudKit — no custom backend, no REST APIs, no network dependency for core functionality. All inference runs on-device.

> **Read first:** [`Docs/THE-CENTRAL-QUESTION.md`](Docs/THE-CENTRAL-QUESTION.md)
> — the one question the whole product is a bet on:
> *"Does LOCA let me **see** my life, or does it just **show me data** about my life?"*

---

## Philosophy

**The device is the server.** All data lives locally in a SQLite store managed by SwiftData. CloudKit acts as a silent, asynchronous sync layer. The UI never awaits a network response to update.

**The model, not the entry, is the product.** LOCA passively builds a probabilistic model of the user's life from sensors, calendars, health data, and habit logs — without asking them to keep a diary. The learning engine infers. It asks only when passive inference is genuinely exhausted.

**Epistemic honesty is a first-class constraint.** LOCA distinguishes no-data from low-value. Absent measurements are structurally separate from measured-neutral values. No composition path converts ignorance into a midpoint.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (view-driven state, no thick MVVM) |
| Data | SwiftData + NSPersistentCloudKitContainer |
| Sync | CloudKit (silent background sync) |
| Inference | On-device only — no network calls, no external ML APIs |
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
│   ├── LOCAApp.swift                    # Entry point, container init
│   ├── AppCoordinator.swift             # Root coordinator
│   ├── CloudKitSyncCoordinator.swift    # NSPersistentCloudKitContainerEvent observer
│   ├── SignalCollectionCoordinator.swift # Hourly sensor pipeline trigger
│   ├── InterventionDelivery.swift       # Habit intervention scheduling
│   ├── ReflectionDelivery.swift         # Reflection prompt delivery
│   └── WidgetRefreshCoordinator.swift   # WidgetKit timeline invalidation
│
├── Core/
│   ├── Models/
│   │   ├── HabitBoard.swift             # Primary habit entity (@Model)
│   │   ├── LogEntry.swift               # Append-only check-in record (@Model)
│   │   ├── ReflectionUnit.swift         # Reflection storage
│   │   └── VersionedSchema.swift        # RippleSchemaV1 + RippleMigrationPlan
│   ├── Persistence/
│   │   ├── ModelContainerFactory.swift  # Production / local dev / in-memory containers
│   │   ├── CheckInWriter.swift          # Atomic check-in write path
│   │   ├── DebugSeeder.swift            # Habit sample data (DEBUG only)
│   │   ├── LifeSeeder.swift             # Life model sample data (DEBUG only)
│   │   ├── ReminderScheduler.swift      # Local notification scheduling
│   │   └── PersistenceError.swift       # Typed error domain
│   ├── Analytics/
│   │   ├── HeatmapDataProvider.swift    # Off-thread heatmap aggregation
│   │   └── StreakCalculator.swift       # Full historical streak recalculation
│   └── DesignSystem/
│       ├── DS.swift                     # Token namespace (spacing, radius, motion)
│       ├── DS+Color.swift               # Semantic color tokens
│       ├── DS+Typography.swift          # Font scale
│       ├── DS+Motion.swift              # Animation tokens
│       ├── DSComponents.swift           # LOCACard, SectionHeader, ValueText
│       ├── ArcGaugeView.swift           # Reusable arc progress component
│       ├── WeeklyBarChart.swift         # Shared bar chart component
│       ├── Haptics.swift                # Haptic feedback wrapper
│       └── PressableButtonStyle.swift   # Press-state button style
│
├── Features/
│   ├── Dashboard/                       # Habit list/grid/timeline views
│   ├── HabitDetail/                     # 4-tab detail: summary/check-ins/journal/analytics
│   ├── HabitManagement/                 # Habit creation, editing, templates, recommendations
│   ├── PersonalLifeView/                # Life scene, chapters, traits, people, patterns
│   ├── Present/                         # "Present" tab: now/reach/ask views
│   └── Settings/                        # Signal collection status
│
├── Learning/
│   ├── Inference/
│   │   ├── InferenceTypes.swift         # InferenceProvenance, InferenceResult (shared with widget)
│   │   ├── InferredStateModel.swift     # @Model for hourly inferred states (absence-aware)
│   │   ├── StateInferenceEngine.swift   # Hourly inference orchestrator
│   │   ├── EnergyInferenceModel.swift   # Energy dimension inference
│   │   ├── StressInferenceModel.swift   # Stress dimension inference
│   │   ├── FocusInferenceModel.swift    # Focus dimension inference
│   │   ├── MoodInferenceModel.swift     # Mood dimension inference
│   │   └── CalibrationManager.swift     # Per-user calibration adjustments
│   ├── Managers/                        # Sensor access (HealthKit, Motion, Calendar, Location)
│   ├── Models/
│   │   ├── SignalModels.swift           # SignalEvent, SignalSource, WeeklyRegime
│   │   └── UncertaintyModels.swift      # UncertaintyType (epistemic / aleatoric)
│   ├── EventDetection/
│   │   ├── EventDetectionEngine.swift   # Life event detection from regime shifts
│   │   ├── EventClassifier.swift        # Signal-to-event classification
│   │   ├── AnomalyDetector.swift        # Statistical anomaly detection
│   │   ├── RegimePersistenceChecker.swift # Regime stability checks
│   │   ├── RelationshipGraphEngine.swift # Person co-occurrence graph
│   │   └── LifeEventModels.swift        # LifeEvent, EventType @Models
│   ├── Entities/
│   │   ├── ChapterBuilder.swift         # Segments life into named chapters
│   │   ├── ChapterModel.swift           # Chapter @Model
│   │   ├── TraitInferenceEngine.swift   # 6 trait dimensions from 30-day state windows
│   │   ├── TraitModel.swift             # Trait @Model
│   │   ├── PersonModel.swift            # Person, PersonAppearance @Models
│   │   ├── PeopleExtractor.swift        # Calendar contact extraction
│   │   ├── DirectionModel.swift         # Direction (goals) @Model
│   │   ├── FeedbackModel.swift          # PatternFeedback, NarrativeFeedback @Models
│   │   └── CalibrationModel.swift       # Calibration @Model
│   ├── Synthesis/
│   │   ├── PatternDetectionEngine.swift # Cross-layer pattern detection
│   │   ├── NarrativeComposer.swift      # Natural language narrative generation
│   │   ├── FeedbackProcessor.swift      # Pattern feedback incorporation
│   │   └── ContextEnricher.swift        # Cross-entity context enrichment
│   ├── UncertaintyValidator.swift       # Validates uncertainty propagation
│   └── ViewRenderingSpecification.swift # Render instruction contracts
│
├── Intents/
│   ├── LogHabitIntent.swift
│   ├── HabitBoardEntity.swift
│   └── LOCAShortcuts.swift
│
└── LOCAWidget/                          # Widget extension target
    ├── HeatmapWidget.swift
    ├── HeatmapWidgetView.swift
    ├── HeatmapProvider.swift
    └── LOCAWidgetBundle.swift
```

---

## Two Verticals

### Vertical 1 — Habit Engine (Phases 1–10, complete)

The original LOCA: create habits, log check-ins, analyze streaks, view analytics. Local-first with CloudKit sync and WidgetKit integration.

### Vertical 2 — Personal Life Model (Phases P1–P10 / Cycle 2)

A passive intelligence layer that builds a probabilistic model of the user's life from sensors and behavior — without asking them to keep a diary.

**The pipeline (sensor → storage → inference → entities → synthesis → surface):**

```
Sensors (HealthKit / Motion / Calendar / Location)
    ↓  SignalManager (hourly collection)
SignalEvent  (raw sensor readings, stored in SwiftData)
    ↓  StateInferenceEngine (hourly, idempotent)
InferredState  (energy / stress / focus / mood, with absence flags)
    ↓  EventDetectionEngine (regime shift detection)
LifeEvent  (workChange / locationChange / socialChange / …)
    ↓  ChapterBuilder  →  Chapter entities
    ↓  TraitInferenceEngine  →  Trait entities (30-day rolling window)
    ↓  PeopleExtractor / RelationshipGraphEngine  →  Person entities
    ↓  PatternDetectionEngine  →  LifePattern cross-layer patterns
    ↓  NarrativeComposer  →  NarrativeUnit natural language
    ↓  MultiEntityComposer / ViewCompositionEngine
Present tab / LifeSceneView / ChapterListView / PatternsView / …
```

---

## Epistemic Architecture (Cycle 2 — C1)

The Cycle 2 epistemics layer enforces one invariant end-to-end: **absence is never converted into a value.** Every layer from inference to surface must distinguish "no data arrived" from "data arrived and the value was neutral."

### Absence representation

`InferredState` carries per-dimension boolean flags alongside numeric values:

| Flag | Meaning |
|---|---|
| `energyAbsent` | No energy signal arrived this hour — `energy` field (0.0) must not be read |
| `stressAbsent` | Same for stress |
| `focusAbsent` | Same for focus |
| `moodAbsent` | Same for mood |

### Provenance (C1.2)

Every `.measured` result carries `InferenceProvenance`: contributing sources, sample count, time window, and `UncertaintyType`.

### Uncertainty types (C1.3)

| Type | Meaning |
|---|---|
| `.epistemic` | Reducible — more data would help (< 3 samples) |
| `.aleatoric` | Inherent — more data won't eliminate the spread (≥ 3 samples) |

### What C1 eliminates

- `guard !x.isEmpty else { return 0.5 }` — fabricating a midpoint from absence
- Including absent-flagged states (value 0.0) in means, deltas, or pattern confidence
- Rendering absent timeline points as values (bars at 0, dots at 0%, line segments to the floor)
- Composition layers that silently supply defaults when the scene is structurally absent

### Surface behavior

- `EnergyTimelineView`: gaps in the line at absent points, no dot drawn
- `StressUnderlayView`: no bar rendered for absent hours
- `MoodDotsView`: hollow ring + "–" label for absent, not "0%"
- `LifeSceneView`: shows the communicative empty state when `ComposedScene.isDataAbsent`
- `UncertaintyLegendView`: three-state legend — Certain / Speculative / No data

---

## Data Model

### Habit Engine Models

**HabitBoard** — a single tracked habit.

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Stable identity |
| `name` | `String` | Display name |
| `metricType` | `Int` | 0 = binary, 1 = quantitative |
| `targetValue` | `Double?` | Daily goal; nil for binary |
| `unitLabel` | `String?` | e.g. "mi", "mins", "L" |
| `colorIndex` | `Int` | Index into ColorPalette |
| `emoji` | `String?` | Optional card prefix |
| `currentStreak` | `Int` | Cached, updated on each check-in |
| `longestStreak` | `Int` | Cached high-water mark |
| `archivedAt` | `Date?` | Soft-delete; nil = active |

**LogEntry** — a single check-in. Append-only at the check-in path.

| Property | Type | Notes |
|---|---|---|
| `timestamp` | `Date` | Exact datetime |
| `value` | `Double` | 1.0 for binary; measured amount for quantitative |
| `note` | `String?` | Optional journal text |
| `boardID` | `UUID` | Denormalized join key (ADR-003) |

### Life Model Entities

**InferredState** — one hourly snapshot of inferred wellbeing.

| Property | Type | Notes |
|---|---|---|
| `timestamp` | `Date` | Hour boundary |
| `energy` / `stress` / `focus` / `mood` | `Double` | 0.0 when `xAbsent = true` |
| `energyAbsent` / `stressAbsent` / `focusAbsent` / `moodAbsent` | `Bool` | C1.1 absence flags |
| `provenanceJSON` | `String?` | Encoded `InferenceProvenance` |
| `uncertaintyTypeRaw` | `String?` | "epistemic" or "aleatoric" |

**Chapter** — a named life interval derived from LifeEvents.

| Property | Notes |
|---|---|
| `startDate` / `endDate` | Interval; `endDate = nil` means current chapter |
| `name` | Default from event type; user-editable |
| `baselineEnergy` / `baselineStress` / `baselineFocus` / `baselineMood` | Per-chapter state baselines |
| `isCurrentChapter` | True for the open chapter |

**Trait** — an inferred personality dimension from a 30-day rolling window.

| Dimension | Description |
|---|---|
| `resilience` | Speed of stress recovery after spikes |
| `consistency` | Regularity of daily energy patterns |
| `socialDrive` | Tendency toward social engagement (proxied via mood lift) |
| `activityDrive` | Physical activity tendency (proxied via morning energy) |
| `focusDepth` | Sustained concentration in uninterrupted sessions |
| `moodStability` | Variance in mood across the window |

**Person / PersonAppearance** — people extracted from calendar events with co-occurrence tracking.

**LifeEvent** — detected life transitions (workChange, locationChange, socialChange, healthChange, scheduleChange, habitChange).

**Direction** — user-authored goals (subject-authoritative; the machine does not author these).

---

## Claim Taxonomy

`Docs/LOCA-Cycle2-Claim-Taxonomy.md` classifies every stored/inferred field into three authority categories:

| Category | Examples |
|---|---|
| **Sensor-authoritative** | All InferredState values, absence flags, provenance, Trait values, Chapter baselines, SignalEvent readings |
| **Subject-authoritative** | Chapter.name, Chapter.userDescription, Direction (all fields), Person.name, RelationshipContext |
| **Unfillable** | Event valence/sentiment, relationship meaning/verdict, Direction existence/content authored by the machine |

The machine never fills subject-authoritative fields. It never authors Direction content. It never adds a sentiment/valence field to LifeEvent.

---

## Feature Status

### Habit Engine
| Feature | Status |
|---|---|
| Habit creation (name, type, goal, unit, color, emoji, template) | ✅ Complete |
| Habit editing | ✅ Complete |
| Habit soft-delete (archive) | ✅ Complete |
| Dashboard — list / grid / timeline layouts | ✅ Complete |
| Binary and quantitative check-ins | ✅ Complete |
| Edit / delete / duplicate check-ins | ✅ Complete |
| Detail view — summary / check-ins / journal / analytics tabs | ✅ Complete |
| 365-day heatmap, streak charts, year comparison, weekday analysis | ✅ Complete |
| Habit templates and unit inference | ✅ Complete |
| Goal inference and tuning | ✅ Complete |
| Relapse prediction and intervention delivery | ✅ Complete |
| Reflection prompts | ✅ Complete |
| Timing suggestions | ✅ Complete |
| Habit correlation analysis | ✅ Complete |
| Habit recommendations | ✅ Complete |
| CloudKit sync | ✅ Complete |
| Widget (WidgetKit + AppIntentConfiguration) | ✅ Complete |
| App Intents / Siri Shortcuts | ✅ Complete |

### Personal Life Model
| Feature | Status |
|---|---|
| Signal collection (HealthKit, Motion, Calendar, Location) | ✅ Complete |
| Hourly state inference — energy, stress, focus, mood | ✅ Complete |
| Absence-aware inference (C1.1 — absence ≠ neutral) | ✅ Complete |
| Inference provenance (C1.2 — sources, sample count, window) | ✅ Complete |
| Uncertainty typing (C1.3 — epistemic vs. aleatoric) | ✅ Complete |
| Absence-aware surface rendering (C1.4) | ✅ Complete |
| Life event detection (regime shift analysis) | ✅ Complete |
| Chapter segmentation from life events | ✅ Complete |
| Chapter baseline computation (per-dimension, absent-filtered) | ✅ Complete |
| Trait inference — 6 dimensions, 30-day rolling window | ✅ Complete |
| Person extraction from calendar events | ✅ Complete |
| Relationship graph (co-occurrence analysis) | ✅ Complete |
| Cross-layer pattern detection (habit×state, person×state, chapter×state) | ✅ Complete |
| Natural language narrative composition | ✅ Complete |
| Pattern feedback incorporation | ✅ Complete |
| Multi-entity composition (chapters + traits + people + insights) | ✅ Complete |
| Present tab (now / reach / ask surfaces) | ✅ Complete |
| LifeSceneView | ✅ Complete |
| ChapterListView | ✅ Complete |
| PatternsView | ✅ Complete |
| NarrativeView | ✅ Complete |
| DirectionCaptureView (user-authored goals) | ✅ Complete |
| RelationshipGraphView | ✅ Complete |
| FeedbackAnalyticsView | ✅ Complete |
| Claim taxonomy (C2.1 — sensor / subject / unfillable) | ✅ Complete |
| Authority-aware composition (C2.2–C2.4) | 🔲 Pending |

---

## Key Architectural Decisions

| ADR | Decision |
|---|---|
| ADR-001 | `LogEntry` append-only at check-in path; user-initiated delete is a separate, permitted action |
| ADR-002 | `ColorPalette` indexed array instead of per-board hex strings — O(1) construction, CloudKit safe |
| ADR-003 | Denormalized `boardID: UUID` on `LogEntry` — `#Predicate` on `board?.id` silently fails on iOS 17 |
| ADR-004 | Shared App Group SQLite; widget and main app address the same file via matching identifier |
| ADR-005 | Snapshot pattern for analytics computation — prevents in-flight mutation during aggregation |
| ADR-009 | `#if LOCAL_DEVELOPMENT` compile-time switch — personal team builds, no entitlements required |
| C1 | Absence flags (`xAbsent: Bool`) on `InferredState` — structurally separate from measured-neutral |
| C1 | `InferenceResult` enum (`.absent` / `.measured`) — absence carries through the pipeline |
| C1 | `InferenceProvenance` on every `.measured` result — callers can answer "where did this come from?" |
| C1 | `UncertaintyType` enum — epistemic (reducible) vs. aleatoric (inherent) |
| C1 | `InferenceTypes.swift` compiled into both main app and widget targets — shared type definitions |
| C2.1 | Claim taxonomy: sensor-authoritative / subject-authoritative / unfillable — governs all C2 sessions |

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

`DebugSeeder` seeds two sample habits with 60 days of log history on first DEBUG launch (no-op if data exists). `LifeSeeder` seeds sample life model data (signals, inferred states, people, chapters) for development of the Personal Life Model vertical.

---

## Platform Shims (`View+PlatformAdaptations.swift`)

| Shim | iOS | macOS |
|---|---|---|
| `.inlineNavigationTitleDisplay()` | `.navigationBarTitleDisplayMode(.inline)` | no-op |
| `.largeNavigationTitleDisplay()` | `.navigationBarTitleDisplayMode(.large)` | no-op |
| `.decimalKeyboard()` | `.keyboardType(.decimalPad)` | no-op |
| `.groupedInsetList()` | `.listStyle(.insetGrouped)` | `.listStyle(.inset)` |
| `.pagedTabView()` | `.tabViewStyle(.page(indexDisplayMode: .never))` | no-op |
| `.confirmationAction` toolbar placement | cross-platform (replaces `.navigationBarTrailing`) | ✓ |

---

## Accessibility

**VoiceOver**
- All interactive list rows carry `.accessibilityElement(children: .ignore)` + descriptive `.accessibilityLabel`.
- Swipe actions (Delete / Edit / Duplicate) exposed via native `.swipeActions`.
- Heatmap cells carry per-cell labels (date + value).

**Dynamic Type**
- All prose uses semantic `DS.Text` tokens that scale automatically.
- Fixed-size fonts in visualization elements (heatmap ≤12pt, chart axes ≤11pt) are intentional for layout integrity.

**Reduce Motion**
- `@Environment(\.accessibilityReduceMotion)` is read; animations skip when set.

---

## Versioning

`MAJOR.MINOR.PATCH` via Build Settings → Product Version.

**Current: 1.0.0**

---

## Design Documents

| Document | Purpose |
|---|---|
| `Docs/LOCA-Founding-Manifesto.md` | Purpose, refusals, ontology — the governing document |
| `Docs/THE-CENTRAL-QUESTION.md` | The one question the whole product is a bet on |
| `Docs/LOCA-Product-Experience.md` | The interaction model |
| `Docs/LOCA-Life-Implementation-Plan.md` | Phase-by-phase build sequence for the life vertical |
| `Docs/LOCA-Cycle2-Plan.md` | Cycle 2: epistemics layer (C1–C6) |
| `Docs/LOCA-Cycle2-Claim-Taxonomy.md` | Every field classified by authority |
| `Docs/PersonalLifeModel.md` | Founding vision (intellectual record) |
| `Docs/PersonalLifeModel-LearningEngine.md` | Learning engine design |
| `Docs/ENGINEERING_PRINCIPLES.md` | Swift 6, on-device, performance, burden budgets |
| `Docs/DESIGN_LANGUAGE.md` | Visual and interaction language |

---

## License

Copyright © 2024 Mihir Maru. All rights reserved.
