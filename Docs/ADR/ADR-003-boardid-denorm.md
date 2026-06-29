# ADR-003 — `boardID: UUID` Denormalization on `LogEntry`

**Status:** Adopted  
**Date:** 2025-06-28  

## Context

To display a board's heatmap, `HeatmapDataProvider` needs all `LogEntry` records for a specific `HabitBoard`, filtered by date range. The natural SwiftData predicate would traverse the optional relationship:

```swift
#Predicate<LogEntry> { $0.board?.id == boardID && $0.timestamp >= start }
```

On iOS 17, SwiftData relationship keypath predicates that traverse optional to-one relationships (`$0.board?.id`) can silently return empty result sets. This is not a compile error or a runtime crash — the predicate evaluates without error but returns zero records. This has been observed in production SwiftData usage on iOS 17.0–17.2.

## Decision

`LogEntry` gains a denormalized `boardID: UUID` property that is a copy of `board!.id` set at insertion time and never mutated:

```swift
var boardID: UUID = UUID()  // default satisfies CloudKit; always overwritten by init
```

All `@Predicate` expressions that filter `LogEntry` by board use this property:

```swift
#Predicate<LogEntry> { $0.boardID == boardID && $0.timestamp >= start }
```

No relationship traversal occurs in any predicate.

**Contract:** `boardID` must equal `board!.id` at all times. The only permitted insertion path is `LogEntry(boardID: board.id, board: board)`. Enforced by the designated initializer making `boardID` a required, non-defaulted parameter.

## Consequences

**Positive:**
- Predicate evaluation is reliable on iOS 17 — no relationship traversal, no silent empty results.
- The denormalization is self-documenting: every `LogEntry` carries its board's identity directly, which also survives transient orphan states during CloudKit sync.

**Negative:**
- `boardID` and `board.id` can theoretically diverge if `board` is replaced (impossible in the current model — boards are never re-parented) or if someone bypasses the designated initializer.
- Extra UUID stored per `LogEntry` — 16 bytes per record, negligible for typical dataset sizes.
- Workaround is load-bearing: if Apple fixes the predicate bug in a future SwiftData version, this denormalization remains harmless but becomes redundant.
