//
//  HabitCheckInsView.swift
//  LOCA
//
//  Phase 14.2 — Check-ins history surface.
//
//  T9:  Binary habits show a toggle in the quick-log header (idempotent
//       tap-to-log / tap-to-undo). Quantitative keeps the amount field.
//  T10: All writes route through CheckInWriter; every path surfaces an
//       alert on save failure.
//  T12: History rows use native .swipeActions — removes the custom
//       DragGesture/fixed-offset SwipeAction implementation.
//

import SwiftUI
import SwiftData

struct HabitCheckInsView: View {

    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingAddCheckIn = false
    @State private var editingEntry: LogEntry? = nil
    @State private var quickLogAmount = ""
    @State private var showWriteError = false

    private var groupedLogs: [(date: Date, entries: [LogEntry])] {
        let logs = board.logs ?? []
        let calendar = Calendar.current

        var grouped: [Date: [LogEntry]] = [:]
        for log in logs {
            let dayStart = calendar.startOfDay(for: log.timestamp)
            grouped[dayStart, default: []].append(log)
        }

        return grouped
            .map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    private var isToday: (Date) -> Bool {
        { Calendar.current.isDateInToday($0) }
    }

    // Static formatters: DateFormatter init is expensive; one per format per process is enough.
    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private func dateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return Self.mediumDateFormatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        Self.shortTimeFormatter.string(from: date)
    }

    private var parsedQuickLogAmount: Double? {
        Double(quickLogAmount.trimmingCharacters(in: .whitespaces))
    }

    // Show quick-log only when already logging today or completely empty.
    private var showQuickLog: Bool {
        groupedLogs.isEmpty || groupedLogs.first?.date == Calendar.current.startOfDay(for: .now)
    }

    // True when today already has at least one entry (used for binary toggle label).
    private var isCheckedInToday: Bool {
        (board.logs ?? []).contains(where: { Calendar.current.isDateInToday($0.timestamp) })
    }

    var body: some View {
        List {
            // MARK: Today Status Card
            if let todayGroup = groupedLogs.first(where: { isToday($0.date) }) {
                Section {
                    LOCACard {
                        todayStatusContent(group: todayGroup)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: DS.Space.sm, leading: DS.Space.lg, bottom: DS.Space.xs, trailing: DS.Space.lg))
                }
            }

            // MARK: Quick Log
            if showQuickLog {
                Section {
                    LOCACard {
                        quickLogContent
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: DS.Space.xs, leading: DS.Space.lg, bottom: DS.Space.sm, trailing: DS.Space.lg))
                }
            }

            // MARK: History
            if groupedLogs.isEmpty {
                Section {
                    VStack(spacing: DS.Space.md) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("No check-ins yet")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(DS.Space.xxxl)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } else {
                ForEach(groupedLogs, id: \.date) { group in
                    Section {
                        ForEach(group.entries, id: \.id) { entry in
                            entryRowView(entry: entry)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) { deleteEntry(entry) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button { editEntry(entry) } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(ColorPalette[4])
                                    Button { duplicateEntry(entry) } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(DS.Color.textSecondary.opacity(0.6))
                                }
                        }
                    } header: {
                        Text(dateLabel(group.date))
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textSecondary)
                            .tracking(0.5)
                            .textCase(nil)
                            .padding(.leading, DS.Space.sm)
                    }
                }
            }

            // Clearance for the floating button.
            Color.clear
                .frame(height: DS.Space.xxxl + DS.Space.xl)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .alert("Couldn't Save Check-in", isPresented: $showWriteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The check-in couldn't be saved. Please try again.")
        }
        .sheet(isPresented: $showingAddCheckIn) {
            AddCheckInSheetView(board: board)
        }
        .sheet(item: $editingEntry) { entry in
            EditCheckInSheetView(entry: entry, board: board)
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingAddCheckIn = true }) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(ColorPalette[board.colorIndex])
                    .clipShape(Circle())
            }
            .padding(DS.Space.lg)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func todayStatusContent(group: (date: Date, entries: [LogEntry])) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(DS.Text.caption)
                    .foregroundStyle(ColorPalette[board.colorIndex])
                Text("TODAY")
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
            }

            let todayTotal = group.entries.reduce(0.0) { $0 + $1.value }
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                ValueText(
                    todayTotal.formatted(.number.precision(.fractionLength(0...1))),
                    font: DS.Text.value
                )
                .foregroundStyle(
                    todayTotal >= board.effectiveTarget
                        ? ColorPalette[board.colorIndex]
                        : DS.Color.textSecondary
                )

                if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                    Text("\(group.entries.count) \(group.entries.count == 1 ? "entry" : "entries") • \(unitLabel)")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var quickLogContent: some View {
        if board.metric == .binary {
            // Binary: idempotent toggle (tap to log, tap again to undo).
            Button(action: quickLog) {
                HStack(spacing: DS.Space.md) {
                    Image(systemName: isCheckedInToday ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isCheckedInToday ? ColorPalette[board.colorIndex] : DS.Color.textSecondary)
                    Text(isCheckedInToday ? "Done today — tap to undo" : "Mark as done")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        } else {
            // Quantitative: amount field + log button.
            HStack(spacing: DS.Space.md) {
                TextField("Add amount", text: $quickLogAmount)
                    .font(DS.Text.body)
                    .decimalKeyboard()

                if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                    Text(unitLabel)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Button(action: quickLog) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                }
                .disabled((parsedQuickLogAmount ?? 0) <= 0)
            }
        }
    }

    @ViewBuilder
    private func entryRowView(entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.md) {
                Text(formattedTime(entry.timestamp))
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                Spacer()

                HStack(spacing: DS.Space.xs) {
                    ValueText(
                        entry.value.formatted(.number.precision(.fractionLength(0...1))),
                        font: DS.Text.body
                    )
                    .foregroundStyle(
                        entry.value >= board.effectiveTarget
                            ? ColorPalette[board.colorIndex]
                            : DS.Color.textPrimary
                    )

                    if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                        Text(unitLabel)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }

            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    // MARK: - Actions

    private func quickLog() {
        do {
            if board.metric == .binary {
                try CheckInWriter.toggleBinary(board: board, context: modelContext)
            } else {
                guard let amount = parsedQuickLogAmount, amount > 0 else { return }
                try CheckInWriter.insert(value: amount, board: board, context: modelContext)
                quickLogAmount = ""
            }
            triggerHaptic()
        } catch {
            showWriteError = true
        }
    }

    private func editEntry(_ entry: LogEntry) {
        editingEntry = entry
    }

    private func deleteEntry(_ entry: LogEntry) {
        do {
            try CheckInWriter.delete(entry, board: board, context: modelContext)
        } catch {
            showWriteError = true
        }
    }

    private func duplicateEntry(_ entry: LogEntry) {
        do {
            try CheckInWriter.insert(value: entry.value, note: entry.note, board: board, context: modelContext)
            triggerHaptic()
        } catch {
            showWriteError = true
        }
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Preview

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
        container.mainContext.insert(habit)

        for daysAgo in 0..<5 {
            if let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) {
                let entry = LogEntry(timestamp: date, value: Double.random(in: 3...8), boardID: habit.id, board: habit)
                container.mainContext.insert(entry)
            }
        }

        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return HabitCheckInsView(board: habit)
        .modelContainer(container)
}
