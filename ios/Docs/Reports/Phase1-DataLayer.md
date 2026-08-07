# Phase 1 Report — Data Layer

**Phase:** 1 of 10  
**Status:** ✅ Complete — reviewed, all Critical and High findings resolved  
**Date Completed:** 2025-06-28  
**Next Phase:** Phase 2 — Analytics Engine  

---

## What Was Built

Phase 1 delivered the complete SwiftData schema, persistence factory, and shared utility extensions. All files live in `LOCA/Core/` and are compiled into both the Main App and Widget Extension targets via Xcode target membership.

| File | Role |
|------|------|
| `HabitBoard.swift` | Primary `@Model` — habit configuration, soft delete, cached streak, metric type |
| `LogEntry.swift` | Append-only `@Model` — single check-in record with denormalized `boardID` |
| `VersionedSchema.swift` | `RippleSchemaV1` + `RippleMigrationPlan` — schema versioning from day one |
| `ModelContainerFactory.swift` | Static factory for production (App Group + CloudKit) and in-memory (tests/Previews) containers |
| `PersistenceError.swift` | `LocalizedError` domain error type |
| `Date+Calendar.swift` | DST-aware day boundary helpers — `startOfDay`, `dayRange`, `trailingDays` |
| `ColorPalette.swift` | Indexed colour system (ADR-002) — 12 entries, O(1) subscript, `heatmapColor` formula |
| `Double+Clamp.swift` | `clamped(to:)` for heatmap intensity bounds |

### CloudKit Compliance Verified
- No `@Attribute(.unique)` anywhere in the schema
- Every stored property carries a default value or is `Optional`
- All relationships are `Optional` with `.nullify` delete rule
- `LogEntry` is append-only — no update or delete path

---

## Architecture Decisions Implemented

All five ADRs from the pre-implementation plan were realised in this phase:

| ADR | Decision |
|-----|---------|
| ADR-001 | Soft delete via `archivedAt: Date?` — `modelContext.delete()` never called on `HabitBoard` |
| ADR-002 | `colorIndex: Int` — eliminates hex parse cost in 365-cell heatmap render path |
| ADR-003 | `boardID: UUID` denormalized on `LogEntry` — works around iOS 17 relationship predicate bug |
| ADR-004 | Xcode target membership — no local SPM package, no `public` overhead |
| ADR-005 | `HeatmapDataProvider` as actor-isolated free function — Phase 2 implementation |

---

## Review Findings

A full Apple Frameworks-level code review was conducted after Phase 1 was written. 14 findings were identified across 4 severity levels.

### Critical — 3 findings, all resolved

| ID | File | Finding | Resolution |
|----|------|---------|-----------|
| C1 | `HabitBoard.swift` | `archive(in:)` rollback set `archivedAt = nil` unconditionally, corrupting prior non-nil values | Capture `previousArchivedAt` before mutation; restore it in `catch` |
| C2 | `ColorPalette.swift` | `Color(.systemGray6)` is UIKit-only — macOS build failure | `#if canImport(UIKit)` conditional; `Color(uiColor: .systemGray6)` on iOS, `Color(nsColor: .windowBackgroundColor)` on macOS, extracted to `emptyCellColor` |
| C3 | `ColorPalette.swift` | Doc comment promised `Color.clear` for empty cells; implementation returned `Color(.systemGray6)` | Updated doc comment to reference `emptyCellColor` and describe the correct return value |

### High — 5 findings, all resolved

| ID | File | Finding | Resolution |
|----|------|---------|-----------|
| H1 | `HabitBoard.swift` | Streak cache (`currentStreak`, `longestStreak`, `lastCheckedDate`) subject to CloudKit last-write-wins — silently incorrect after sync on devices with divergent log histories | Added `needsStreakRecalculation: Bool = false` invalidation flag; documented full lifecycle (set by CloudKit event observer, cleared by `StreakCalculator` after successful recalculation) |
| H2 | `LogEntry.swift` | `board: HabitBoard?` had no `@Relationship` annotation — inverse inferred from one side only, fragile on iOS 17.0–17.2 | Added `@Relationship(inverse: \HabitBoard.logs)` explicit declaration |
| H3 | `ModelContainerFactory.swift` | `Schema` embedded in both `ModelConfiguration(schema:)` and `ModelContainer(for:)` — API misuse with unspecified reconciliation behaviour | Removed `schema:` from `ModelConfiguration`; schema now passed exclusively to `ModelContainer(for:)` |
| H4 | `HabitBoard.swift` | `effectiveTarget` floor of `1e-9` caused `targetValue == 0.0` to make every entry show 100% completion | Replaced `max(targetValue ?? 1.0, 1e-9)` with conditional expression `let raw = targetValue ?? 1.0; return raw > 0 ? raw : 1.0`. Note: reviewer's proposed fix `max(_, 1.0)` was not used as it incorrectly clips valid fractional targets (e.g., 0.5 miles/day) |
| H5 | `HabitBoard.swift` | `calendar.startOfDay(for:)` called once per log entry in `updateStreak` filter — expensive Calendar operation in O(n) loop on main thread | Precomputed `tomorrowStart` via `calendar.date(byAdding: .day, value: 1, to: todayStart)`; filter now uses half-open interval `$0.timestamp >= todayStart && $0.timestamp < tomorrowStart` — two Date comparisons per entry |

### Medium — 4 findings, deferred

| ID | File | Finding | Deferred To |
|----|------|---------|------------|
| M1 | `HabitBoard.swift` | No canonical `activePredicate` — archived boards will leak into views | Phase 4 (Dashboard) — must be added before first `@Query` on boards |
| M2 | `PersistenceError.swift` | `containerURLNotFound` case has no throw site | Phase 1 cleanup — remove or add pre-flight URL check |
| M3 | `HabitBoard.swift` | `resetStreakCache()` leaves unsaved zero state; no recovery if crash occurs mid-recalc | Partially mitigated by H1's `needsStreakRecalculation` flag; full mitigation in Phase 2 `StreakCalculator` |
| M4 | `ModelContainerFactory.swift` | Doc comment endorses `try!` in Preview code | Phase 3 (Navigation Shell) — provide a non-throwing Preview helper |

### Low — 2 findings, deferred

| ID | File | Finding | Deferred To |
|----|------|---------|------------|
| L1 | `HabitBoard.swift` | `MetricType.label` strings not wrapped for localization | Phase 10 (QA & Polish) |
| L2 | `Date+Calendar.swift` | `dayRange` result array not pre-allocated — ~9 reallocations for 365-day grid | Phase 2 — fix when `HeatmapDataProvider` calls this function |

---

## Remaining Risks Before Phase 2

| Risk | Severity | Mitigation |
|------|---------|-----------|
| `NSPersistentCloudKitContainerEvent` observer not implemented — `needsStreakRecalculation` flag is never set | High | Must be implemented in `LOCAApp.swift` (scaffold) before any CloudKit-enabled testing |
| `ColorPalette` WCAG AA contrast unvalidated | Medium | Required before Phase 7 (`NewHabitForm`) ships |
| `cloudKitDatabase: .automatic` unverified against provisioning profile | Medium | Verify before first CloudKit sync in any environment |
| M1 `activePredicate` absent | Medium | Must be added before Phase 4 `DashboardView` is written |

---

## Phase 2 Entry Criteria

- [x] All Critical and High review findings resolved
- [x] `needsStreakRecalculation` flag present in schema (H1)
- [x] Both sides of `HabitBoard ↔ LogEntry` relationship explicitly declared (H2)
- [x] `ModelContainerFactory` using correct API (H3)
- [x] `effectiveTarget` safe for all valid and invalid inputs (H4)
- [x] `updateStreak` using O(1) date comparisons in filter (H5)
- [ ] `NSPersistentCloudKitContainerEvent` observer implemented in app entry point
- [ ] Phase 1 unit tests written (`StreakCalculator` DST suite, persistence integration tests)
