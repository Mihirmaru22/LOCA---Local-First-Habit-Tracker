import SwiftData
import Foundation

// MARK: - TodoBucket

/// The display bucket a task falls into based on its due date.
enum TodoBucket: String, Codable, CaseIterable {
    case today    = "Today"
    case upcoming = "Upcoming"
    case anytime  = "Anytime"
}

// MARK: - TodoItem

/// A single user-authored task.
///
/// ## Design principles
/// - **Soft delete only.** Set `archivedAt` instead of calling `modelContext.delete()`.
/// - **Completion is reversible.** Set `completedAt = nil` to un-complete (T4).
/// - **CloudKit-compatible.** Every stored property has a default value or is Optional.
/// - **Append-only completion pattern.** To un-complete, null out `completedAt` rather
///   than deleting a completion record; simpler than the Android fact-deletion approach
///   and correct for SwiftData's last-write-wins CloudKit sync.
@Model
final class TodoItem {

    // MARK: Identity

    var id:        UUID   = UUID()
    var createdAt: Date   = Date()

    // MARK: Content

    var title:   String  = ""
    var notes:   String? = nil
    var dueDate: Date?   = nil

    // MARK: Priority (0 = none, 1 = low, 2 = medium, 3 = high)

    var priority: Int = 0

    // MARK: Day-planner scheduling (optional — nil = not on the timeline)

    /// When set, the task is placed on the day-planner timeline at this exact
    /// date + time. `nil` means the task lives only in the bucket list (T2) or,
    /// when due today, in the planner's Unscheduled tray. CloudKit-safe (Optional).
    var startTime: Date? = nil

    /// Length of the scheduled block in minutes. 0 = a point in time (no range).
    var durationMinutes: Int = 0

    /// SF Symbol name shown in the timeline icon bubble. `nil` falls back to a
    /// default glyph. Lets a planned block read at a glance (alarm, envelope…).
    var iconName: String? = nil

    // MARK: Lifecycle

    /// Non-nil when the task is done. Nullify to un-complete (T4).
    var completedAt: Date? = nil

    /// Non-nil when the task is archived (soft-deleted). Never shown in UI.
    var archivedAt: Date? = nil

    // MARK: - Computed

    var isCompleted: Bool { completedAt != nil }
    var isArchived:  Bool { archivedAt  != nil }

    /// True when the task is placed on the day-planner timeline.
    var isScheduled: Bool { startTime != nil }

    /// End of the scheduled block, or `nil` when unscheduled. A zero-duration
    /// block returns its start time (a point on the timeline).
    var endTime: Date? {
        guard let start = startTime else { return nil }
        return Calendar.current.date(byAdding: .minute,
                                     value: max(0, durationMinutes),
                                     to: start)
    }

    /// Which display bucket this task belongs to.
    ///
    /// - **Today**: dueDate is today or already past (overdue).
    /// - **Upcoming**: dueDate exists and is in the future.
    /// - **Anytime**: no due date set.
    var bucket: TodoBucket {
        guard let due = dueDate else { return .anytime }
        let today = Calendar.current.startOfDay(for: .now)
        let dueDay = Calendar.current.startOfDay(for: due)
        return dueDay <= today ? .today : .upcoming
    }

    // MARK: - Init

    init(
        id:              UUID    = UUID(),
        title:           String  = "",
        notes:           String? = nil,
        dueDate:         Date?   = nil,
        priority:        Int     = 0,
        startTime:       Date?   = nil,
        durationMinutes: Int     = 0,
        iconName:        String? = nil,
        completedAt:     Date?   = nil,
        archivedAt:      Date?   = nil
    ) {
        self.id              = id
        self.title           = title
        self.notes           = notes
        self.dueDate         = dueDate
        self.priority        = priority
        self.startTime       = startTime
        self.durationMinutes = durationMinutes
        self.iconName        = iconName
        self.completedAt     = completedAt
        self.archivedAt      = archivedAt
    }
}
