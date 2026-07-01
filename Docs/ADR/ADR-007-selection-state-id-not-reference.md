# ADR-007 — Navigation Selection State Holds `HabitBoard.id`, Not a Model Reference

**Status:** Adopted
**Date:** 2026-06-30

## Context

`NavigationSplitView`'s sidebar/detail pattern requires some form of selection
state to determine what the detail column shows. Two implementation choices
were available for `RootNavigationView`:

**Option A:** `@State private var selectedBoard: HabitBoard?` — hold the live
model object directly.

**Option B:** `@State private var selectedBoardID: UUID?` — hold the board's
identifier, re-resolving the live object from the current `@Query` result set
on every body evaluation.

Option A is the more obvious, less code choice, and is what most introductory
SwiftUI material demonstrates for simple, non-persisted selection state.

## Decision

Option B. `RootNavigationView` holds `selectedBoardID: UUID?` and resolves it
against `activeBoards` (the live `@Query` result) via `activeBoards.first { $0.id == id }`
on every render.

SwiftData `@Model` objects are tied to a `ModelContext`, and that context's
contents can change underneath a held reference — most relevantly here, via a
CloudKit-driven background merge, or the board being archived (and therefore
dropped from `activeBoards` by `HabitBoard.activePredicate`) while it remains
selected. A held `HabitBoard?` reference does not automatically become `nil`
when the object it points to is invalidated or filtered out of the active set;
re-deriving the selection from the current query result on every render makes
"the selected board no longer exists in the active set" resolve naturally to
`nil` — `EmptyDetailPlaceholderView` — with no special-case invalidation handling
required anywhere.

This is also the pattern Apple's own SwiftData sample code and several WWDC
sessions on `NavigationSplitView` + SwiftData recommend: bind selection to an
`Identifiable` value's `ID`, not the object itself.

## Consequences

**Positive:**
- No stale-reference risk if the selected board is archived, deleted, or
  affected by a CloudKit merge while selected.
- `selectedBoardID: UUID?` is trivially `Sendable` and `Equatable`, with none of
  the actor-isolation questions a held `@Model` reference would raise in a
  Swift 6 strict-concurrency codebase.
- The resolution lookup (`activeBoards.first { $0.id == id }`) doubles as the
  invalidation check — no separate "is my selection still valid" logic needed.

**Negative:**
- A linear scan over `activeBoards` runs on every body evaluation rather than
  an O(1) reference dereference. Accepted as negligible: `activeBoards` is
  bounded by realistic habit counts (tens, not thousands) — this is not a
  `LogEntry`-scale dataset.
- Every consumer of "the selected board" must perform this same lookup or
  receive an already-resolved `HabitBoard?` from `RootNavigationView`, rather
  than reading a single `@State` property directly. `RootNavigationView`
  performs the resolution once per render and passes the resolved object
  down to `HabitDetailView`, so this cost is paid in exactly one place.
