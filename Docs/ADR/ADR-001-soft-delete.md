# ADR-001 — Soft Delete via `archivedAt`

**Status:** Adopted  
**Date:** 2025-06-28  

## Context

SwiftData's `@Relationship(deleteRule: .cascade)` issues `modelContext.delete()` on associated child records when a parent is deleted. When the parent-child store is backed by CloudKit, deletion order during sync propagation is not guaranteed. A device that receives the parent (`HabitBoard`) tombstone before all associated child (`LogEntry`) tombstones will hold orphaned `LogEntry` records indefinitely — SwiftData will not re-issue the delete, and CloudKit will not re-deliver the tombstone once missed.

Additionally, `LogEntry` records represent irreplaceable user data (daily habit logs). Hard deletion of a `HabitBoard` that a user "deleted by mistake" permanently destroys that history with no recovery path.

## Decision

`HabitBoard` is never hard-deleted. Instead, it carries a `archivedAt: Date?` property. Setting this property to `Date()` and saving constitutes the only permitted deletion path.

The relationship delete rule is `.nullify` (not `.cascade`). If a `HabitBoard` is ever hard-deleted by accident, associated `LogEntry` records lose their `board` back-reference but remain in the store — they do not cascade-delete.

All active-board `@Query` predicates filter on `archivedAt == nil`.

The canonical deletion method:

```swift
extension HabitBoard {
    func archive(in context: ModelContext) throws {
        let previousArchivedAt = archivedAt
        archivedAt = Date()
        do {
            try context.save()
        } catch {
            archivedAt = previousArchivedAt
            throw PersistenceError.saveFailed(underlying: error)
        }
    }
}
```

## Consequences

**Positive:**
- No CloudKit orphan accumulation from out-of-order tombstone delivery.
- User data (logs) survives a board "deletion" and can be restored if desired.
- The deletion path is explicit and auditable — a grep for `modelContext.delete()` with a `HabitBoard` argument is a review violation.

**Negative:**
- Archived boards accumulate in the store indefinitely unless a purge mechanism is added later.
- `@Query` predicates must always include `archivedAt == nil` — omitting it silently surfaces archived boards. A canonical `static var activePredicate` mitigates this (tracked, deferred to Phase 4).
- Storage grows without bound for heavy users who archive many boards. Acceptable for v1.
