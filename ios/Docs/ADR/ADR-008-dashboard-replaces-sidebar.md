# ADR-008 — `DashboardView` as Sidebar Content, Replacing `HabitSidebarView`

**Status:** Adopted
**Date:** 2026-07-02

## Context

The original spec described two separate top-level UI patterns (`NavigationSplitView` for iPad/Mac vs. a `NavigationStack` + card `ScrollView` for iOS). ADR-006 already unified these into one `NavigationSplitView`, leaving no separate destination for a card-based "Dashboard." Phase 3 built `HabitSidebarView` as a minimal row-list, explicitly deferring richer per-habit presentation to "Phase 4's `HabitCardView`."

## Decision

`DashboardView` (rendering `HabitCardView` rows) replaces `HabitSidebarView` at its single call site in `RootNavigationView`'s `sidebar:` closure. Same `boards`/`selection` signature. Selection state (ADR-007), the `activePredicate` query, and auto-select logic (Phase 3 H3) are unmodified. `HabitSidebarView.swift` is left in the codebase, now unused, pending an explicit decision to remove it.

## Consequences

**Positive:** No new navigation destination or routing logic needed; Dashboard is what the sidebar already was, just richer. Zero disruption to ADR-006/007 or Phase 3's selection mechanics.

**Negative:** `HabitSidebarView.swift` is now dead code until explicitly removed.
