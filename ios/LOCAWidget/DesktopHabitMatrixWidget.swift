import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

// MARK: - ToggleHabitWidgetIntent

struct ToggleHabitWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Habit"
    static let description = IntentDescription("Check off a habit directly from the desktop widget.")

    @Parameter(title: "Habit ID")
    var habitIDString: String

    init() {}

    init(habitID: UUID) {
        self.habitIDString = habitID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitIDString) else {
            return .result()
        }

        do {
            let container = try ModelContainerFactory.makeConfiguredContainer()
            let context = ModelContext(container)

            var desc = FetchDescriptor<HabitBoard>(predicate: #Predicate { $0.id == uuid })
            desc.fetchLimit = 1
            if let board = try context.fetch(desc).first {
                let today = Calendar.current.startOfDay(for: .now)
                let existing = board.activeLogs.first { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }

                if let log = existing {
                    context.delete(log)
                } else {
                    let entry = LogEntry(timestamp: .now, value: 1.0, boardID: board.id)
                    entry.board = board
                    context.insert(entry)
                }
                try context.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("Widget intent error: \(error)")
        }

        return .result()
    }
}

// MARK: - DesktopHabitMatrixEntry

struct DesktopHabitMatrixEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabitSnapshot]
}

struct WidgetHabitSnapshot: Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let isCompletedToday: Bool
    let streak: Int
    let colorIndex: Int
}

// MARK: - DesktopHabitMatrixProvider

struct DesktopHabitMatrixProvider: TimelineProvider {
    func placeholder(in context: Context) -> DesktopHabitMatrixEntry {
        DesktopHabitMatrixEntry(date: .now, habits: sampleHabits)
    }

    func getSnapshot(in context: Context, completion: @escaping (DesktopHabitMatrixEntry) -> Void) {
        completion(DesktopHabitMatrixEntry(date: .now, habits: fetchHabits()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DesktopHabitMatrixEntry>) -> Void) {
        let entry = DesktopHabitMatrixEntry(date: .now, habits: fetchHabits())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func fetchHabits() -> [WidgetHabitSnapshot] {
        guard let container = try? ModelContainerFactory.makeConfiguredContainer() else {
            return sampleHabits
        }
        let context = ModelContext(container)
        let desc = FetchDescriptor<HabitBoard>(sortBy: [SortDescriptor(\.createdAt)])
        guard let boards = try? context.fetch(desc) else { return sampleHabits }

        let today = Calendar.current.startOfDay(for: .now)
        return boards.filter { $0.archivedAt == nil }.prefix(6).map { b in
            let done = b.activeLogs.contains { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
            return WidgetHabitSnapshot(
                id: b.id,
                title: b.name,
                icon: "checkmark",
                isCompletedToday: done,
                streak: b.currentStreak,
                colorIndex: b.colorIndex
            )
        }
    }

    private var sampleHabits: [WidgetHabitSnapshot] {
        [
            WidgetHabitSnapshot(id: UUID(), title: "Morning Meditation", icon: "sparkles", isCompletedToday: true, streak: 14, colorIndex: 0),
            WidgetHabitSnapshot(id: UUID(), title: "Cold Plunge & Workout", icon: "figure.run", isCompletedToday: true, streak: 28, colorIndex: 1),
            WidgetHabitSnapshot(id: UUID(), title: "Deep Focus Coding", icon: "laptopcomputer", isCompletedToday: false, streak: 7, colorIndex: 2),
            WidgetHabitSnapshot(id: UUID(), title: "Read 20 Pages", icon: "book.fill", isCompletedToday: false, streak: 12, colorIndex: 3)
        ]
    }
}

// MARK: - DesktopHabitMatrixWidget

struct DesktopHabitMatrixWidget: Widget {
    static let kind = "com.mihirmaru.loca.DesktopHabitMatrixWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: DesktopHabitMatrixProvider()) { entry in
            DesktopHabitMatrixView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Desktop Habit Matrix")
        .description("Interactive clickable habit dots directly on your macOS desktop background.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - DesktopHabitMatrixView

struct DesktopHabitMatrixView: View {
    let entry: DesktopHabitMatrixEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("HABIT MATRIX")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(.secondary)

                Spacer()

                let doneCount = entry.habits.filter { $0.isCompletedToday }.count
                Text("\(doneCount)/\(entry.habits.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Divider()

            if family == .systemSmall {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(entry.habits.prefix(4)) { h in
                        Button(intent: ToggleHabitWidgetIntent(habitID: h.id)) {
                            VStack(spacing: 3) {
                                Image(systemName: h.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(h.isCompletedToday ? .green : .secondary)

                                Text(h.title)
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(h.isCompletedToday ? Color.green.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(entry.habits.prefix(4)) { h in
                        Button(intent: ToggleHabitWidgetIntent(habitID: h.id)) {
                            HStack(spacing: 8) {
                                Image(systemName: h.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(h.isCompletedToday ? .green : .secondary)

                                Text(h.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(h.isCompletedToday ? .secondary : .primary)
                                    .lineLimit(1)

                                Spacer()

                                if h.streak > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.orange)
                                        Text("\(h.streak)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(h.isCompletedToday ? Color.green.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(4)
    }
}
