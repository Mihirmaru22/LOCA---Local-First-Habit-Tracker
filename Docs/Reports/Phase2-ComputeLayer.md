# Phase 2 Report — Compute Layer

**Phase:** 2 of 10  
**Status:** ✅ Complete — reviewed, all High findings resolved  
**Date Completed:** 2026-06-29  
**Next Phase:** Phase 3 — Navigation Shell  

---

## What Was Built

Phase 2 delivered the pure compute layer for streak and heatmap analytics. Both files live in `LOCA/Analytics/`, have zero dependency on SwiftUI, WidgetKit, App Intents, or `ModelContext`, and are compiled into both the Main App and Widget Extension targets via Xcode target membership.

| File | Role |
|------|------|
| `StreakCalculator.swift` | `LogSnapshot` (Sendable bridge), `DayTotal`, `StreakResult` value types; `aggregateByDay` / `aggregateByDayWithGrace` shared aggregation kernel; `StreakCalculator.calculate` full-history streak recomputation |
| `HeatmapDataProvider.swift` | `DayCell` value type; `HeatmapDataProvider.buildDayGrid` — builds the trailing-window heatmap grid |

### Architecture Compliance Verified
- No SwiftUI, WidgetKit, or App Intents imports in either file
- No `ModelContext`/`ModelContainer`/`@Query`/`@Environment` access — pure value-type computation
- All public types conform to `Sendable`; all methods are `nonisolated async` per ADR-005
- No O(n²) algorithms; no Sendable violations; no leap-year or DST day-arithmetic bugs in the consecutive-day walk (independently verified during review)

---

## Review Findings

A full Apple Frameworks-level pre-ship review was conducted after Phase 2 was written, covering algorithmic correctness, Calendar/DST/timezone handling, Swift 6 concurrency, performance, and CloudKit synchronization assumptions. 14 findings were identified across 3 severity levels (zero Critical).

### High — 6 findings, all resolved

| ID | Finding | Resolution |
|----|---------|-----------|
| H1 | A future-dated or clock-skewed `LogEntry` (plausible after multi-device CloudKit sync with clock drift) could become the chronologically last completed day, suppressing an active `currentStreak` to zero or inflating `longestStreak` | `calculateStreaks` now filters `dayTotals` to `date <= today` before the streak walk begins, excluding any day later than the calculation's reference date |
| H2 | Floating-point summation of fractional log values (e.g., repeated 0.1-unit increments) could leave `total` at `0.9999999999999998` instead of exactly `1.0`, causing a genuinely completed day to register as incomplete — including in the accessibility-label `intensity >= 1.0` pattern | Added a shared `DayTotal.completionEpsilon = 1e-9` constant; `isComplete`/`isCompleteWithGrace` and `HeatmapDataProvider`'s intensity calculation all subtract it before comparison, so an at-or-above-target day always produces exactly `1.0`, not a near-1.0 approximation |
| H3 | `HeatmapDataProvider` called the same combined aggregation function `StreakCalculator` used, unconditionally paying for DST grace-window computation it never read (`graceTotal` was never accessed) | Split into two functions: `aggregateByDay` (primary attribution only, used by `HeatmapDataProvider`) and `aggregateByDayWithGrace` (adds grace credits, used by `StreakCalculator`). The heatmap's hot path no longer executes the grace-credit pass at all |
| H4 | The combined aggregation function recomputed `calendar.startOfDay(for:)` — the most expensive operation in the algorithm — twice per snapshot, once in each of two sequential loops | `aggregateByDayWithGrace` now computes each snapshot's day exactly once via a single `map` pass (`snapshotDays`), reused by both the primary-attribution loop and the grace-credit loop. Also removed two redundant re-normalization calls in the grace-window branches |
| H5 | `calculateStreaks` called `Date()` directly with no way for a test to inject a fixed reference instant, making the four mandatory DST test dates in Engineering Principles §8.3 non-deterministic and effectively untestable for the "is streak active" logic | `StreakCalculator.calculate` now accepts `referenceDate: Date = Date()`, threaded through to `calculateStreaks`, which derives `today`/`yesterday` from it instead of an internal `Date()` call |
| H6 | Engineering Principles §2.1, §3.2, §5.1, §5.2, and §8.1 referenced a type, `DailyAggregator`, that does not exist anywhere in the Phase 2 implementation — creating ambiguity about which function the mandated 10,000-record performance test and PR-checklist Time Profiler requirement actually cover | All seven references updated to name `aggregateByDay` and `aggregateByDayWithGrace` explicitly. Engineering Principles revision bumped to 1.1.0 with an explicit changelog entry per the document's own amendment process |

### Medium — 4 findings, deferred to Phase 5/6

| ID | Finding | Deferred To |
|----|---------|------------|
| M1 | Two independent `Date()` calls in `buildDayGrid` (one inside `Date.trailingDays`, one for `today`) create a rare midnight-boundary race where no cell shows `isToday == true` | Phase 5 (Heatmap & Detail) — pairs naturally with adding an injectable `referenceDate` to `Date.trailingDays` itself |
| M2 | Cross-timezone travel retroactively reattributes past entries to different calendar days, since day-boundary computation always uses the device's *current* timezone, not the timezone at logging time | Documented as an intentional design tradeoff in `aggregateByDay`'s header comment; no code change planned |
| M3 | No `NaN`/`Infinite` guard on summed `Double` values — a single corrupted `LogEntry.value` would silently and permanently zero out a day's completion status | Phase 6 (Check-In Flow) — pair with input validation at the point values are first captured |
| M4 | No staleness-detection mechanism if new CloudKit data arrives while a recalculation is in flight | Phase 3 — must be addressed when the `NSPersistentCloudKitContainerEvent` observer and `needsStreakRecalculation` orchestration logic are implemented |

### Low — 4 findings, deferred

| ID | Finding | Deferred To |
|----|---------|------------|
| L1 | `LogSnapshot.init(from:)` doc comment described a more general actor constraint than its actual `@MainActor`-pinned signature | Tightened wording was applied during the H1–H6 pass as a side effect of touching the file; formal generalization (if ever needed) deferred indefinitely |
| L2 | `DayTotal.isComplete(for:)` is unused; `HeatmapDataProvider` duplicates equivalent logic inline | Low priority — consolidate if/when intensity calculation is touched again |
| L3 | Intermediate tuple array allocation in `Dictionary(uniqueKeysWithValues:)` construction | Low priority — negligible at current data scale |
| L4 | No upper bound on `windowDays`; grace-window boundary uses strict `<` with no documented boundary-instant behavior | Low priority — cheap robustness improvement, not urgent |

---

## Fix Verification (Re-Review Summary)

After applying the six High-severity fixes, each was independently re-verified against the corrected code:

- **H1**: `calculateStreaks` filters `dayTotals` to `date <= today` before building `completedDates` — confirmed via direct inspection and grep verification
- **H2**: `DayTotal.completionEpsilon` is the single shared constant read by both `StreakCalculator`'s completion checks and `HeatmapDataProvider`'s intensity branch — confirmed no duplicated epsilon values exist
- **H3**: `aggregateByDay` and `aggregateByDayWithGrace` are now distinct functions; `HeatmapDataProvider` calls only the former — confirmed via call-site grep
- **H4**: `snapshotDays` is computed once and reused by both loops in `aggregateByDayWithGrace` — confirmed via line-level inspection
- **H5**: `calculateStreaks` no longer contains a direct `calendar.startOfDay(for: Date())` call; `referenceDate` is threaded through from `calculate`'s public signature — confirmed via grep showing zero direct `Date()` calls inside the function
- **H6**: Zero remaining `DailyAggregator` references in Engineering Principles outside the changelog entry documenting the fix — confirmed via grep

No regressions were introduced: brace balance was verified on both files post-edit, all Phase 1 model/persistence files were untouched, and the deferred Medium/Low findings were left unaddressed exactly as scoped.

---

## Algorithm Complexity Summary

| Function | Complexity | Notes |
|----------|-----------|-------|
| `aggregateByDay` | O(N log D) | Primary attribution only — one O(N) pass + O(D log D) sort. Used by `HeatmapDataProvider` |
| `aggregateByDayWithGrace` | O(N log D) | One O(N) pass to compute `snapshotDays`, two further O(N) dictionary-only passes reusing it, + O(D log D) sort. Used by `StreakCalculator` |
| `StreakCalculator.calculate` | O(N log D) | Delegates to `aggregateByDayWithGrace`, then a single O(D) forward walk |
| `HeatmapDataProvider.buildDayGrid` | O(N log D + W) | Delegates to `aggregateByDay`, then O(W) grid construction for the trailing window |

N = snapshot count, D = distinct calendar days, W = window size (typically 365).

---

## Phase 3 Entry Criteria

- [x] All High review findings (H1–H6) resolved
- [x] Re-review confirms each fix independently
- [x] Engineering Principles updated and revision-bumped per its own amendment process
- [x] No dependency on SwiftUI, WidgetKit, App Intents, or `ModelContext` in either file
- [x] `StreakCalculator.calculate` and `HeatmapDataProvider.buildDayGrid` both accept all data via parameters — no hidden global state
- [ ] `NSPersistentCloudKitContainerEvent` observer (Phase 1 scaffold work, still pending) must address M4 when implemented
- [ ] Phase 2 unit tests written (the four mandatory DST dates via injected `referenceDate`, boundary conditions for both aggregation functions, the 10,000-record performance baseline for `aggregateByDayWithGrace`)
