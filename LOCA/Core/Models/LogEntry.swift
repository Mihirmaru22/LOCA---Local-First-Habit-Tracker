import SwiftData
import Foundation

// MARK: - LogEntry

/// A single recorded instance of a habit being performed.
///
/// `LogEntry` records are **append-only**. Once inserted and saved, a `LogEntry`
/// is never mutated. Deletion uses soft-delete (set `archivedAt` to current date)
/// rather than hard-delete. This design serves three purposes:
///
/// 1. **CloudKit conflict safety.** CloudKit's last-write-wins merge resolves
///    concurrent writes by discarding one. For a mutable log record, this silently
///    drops user-entered data with no error. An append-only model means every
///    write is a new record; nothing is ever overwritten.
///
/// 2. **Audit trail.** Soft-deleted entries remain in the database, enabling
///    5-second undo windows and historical audits. Hard-delete would lose this
///    information permanently.
///
/// 3. **Orphan containment.** If the owning `HabitBoard` is archived before all
///    associated `LogEntry` records propagate through CloudKit, the entries become
///    temporarily orphaned (board == nil). Because entries are never hard-deleted,
///    this state is benign and self-corrects when sync completes.
///
/// ## Denormalized `boardID` (ADR-003)
/// `boardID` is a copy of `board?.id` stored directly on `LogEntry`. This enables
/// `#Predicate<LogEntry>` expressions to filter by board using a direct value
/// comparison (`$0.boardID == id`) rather than an optional relationship keypath
/// (`$0.board?.id == id`), which returns empty results on iOS 17 due to a SwiftData
/// framework limitation. See ADR-003.
///
/// **Contract:** `boardID` must equal `board!.id` at all times.
/// The only permitted insertion path is `LogEntry(boardID: board.id, board: board)`.
///
/// ## CloudKit Sync Constraints
/// - No `@Attribute(.unique)` is used.
/// - All properties carry default values or are `Optional`.
/// - The `board` back-reference is `Optional` to tolerate transient orphan states.
@Model
final class LogEntry {

    // MARK: - Identity

    /// Stable identifier for this log entry.
    var id: UUID = UUID()

    // MARK: - Payload

    /// The exact moment this entry was recorded.
    ///
    /// Full timestamp (not date-only) preserves time-of-day information used by
    /// `JournalListView` and for ordering multiple same-day entries.
    var timestamp: Date = Date()

    /// The amount logged for this entry.
    ///
    /// For binary habits: always `1.0`.
    /// For quantitative habits: the numeric contribution in `board.unitLabel` units.
    /// Multiple entries on the same day are summed to compute the daily total.
    var value: Double = 1.0

    /// An optional user-written note attached to this check-in.
    ///
    /// Entries with a non-`nil` `note` surface in `JournalListView`. The presence
    /// of a note does not affect streak or heatmap computation.
    var note: String? = nil

    // MARK: - Soft Delete

    /// Timestamp when this entry was marked as deleted (soft delete).
    ///
    /// When `nil` (default): Entry is active and visible in all UI.
    /// When set to a `Date`: Entry is logically deleted but retained in database
    /// for audit trail and undo operations (5-second undo window).
    ///
    /// All queries exclude entries where `archivedAt != nil`.
    /// To restore a soft-deleted entry, set `archivedAt = nil` and save.
    var archivedAt: Date? = nil

    // MARK: - Denormalized Board Reference

    // MARK: boardID Denormalization (ADR-003)
    //
    // `boardID` is a direct copy of `board?.id`, stored on `LogEntry` so that
    // `@Query` predicates can filter entries by board using a plain value comparison:
    //
    //   #Predicate<LogEntry> { $0.boardID == someID && $0.timestamp >= start }
    //
    // On iOS 17, SwiftData relationship keypath predicates such as
    // `$0.board?.id == someID` can silently return empty result sets. The
    // denormalized `boardID` is the workaround. See ADR-003.
    //
    // Maintenance: `boardID` is set once at insertion and never mutated.
    // The only permitted insertion path passes both `boardID: board.id` and
    // `board: board` to keep the denormalized value and the relationship in sync.

    /// Copy of the owning `HabitBoard.id`.
    ///
    /// Use this property — never `board?.id` — in all `#Predicate` expressions
    /// that filter `LogEntry` by board. See ADR-003.
    ///
    /// The property default (`UUID()`) satisfies CloudKit's "all properties must
    /// have a default" requirement. In practice it is always overwritten by the
    /// designated initialiser, which requires `boardID` as a non-defaulted parameter.
    var boardID: UUID = UUID()

    // MARK: - Relationship

    /// The owning `HabitBoard`. `Optional` to tolerate transient CloudKit orphan states.
    ///
    /// A device may receive `LogEntry` records via CloudKit before the corresponding
    /// `HabitBoard` record during first-install or post-conflict sync. The entry's
    /// `boardID` remains valid and the relationship resolves once the board record arrives.
    ///
    /// No `@Relationship` attribute on this side. SwiftData's bidirectional relationship
    /// model requires `inverse:` to be declared on exactly **one** side of a relationship
    /// pair — `HabitBoard.logs` is that side (`@Relationship(deleteRule: .nullify,
    /// inverse: \LogEntry.board)`). A prior revision declared `inverse:` on both sides,
    /// each pointing at the other — a genuine circular dependency during macro expansion
    /// (resolving `HabitBoard.logs`'s macro required resolving `LogEntry.board`'s type,
    /// whose own macro required resolving `HabitBoard.logs` in turn), which the compiler
    /// correctly rejected. This plain, attribute-free declaration is the correct pattern:
    /// SwiftData resolves this property as the inverse counterpart via `HabitBoard.logs`'s
    /// keypath, with no separate declaration needed here.
    var board: HabitBoard? = nil

    // MARK: - Initialiser

    /// Creates a new `LogEntry` for a specific `HabitBoard`.
    ///
    /// Both `boardID` and `board` must refer to the same `HabitBoard` instance.
    /// Passing mismatched values violates the denormalization contract (ADR-003)
    /// and produces incorrect `@Query` predicate results.
    ///
    /// Typical call site (inside a check-in action on `@MainActor`):
    /// ```swift
    /// let entry = LogEntry(value: value, note: note, boardID: board.id, board: board)
    /// context.insert(entry)
    /// board.updateStreak(using: .current)
    /// try context.save()
    /// ```
    ///
    /// - Parameters:
    ///   - id: Stable UUID. Defaults to a new `UUID()`.
    ///   - timestamp: Log time. Defaults to `Date()` (now).
    ///   - value: Logged amount. Use `1.0` for binary habits.
    ///   - note: Optional journal text. Pass `nil` for a note-free entry.
    ///   - boardID: The `id` of the owning `HabitBoard`. Required; no default.
    ///   - board: The owning `HabitBoard` object. Pass `nil` only in test fixtures
    ///            where the relationship is set separately.
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        value: Double = 1.0,
        note: String? = nil,
        boardID: UUID,
        board: HabitBoard? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.note = note
        self.boardID = boardID
        self.board = board
    }
}
