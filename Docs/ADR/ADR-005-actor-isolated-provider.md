# ADR-005 — Actor-Isolated `HeatmapDataProvider` as `nonisolated async` Free Function

**Status:** Adopted  
**Date:** 2025-06-28  

## Context

The heatmap requires grouping up to 3+ years of `LogEntry` records by calendar day, summing their values, computing completion ratios, and mapping them to `DayCell` structs with colour-intensity values. This is the most computationally intensive derived-data operation in the app.

Three implementation approaches were evaluated:

**Option A: Computed property on `@Model` extension**  
`var dayGrid: [DayCell]` computed directly on `HabitBoard`.

**Option B: Inline computation in `HeatmapGridView.body`**  
`@State var cells = board.logs.map { ... }` run in the view body.

**Option C: Actor-isolated provider / `nonisolated async` free function**  
`func buildDayGrid(logs: [LogEntry], ...) async -> [DayCell]` off the main thread.

## Decision

Option C: a `nonisolated async` free function, implemented in Phase 2 as `HeatmapDataProvider.swift`.

**Why not Option A:** A computed property on `@Model` runs synchronously on the calling actor. Views read `@Model` properties on `@MainActor`. A full 365-day walk with Calendar operations on the main actor produces a visible frame stall on large datasets. Apple's own guidance for expensive derived SwiftData values recommends background calculation.

**Why not Option B:** Same problem as Option A — the stall happens in `body`, which is strictly main-actor. Additionally, inline computation in `body` means the work re-runs on every SwiftUI invalidation.

The free function signature:
```swift
func buildDayGrid(
    logs: [LogEntry],
    target: Double,
    calendar: Calendar,
    windowDays: Int
) async -> [DayCell]
```

`logs` is a value-type snapshot taken on `@MainActor` before the async call. The function executes on the cooperative thread pool with no actor hop for the computation itself. The returned `[DayCell]` array is stored as `@State` in the view and updated only when the function completes.

## Consequences

**Positive:**
- Main thread is never blocked by heatmap computation.
- The function is pure (no actor, no model context) and fully unit-testable with synthetic input arrays.
- The `[DayCell]` value type crosses the actor boundary safely without `@unchecked Sendable`.

**Negative:**
- A brief delay between view appearance and heatmap population — the grid shows empty/loading state while the first `buildDayGrid` call completes. Mitigated by a skeleton loading state (Phase 10).
- The caller must manage task lifecycle (`task` modifier on the view, cancellation on disappear).
