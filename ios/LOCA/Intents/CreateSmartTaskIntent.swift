import AppIntents
import Foundation
import SwiftData
import SwiftUI

// MARK: - CreateSmartTaskIntent (Siri Voice Smart Task Creator)

/// Adds a new task directly into LOCA with natural language date, time, and tag parsing.
///
/// Example Voice Invocations:
/// - "Hey Siri, add a task in LOCA: Deep Work tomorrow at 9am for 1h #work"
/// - "Hey Siri, new task in LOCA: Gym tonight !!"
struct CreateSmartTaskIntent: AppIntent {

    static let title: LocalizedStringResource = "Add Task"
    static let description = IntentDescription("Add a new task to your Today schedule with natural language date and time recognition.")

    @Parameter(title: "Task Description")
    var taskDescription: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskDescription) to PLUTO")
    }

    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        guard let container = try? ModelContainerFactory.makeConfiguredContainer() else {
            return .result(dialog: "Unable to access PLUTO database.") {
                SmartTaskAddedSnippetView(title: taskDescription, time: nil)
            }
        }

        let context = ModelContext(container)
        let parsed = LocaNeuralEngine.parseSmartTask(taskDescription)

        let item = TodoItem(
            title: parsed.cleanTitle,
            dueDate: parsed.dueDate ?? Calendar.current.startOfDay(for: .now),
            priority: parsed.priority,
            startTime: parsed.startTime,
            durationMinutes: parsed.durationMinutes > 0 ? parsed.durationMinutes : 30,
            category: parsed.detectedTags.first
        )

        context.insert(item)
        try? context.save()

        let timeStr = parsed.startTime?.formatted(.dateTime.hour().minute())
        let dialog = IntentDialog("Added '\(parsed.cleanTitle)' to your PLUTO tasks.")

        return .result(dialog: dialog) {
            SmartTaskAddedSnippetView(title: parsed.cleanTitle, time: timeStr)
        }
    }
}

struct SmartTaskAddedSnippetView: View {
    let title: String
    let time: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))

                if let t = time {
                    Text("Scheduled for \(t)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("SAVED")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12), in: Capsule())
        }
        .padding()
    }
}
