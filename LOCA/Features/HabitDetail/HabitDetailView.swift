import SwiftUI
import SwiftData

// MARK: - HabitDetailView

struct HabitDetailView: View {

    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingEditSheet = false

    @Query private var logs: [LogEntry]

    init(board: HabitBoard) {
        self.board = board
        let boardID = board.id
        _logs = Query(
            filter: #Predicate<LogEntry> { $0.boardID == boardID },
            sort: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    private var hasLogs: Bool { !logs.isEmpty }

    private var journalSections: [JournalDaySection] {
        JournalGrouping.groupByDay(logs)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                // 1 — Current status (hero)
                statusHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    .animation(
                        reduceMotion ? .linear(duration: 0.1) : .rippleSettle,
                        value: todaysTotal
                    )

                Divider().padding(.horizontal, 20)

                // 2 — History heatmap
                historyBlock
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                // 3 — Statistics (only when there's data)
                if hasLogs {
                    statisticsBlock
                        .padding(.top, 4)
                        .padding(.bottom, 8)

                    Divider().padding(.horizontal, 20)

                    // 4 — Journal
                    journalBlock
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(board.name)
        .largeNavigationTitleDisplay()
        .safeAreaInset(edge: .bottom) {
            CheckInButton(board: board)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.thinMaterial)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditSheet = true }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board))
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            // Large ring
            let total    = todaysTotal
            let fraction = progressFraction(for: total)
            let accent   = ColorPalette[board.colorIndex]

            ZStack {
                ArcProgressView(fraction: fraction, color: accent, size: 64)
                percentOrCheck(fraction: fraction, accent: accent)
            }
            .frame(width: 64, height: 64)

            // Identity + progress
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                    Text(board.name)
                        .font(.title3.bold())
                        .lineLimit(2)
                }

                Text(todayProgressLine(total: total, fraction: fraction))
                    .font(.subheadline)
                    .foregroundStyle(fraction >= 1 ? accent : .primary)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(streakSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func percentOrCheck(fraction: Double, accent: Color) -> some View {
        switch board.metric {
        case .binary:
            if fraction >= 1 {
                Image(systemName: "checkmark")
                    .font(.title.weight(.bold))
                    .foregroundStyle(accent)
            }
        case .quantitative:
            Text("\(Int((fraction * 100).rounded()))%")
                .font(.title3.weight(.bold).design(.rounded))
                .foregroundStyle(accent)
        }
    }

    // MARK: - History Block

    private var historyBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.headline)
                .padding(.horizontal, 20)

            if hasLogs {
                HeatmapView(board: board)
                    .padding(.horizontal, 8)
            } else {
                Label(
                    "Log \(board.name) to start building your history.",
                    systemImage: "square.grid.3x3"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Statistics Block

    private var statisticsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistics")
                .font(.headline)
                .padding(.horizontal, 20)
            AnalyticsCardsView(board: board)
                .padding(.horizontal, 12)
        }
        .padding(.top, 12)
    }

    // MARK: - Journal Block

    private var journalBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Activity")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ForEach(journalSections) { section in
                VStack(alignment: .leading, spacing: 0) {
                    Text(JournalGrouping.headerTitle(for: section.dayStart))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    ForEach(section.entries) { entry in
                        JournalEntryRow(entry: entry, board: board)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                            .contextMenu {
                                Button(role: .destructive) { delete(entry) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        if entry.id != section.entries.last?.id {
                            Divider().padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var todaysTotal: Double {
        logs.filter { $0.timestamp.isToday() }.reduce(0) { $0 + $1.value }
    }

    private func progressFraction(for total: Double) -> Double {
        max(0, min(1, total / board.effectiveTarget))
    }

    private func todayProgressLine(total: Double, fraction: Double) -> String {
        switch board.metric {
        case .binary:
            return fraction >= 1 ? "Done today ✓" : "Check off daily"
        case .quantitative:
            let unit = board.unitLabel.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
            let done = total.formatted(.number.precision(.fractionLength(0...1)))
            let goal = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            return fraction >= 1
                ? "\(done)\(unit) logged · Goal met ✓"
                : "\(done) / \(goal)\(unit) today"
        }
    }

    private var streakSubtitle: String {
        let s = board.currentStreak
        let b = board.longestStreak
        let streak = s == 1 ? "1 day streak" : "\(s) day streak"
        return b > s ? "\(streak) · Best: \(b)d" : streak
    }

    private func delete(_ entry: LogEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private var streakText: String {
        board.currentStreak == 1 ? "1 day streak" : "\(board.currentStreak) day streak"
    }
}

// MARK: - Previews

@MainActor
private func makeDetailWithHistoryContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let board = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "mi", colorIndex: 0)
    board.currentStreak = 5; board.longestStreak = 12
    container.mainContext.insert(board)
    let calendar = Calendar.current
    for (i, note) in ["Felt great.", nil, "Rain but worth it."].enumerated() {
        if let day = calendar.date(byAdding: .day, value: -i, to: .now) {
            container.mainContext.insert(
                LogEntry(timestamp: day, value: Double.random(in: 2...6),
                         note: note, boardID: board.id, board: board)
            )
        }
    }
    try? container.mainContext.save()
    return (container, board)
}

#Preview("With History") {
    let (container, board) = makeDetailWithHistoryContainer()
    return NavigationStack { HabitDetailView(board: board) }
        .modelContainer(container)
}
