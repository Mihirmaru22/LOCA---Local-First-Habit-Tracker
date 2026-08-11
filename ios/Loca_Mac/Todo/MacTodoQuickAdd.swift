import SwiftUI
import SwiftData
import Foundation

// MARK: - MacTodoQuickAdd   (T1 — natural-language quick-add bar)

/// Single text field at the top of the Todo content column.
///
/// The user types a task title, optionally including a date phrase, and presses Return.
/// `TodoNLParser` extracts a due date from the text, then the field is cleared.
///
/// Supported date phrases (case-insensitive, stripped from the saved title):
/// - "today", "tonight"
/// - "tomorrow"
/// - "monday" … "sunday" (next occurrence)
/// - "next [weekday]"
///
/// Examples:
///   "Call dentist tomorrow"       → title="Call dentist", dueDate=tomorrow
///   "Buy milk"                    → title="Buy milk", dueDate=nil (Anytime)
///   "Project review next Monday"  → title="Project review", dueDate=next Monday
struct MacTodoQuickAdd: View {

    @Environment(\.modelContext) private var modelContext
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(DS.Color.textTertiary)
                .font(.body)

            TextField("Add a task…", text: $text)
                .textFieldStyle(.plain)
                .focused($focused)
                .onSubmit(submit)
                .onExitCommand { text = ""; focused = false }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
        .onTapGesture { focused = true }
    }

    private func submit() {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        let (title, due) = TodoNLParser.parse(raw)
        let item = TodoItem(title: title, dueDate: due)
        modelContext.insert(item)
        try? modelContext.save()
        text = ""
    }
}

// MARK: - TodoNLParser

/// Extracts a `Date?` from a natural-language task string and returns the
/// cleaned title with the date phrase removed.
enum TodoNLParser {

    static func parse(_ raw: String) -> (title: String, dueDate: Date?) {
        var words = raw.components(separatedBy: .whitespaces)
        var dueDate: Date? = nil
        var removeIndices = IndexSet()

        let lower = raw.lowercased()

        // "today" / "tonight"
        if let idx = words.firstIndex(where: { ["today", "tonight"].contains($0.lowercased()) }) {
            dueDate = Calendar.current.startOfDay(for: .now)
            removeIndices.insert(idx)
        }
        // "tomorrow"
        else if let idx = words.firstIndex(where: { $0.lowercased() == "tomorrow" }) {
            dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))
            removeIndices.insert(idx)
        }
        // "next [weekday]"
        else if let nextRange = lower.range(of: #"next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)"#,
                                             options: .regularExpression) {
            let matched = String(lower[nextRange])
            let dayName = matched.components(separatedBy: .whitespaces).last ?? ""
            if let date = nextOccurrence(of: dayName, after: 1) {
                dueDate = date
                // remove "next" + weekday
                let matchedWords = matched.components(separatedBy: .whitespaces)
                for (i, w) in words.enumerated() {
                    if matchedWords.contains(w.lowercased()) { removeIndices.insert(i) }
                }
            }
        }
        // bare weekday name
        else if let idx = words.firstIndex(where: { weekdayNames.contains($0.lowercased()) }) {
            if let date = nextOccurrence(of: words[idx].lowercased(), after: 0) {
                dueDate = date
                removeIndices.insert(idx)
            }
        }

        // Remove matched indices and rejoin
        let cleaned = words
            .enumerated()
            .filter { !removeIndices.contains($0.offset) }
            .map { $0.element }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (cleaned.isEmpty ? raw : cleaned, dueDate)
    }

    // MARK: - Helpers

    private static let weekdayNames = ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]

    private static func nextOccurrence(of dayName: String, after minDaysAhead: Int) -> Date? {
        let weekdayMap = ["sunday":1,"monday":2,"tuesday":3,"wednesday":4,
                          "thursday":5,"friday":6,"saturday":7]
        guard let target = weekdayMap[dayName] else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let todayWeekday = cal.component(.weekday, from: today)
        var daysAhead = target - todayWeekday
        if daysAhead <= minDaysAhead { daysAhead += 7 }
        return cal.date(byAdding: .day, value: daysAhead, to: today)
    }
}
