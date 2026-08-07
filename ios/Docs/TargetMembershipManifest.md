# Target Membership Verification Manifest

**Purpose:** Every file delivered across Phases 1–3 was written and reviewed as
loose Swift files, organized into a folder structure that mirrors the intended
Xcode target layout, but no `.xcodeproj` has existed until Phase 0. This document
is the authoritative checklist for setting real Xcode target membership on every
existing file. "Verified" here means "specified correctly in this document" — the
actual Xcode checkbox state must be confirmed against this list when the project
is opened in Xcode, since that step cannot be performed outside the Xcode GUI.

**Convention:** ⊕ = both targets. Main = Main App target only. Widget = Widget
Extension target only (none yet — see note at bottom).

---

## App/ (Phase 0)

| File | Target | Rationale |
|------|--------|-----------|
| `LOCAApp.swift` | Main | `@main` entry point — meaningless in a Widget Extension |
| `CloudKitSyncCoordinator.swift` | Main | Owned and started by `LOCAApp`; mutates the shared container's boards, an app-lifecycle concern, not a widget concern |

## Core/Models/ (Phase 1)

| File | Target | Rationale |
|------|--------|-----------|
| `HabitBoard.swift` | ⊕ | `@Model` type — both the app and the widget's `TimelineProvider` need the schema |
| `LogEntry.swift` | ⊕ | Same reasoning |
| `VersionedSchema.swift` | ⊕ | `RippleSchemaV1.models` must resolve identically in both targets — this is the exact failure mode ADR-004 warns about if membership is set incorrectly |

## Core/Persistence/ (Phase 1)

| File | Target | Rationale |
|------|--------|-----------|
| `ModelContainerFactory.swift` | ⊕ | `makeSharedContainer()` is called from both `LOCAApp.swift` (Main) and the future `TimelineProvider` (Widget), per the factory's own doc comment |
| `PersistenceError.swift` | ⊕ | Consumed by `ModelContainerFactory`, which is shared |

## Core/Extensions/ (Phase 1)

| File | Target | Rationale |
|------|--------|-----------|
| `Date+Calendar.swift` | ⊕ | Consumed by `Analytics/`, which is shared |
| `ColorPalette.swift` | ⊕ | The widget's heatmap timeline (Phase 9) will need the same colour system as the main app's heatmap (Phase 5) |
| `Double+Clamp.swift` | ⊕ | Consumed by `Analytics/`, which is shared |

## Analytics/ (Phase 2)

| File | Target | Rationale |
|------|--------|-----------|
| `StreakCalculator.swift` | ⊕ | Widget timelines (Phase 9) display streak data — must compute it the same way the main app does |
| `HeatmapDataProvider.swift` | ⊕ | The widget's entire purpose (per the original spec) is displaying a heatmap — must share this exact computation |

## Features/Navigation/, Features/HabitDetail/ (Phase 3)

| File | Target | Rationale |
|------|--------|-----------|
| `RootNavigationView.swift` | Main | Imports SwiftUI navigation APIs meaningless outside the Main App target |
| `HabitSidebarView.swift` | Main | Same |
| `HabitDetailView.swift` | Main | Same |

## Root

| File | Target | Rationale |
|------|--------|-----------|
| `LOCA.entitlements` | Main | App Groups + CloudKit capability for the Main App target |

---

## Note on the Widget Extension Target

No Widget Extension target exists yet, and none of the files above marked ⊕ can
have their Widget-side membership actually set until that target is created in
Xcode — this happens in Phase 9, per the roadmap, matching `ModelContainerFactory`'s
own long-standing documentation of how the widget will consume it. Phase 0
deliberately does not create an empty Widget Extension target or its entitlements
file; doing so ahead of any Widget Extension code would be scaffolding for a
target with nothing in it, outside this phase's stated scope of "making the
existing architecture runnable" — the existing architecture (Main App only) does
not require the Widget Extension to exist to run.

When Phase 9 creates the Widget Extension target, every file marked ⊕ in this
document must have its membership checkbox set for that target too, and a
`LOCAWidget.entitlements` file (App Groups + CloudKit, same identifiers as
`LOCA.entitlements`) must be created at that time.
