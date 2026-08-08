import SwiftData
import Foundation

// MARK: - JournalNote

/// A free-form daily note written in the Mac Journal → Collect surface.
///
/// One note per calendar day is the intended pattern (the write surface
/// auto-loads today's note on entry), but nothing enforces uniqueness —
/// CloudKit forbids unique constraints. If the user writes multiple notes
/// in one day, all appear in the collect list in createdAt order.
///
/// Notes are independent of `LogEntry`: they capture general daily reflection,
/// not habit-specific check-in context. Habit-specific notes live on
/// `LogEntry.note`; daily life notes live here.
@Model
final class JournalNote {

    var id:         UUID    = UUID()
    var date:       Date    = Date()   // day the note was written
    var text:       String  = ""
    var archivedAt: Date?   = nil

    var isArchived: Bool { archivedAt != nil }

    init(date: Date = Date(), text: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
    }
}
