# ADR-010 — Analytics Cards Computes Its Own Windowed `DayCell` Data

**Status:** Adopted
**Date:** 2026-07-06

## Context

Phase 5.3's completion-rate stat needs day-level grouping, which only `HeatmapDataProvider.buildDayGrid` legitimately provides. `HeatmapView` (Phase 5.2, closed) already computes a `[DayCell]` array internally as private `@State`. Sharing it would require `HeatmapView` to accept that array as an external parameter instead of owning it — a real change to a subphase explicitly closed and not to be reopened without a genuine defect.

## Decision

`AnalyticsCardsView` makes its own independent `HeatmapDataProvider.buildDayGrid` call, windowed to 30 days rather than `HeatmapView`'s 365 — a deliberate choice, not just an implementation convenience: a 30-day completion rate is more actionable than a 365-day one, which would stay permanently depressed by a rough first month on a multi-year habit. Since the two views use different windows, this is not literally duplicate computation of the same thing.

## Consequences

**Positive:** Zero changes to `HeatmapView.swift` or `HabitDetailView`'s existing sections — only an additive new section. Each view's data need is independently correct for its own purpose.

**Negative:** Two separate `buildDayGrid` calls run for the same board when its detail screen is open — accepted, since each costs sub-5ms per Phase 2's documented performance characteristics at realistic dataset sizes.
