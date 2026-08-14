import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - ToggleTaskWidgetIntent

struct ToggleTaskWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Task"
    static let description = IntentDescription("Mark a task complete or active from the desktop widget.")

    @Parameter(title: "Task ID")
    var taskIDString: String

    init() {}

    init(taskID: UUID) {
        self.taskIDString = taskID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskIDString) else { return .result() }

        do {
            let container = try ModelContainerFactory.makeConfiguredContainer()
            let context = ModelContext(container)

            var desc = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == uuid })
            desc.fetchLimit = 1
            if let task = try context.fetch(desc).first {
                task.completedAt = task.isCompleted ? nil : Date()
                try context.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("Toggle task widget error: \(error)")
        }

        return .result()
    }
}

// MARK: - TodayAgendaEntry

struct TodayAgendaEntry: TimelineEntry {
    let date: Date
    let currentSprintTitle: String
    let currentSprintTime: String
    let currentSprintIcon: String
    let tasks: [WidgetTaskSnapshot]
    let completedCount: Int
    let totalCount: Int
}

struct WidgetTaskSnapshot: Identifiable {
    let id: UUID
    let title: String
    let timeRange: String?
    let isCompleted: Bool
    let priority: Int
}

// MARK: - TodayAgendaProvider

struct TodayAgendaProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayAgendaEntry {
        TodayAgendaEntry(
            date: .now,
            currentSprintTitle: "MORNING SPRINT",
            currentSprintTime: "07:00 – 12:00",
            currentSprintIcon: "sunrise.fill",
            tasks: sampleTasks,
            completedCount: 1,
            totalCount: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayAgendaEntry) -> Void) {
        completion(fetchAgenda())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayAgendaEntry>) -> Void) {
        let entry = fetchAgenda()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func fetchAgenda() -> TodayAgendaEntry {
        let hour = Calendar.current.component(.hour, from: .now)
        let sprintTitle: String
        let sprintTime: String
        let sprintIcon: String

        if hour >= 7 && hour < 12 {
            sprintTitle = "MORNING SPRINT"
            sprintTime = "07:00 – 12:00"
            sprintIcon = "sunrise.fill"
        } else if hour >= 12 && hour < 17 {
            sprintTitle = "AFTERNOON DEEP WORK"
            sprintTime = "12:00 – 17:00"
            sprintIcon = "sun.max.fill"
        } else {
            sprintTitle = "EVENING & WIND DOWN"
            sprintTime = "17:00 – 22:00"
            sprintIcon = "moon.fill"
        }

        guard let container = try? ModelContainerFactory.makeConfiguredContainer() else {
            return TodayAgendaEntry(
                date: .now,
                currentSprintTitle: sprintTitle,
                currentSprintTime: sprintTime,
                currentSprintIcon: sprintIcon,
                tasks: sampleTasks,
                completedCount: 1,
                totalCount: 3
            )
        }

        let context = ModelContext(container)
        let today = Calendar.current.startOfDay(for: .now)
        let desc = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.startTime)])
        guard let all = try? context.fetch(desc) else {
            return TodayAgendaEntry(
                date: .now,
                currentSprintTitle: sprintTitle,
                currentSprintTime: sprintTime,
                currentSprintIcon: sprintIcon,
                tasks: sampleTasks,
                completedCount: 1,
                totalCount: 3
            )
        }

        let todayTasks = all.filter { t in
            guard !t.isArchived, t.parentID == nil else { return false }
            if let start = t.startTime { return Calendar.current.isDate(start, inSameDayAs: today) }
            if let due = t.dueDate { return Calendar.current.isDate(due, inSameDayAs: today) }
            return false
        }

        let taskSnapshots = todayTasks.prefix(5).map { t -> WidgetTaskSnapshot in
            var range: String? = nil
            if let s = t.startTime, let e = t.endTime {
                range = "\(s.formatted(.dateTime.hour().minute())) - \(e.formatted(.dateTime.hour().minute()))"
            }
            return WidgetTaskSnapshot(
                id: t.id,
                title: t.title.isEmpty ? "Untitled Task" : t.title,
                timeRange: range,
                isCompleted: t.isCompleted,
                priority: t.priority
            )
        }

        let completed = todayTasks.filter { $0.isCompleted }.count

        return TodayAgendaEntry(
            date: .now,
            currentSprintTitle: sprintTitle,
            currentSprintTime: sprintTime,
            currentSprintIcon: sprintIcon,
            tasks: Array(taskSnapshots),
            completedCount: completed,
            totalCount: todayTasks.count
        )
    }

    private var sampleTasks: [WidgetTaskSnapshot] {
        [
            WidgetTaskSnapshot(id: UUID(), title: "Deep Work Sprint (60m)", timeRange: "09:00 - 10:00", isCompleted: true, priority: 3),
            WidgetTaskSnapshot(id: UUID(), title: "Review Strategic Goal Checkpoints", timeRange: "11:00 - 11:30", isCompleted: false, priority: 2),
            WidgetTaskSnapshot(id: UUID(), title: "Team Architecture Sync", timeRange: "14:00 - 15:00", isCompleted: false, priority: 1)
        ]
    }
}

// MARK: - TodayAgendaWidget

struct TodayAgendaWidget: Widget {
    static let kind = "com.mihirmaru.loca.TodayAgendaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TodayAgendaProvider()) { entry in
            TodayAgendaWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today Agenda & Sprint")
        .description("Current time sprint block and upcoming scheduled tasks with interactive complete buttons.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - TodayAgendaWidgetView

struct TodayAgendaWidgetView: View {
    let entry: TodayAgendaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Sprint Badge
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: entry.currentSprintIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)

                    Text(entry.currentSprintTitle)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.primary)
                        .tracking(0.6)
                }

                Spacer()

                Text("\(entry.completedCount)/\(entry.totalCount) done")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Divider()

            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No tasks scheduled for today")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 4) {
                    ForEach(entry.tasks) { task in
                        Button(intent: ToggleTaskWidgetIntent(taskID: task.id)) {
                            HStack(spacing: 7) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(task.isCompleted ? .green : .secondary)

                                Text(task.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                    .strikethrough(task.isCompleted)
                                    .lineLimit(1)

                                Spacer()

                                if let range = task.timeRange {
                                    Text(range)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(task.isCompleted ? Color.green.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(4)
    }
}
