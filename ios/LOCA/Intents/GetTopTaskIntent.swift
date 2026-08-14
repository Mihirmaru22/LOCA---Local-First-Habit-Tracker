import AppIntents
import Foundation
import SwiftData
import SwiftUI

// MARK: - GetTopTaskIntent (Siri Voice Query)

/// Reads today's highest-priority uncompleted task from LOCA's Day Planner.
///
/// Example Voice Invocations:
/// - "Hey Siri, what's my top task today in LOCA?"
/// - "Hey Siri, what should I do next in LOCA?"
struct GetTopTaskIntent: AppIntent {

    static let title: LocalizedStringResource = "Get Top Task"
    static let description = IntentDescription("Find out your top priority scheduled task for today.")

    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        guard let container = try? ModelContainerFactory.makeConfiguredContainer() else {
            return .result(dialog: "Unable to access your PLUTO workspace.") {
                TopTaskSnippetView(taskTitle: "Unable to access workspace", timeString: nil, priority: 0)
            }
        }

        let context = ModelContext(container)
        let today = Calendar.current.startOfDay(for: .now)
        let desc = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.startTime)])

        guard let all = try? context.fetch(desc) else {
            return .result(dialog: "You have no tasks scheduled for today. You're completely clear!") {
                TopTaskSnippetView(taskTitle: "No Tasks Pending", timeString: nil, priority: 0)
            }
        }

        let pendingToday = all.filter { t in
            guard !t.isArchived, !t.isCompleted, t.parentID == nil else { return false }
            if let s = t.startTime { return Calendar.current.isDate(s, inSameDayAs: today) }
            if let d = t.dueDate { return Calendar.current.isDate(d, inSameDayAs: today) }
            return false
        }

        guard let top = pendingToday.first else {
            return .result(dialog: "All tasks for today are complete! Outstanding execution.") {
                TopTaskSnippetView(taskTitle: "All Today's Tasks Completed! 🎉", timeString: nil, priority: 0)
            }
        }

        var timeStr: String? = nil
        if let s = top.startTime {
            timeStr = s.formatted(.dateTime.hour().minute())
        }

        let spokenDialog: IntentDialog
        if let time = timeStr {
            spokenDialog = IntentDialog("Your top task today is \(top.title), scheduled at \(time).")
        } else {
            spokenDialog = IntentDialog("Your top task today is \(top.title).")
        }

        return .result(dialog: spokenDialog) {
            TopTaskSnippetView(taskTitle: top.title, timeString: timeStr, priority: top.priority)
        }
    }
}

struct TopTaskSnippetView: View {
    let taskTitle: String
    let timeString: String?
    let priority: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text(taskTitle)
                    .font(.system(size: 14, weight: .bold))

                if let t = timeString {
                    Text("Scheduled for \(t)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if priority > 0 {
                Image(systemName: "flag.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(priority == 3 ? .red : priority == 2 ? .orange : .blue)
            }
        }
        .padding()
    }
}
