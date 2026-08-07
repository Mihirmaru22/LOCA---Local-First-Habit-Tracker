# Phase 3 Report — Navigation Shell

**Phase:** 3 of 10
**Status:** ✅ Complete — reviewed, all High findings + M1 fixed, verified
**Date Completed:** 2026-06-30
**Next:** Phase 0 (runtime integration) — scheduled after this approval, before Phase 4

---

## What Was Built

Phase 3 delivered the navigation shell: a single `NavigationSplitView` adapting
automatically across iPhone, iPad, and Mac, a sidebar list of active `HabitBoard`s,
selection state management, and an empty placeholder for the detail column. No
heatmap, chart, journal, analytics, check-in, widget, or App Intents content —
strictly navigation chrome, per explicit scope agreement at the start of this phase.

| File | Role |
|------|------|
| `RootNavigationView.swift` | The navigation shell root — owns `columnVisibility`, `selectedBoardID`, the single `@Query` against `HabitBoard`, and auto-selection logic |
| `HabitSidebarView.swift` | Sidebar column — selectable list of active boards, empty-state placeholder |
| `HabitDetailView.swift` | Placeholder detail container — no business logic, stable API for Phase 5 to build inside |
| `HabitBoard.swift` (modified) | Added `static var activePredicate` — closes Phase 1 review finding M1 |

### Architecture Compliance Verified
- Single `NavigationSplitView` tree for all platforms (ADR-006) — zero `#if os()` layout branching anywhere
- Selection state holds `UUID?`, never a live `HabitBoard?` reference (ADR-007)
- `HabitSidebarView` and `HabitDetailView` receive data via parameters, not their own `@Query` — single-sourced at `RootNavigationView`
- No `try!` anywhere, including Previews — failed containers degrade to a visible `ContentUnavailableView` rather than crashing (closes Phase 1 finding M4 at its first real Preview usage)

---

## Review Findings

A formal Correctness / Engineering / Experience review was conducted after Phase 3 was written, matching the standard established in Phases 1 and 2. Zero Critical findings. Ten findings total across three severity levels.

### High — 3 findings, all resolved

| ID | Finding | Resolution |
|----|---------|-----------|
| H1 | Sidebar `List` was missing `.listStyle(.sidebar)` — would not render with native platform sidebar chrome (translucent vibrancy background, sidebar row styling) on macOS/iPadOS, failing the project's explicit "feels like a first-party Apple feature" bar | `.listStyle(.sidebar)` applied to the `List` |
| H2 | Empty-state `ContentUnavailableView` was embedded as row content inside the selectable `List` rather than branching before it — non-idiomatic pattern producing incorrect interaction chrome (hover/press highlight) on non-interactive content | Restructured `HabitSidebarView.body` to branch via `Group { if boards.isEmpty { ... } else { List { ... } } }` — empty-state and `List` are now mutually exclusive siblings |
| H3 | No auto-selection of the first habit on regular-width layouts (iPad/Mac) — violated established Apple HIG convention (Mail, Notes, Reminders, Settings all auto-select first item when both split-view columns are visible) | Added `autoSelectFirstBoardIfNeeded()`, gated on `horizontalSizeClass == .regular` to correctly exclude iPhone (where auto-selecting would skip the sidebar list entirely, contrary to how first-party apps behave on iPhone), wired via `.task` and `.onChange(of: activeBoards.count)` |

### Medium — 1 fixed, 2 deferred

| ID | Finding | Disposition |
|----|---------|------------|
| M1 | Detail-column empty-state copy ("Choose a habit from the sidebar") contradicted the sidebar's own empty-state copy when zero habits exist — Phase 3's own two placeholder views talking past each other | **Fixed** — `EmptyDetailPlaceholderView` now takes `hasAnyBoards: Bool` and shows non-contradictory copy for the true first-run case |
| M2 | `HabitBoard.activePredicate` as a static computed property is unverified against a known SwiftData 17.0–17.2 predicate-fragility class this project already worked around once (ADR-003) — low probability given the predicate's simplicity (no captures, no relationship traversal), but unconfirmed | **Deferred** to Phase 0/4 exit criteria — verify empirically against a real (non-in-memory) `ModelContainer` |
| M3 | No selection persistence across app relaunch (`@SceneStorage`) | **Deferred** to Phase 10 (Polish) |

### Low — 4 findings, all deferred

| ID | Finding | Deferred To |
|----|---------|------------|
| L1 | "0 day streak" copy not the warmest first-party microcopy | Phase 10 (copy pass) |
| L2 | Doc comment overstated Identifiable "synthesis" | Wording corrected as a zero-risk drive-by fix during the H1/H2 edit; no behavior change |
| L3 | Undocumented `sort: \HabitBoard.createdAt` ordering rationale | Low priority, no phase assigned |
| L4 | No macOS keyboard shortcuts for sidebar selection | Phase 10 (Polish) |

---

## Fix Verification (Re-Review Summary)

- **H1**: `.listStyle(.sidebar)` confirmed present on the `List`, applied only within the non-empty branch
- **H2**: Body structure confirmed as `Group { if/else }` with `List` and the empty-state view as mutually exclusive siblings, never nested
- **H3**: `horizontalSizeClass == .regular` guard confirmed present before any selection mutation; wired to both initial appearance (`.task`) and later-arriving data (`.onChange(of: activeBoards.count)`, using a count proxy since `HabitBoard` `Equatable` conformance isn't guaranteed)
- **M1**: `hasAnyBoards` parameter confirmed threaded from `RootNavigationView` through to `EmptyDetailPlaceholderView`, with copy branching confirmed at the `Text(...)` call site

No regressions: brace balance verified on both touched files, no `print`/`fatalError`/force-unwrap introduced, `HabitDetailView.swift` confirmed unmodified (correctly out of this fix's scope via checksum), and all five deferred findings (M2, M3, L1, L3, L4) confirmed untouched by direct inspection.

---

## Phase 0 Entry Criteria

- [x] Phase 3 formally approved
- [x] All High findings (H1–H3) resolved and verified
- [x] M1 resolved and verified (Phase-3-owned, folded into the same fix pass)
- [ ] M2 verification — confirm `HabitBoard.activePredicate` behaves correctly against a real `ModelContainer`, not just the in-memory Preview container used throughout Phases 1–3. This is now Phase 0's first meaningful test, since Phase 0 is exactly the phase that introduces a real container for the first time.
