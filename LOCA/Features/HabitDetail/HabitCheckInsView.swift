//
//  HabitCheckInsView.swift
//  LOCA
//
//  Phase 14.2 — Check-ins history surface.
//
//  Displays grouped check-in history (by date), with swipe actions for
//  edit, delete, duplicate. Today's entries highlighted. Quick-log input
//  in the header for same-day logging.
//

import SwiftUI
import SwiftData

struct HabitCheckInsView: View {

    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isSubmitting = false
    @State private var showingAddCheckIn = false
    @State private var editingEntry: LogEntry? = nil
    @State private var quickLogAmount = ""

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
        { date in
            Calendar.current.isDateInToday(date)
        }
    }

    private var dateLabel: (Date) -> String {
        { date in
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {

                // MARK: - Today Status Card
                if let todayGroup = groupedLogs.first(where: { isToday($0.date) }) {
                    LOCACard {
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

                            let todayTotal = todayGroup.entries.reduce(0.0) { $0 + $1.value }
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
                                    Text("\(todayGroup.entries.count) \(todayGroup.entries.count == 1 ? "entry" : "entries") • \(unitLabel)")
                                        .font(DS.Text.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Space.md)
                    }
                }

                // MARK: - Quick Log Input (Today only)
                if groupedLogs.first?.date == Calendar.current.startOfDay(for: .now) || groupedLogs.isEmpty {
                    LOCACard {
                        HStack(spacing: DS.Space.md) {
                            TextField("Add amount", text: $quickLogAmount)
                                .font(DS.Text.body)
                                .decimalKeyboard()

                            if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                                Text(unitLabel)
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Button(action: { quickLog() }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(ColorPalette[board.colorIndex])
                            }
                            .disabled(Double(quickLogAmount.trimmingCharacters(in: .whitespaces)) == nil || Double(quickLogAmount.trimmingCharacters(in: .whitespaces)) ?? 0 <= 0)
                        }
                        .padding(DS.Space.md)
                    }
                }

                // MARK: - History (Grouped by Date)
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    if groupedLogs.isEmpty {
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
                    } else {
                        ForEach(groupedLogs, id: \.date) { group in
                            VStack(alignment: .leading, spacing: DS.Space.md) {
                                // Date header
                                Text(dateLabel(group.date))
                                    .font(DS.Text.footnote)
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .tracking(0.5)

                                // Entries for this date
                                ForEach(group.entries, id: \.id) { entry in
                                    SwipeAction(
                                        onEdit: { editEntry(entry) },
                                        onDelete: { deleteEntry(entry) },
                                        onDuplicate: { duplicateEntry(entry) }
                                    ) {
                                        HStack(spacing: DS.Space.md) {
                                            // Time
                                            VStack(alignment: .leading, spacing: DS.Space.xs) {
                                                Text(formattedTime(entry.timestamp))
                                                    .font(DS.Text.caption)
                                                    .foregroundStyle(DS.Color.textSecondary)
                                            }

                                            Spacer()

                                            // Value + unit
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
                                        .padding(DS.Space.md)
                                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                                    }

                                    // Notes (if present)
                                    if let note = entry.note, !note.isEmpty {
                                        Text(note)
                                            .font(DS.Text.caption)
                                            .foregroundStyle(DS.Color.textSecondary)
                                            .padding(DS.Space.md)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                                    }
                                }
                            }
                        }
                    }
                }

                // Clearance for the floating SurfaceSelector pill.
                Spacer(minLength: DS.Space.xxxl + DS.Space.xl)
            }
            .padding(DS.Space.lg)
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

    // MARK: - Actions

    private func quickLog() {
        guard let amount = Double(quickLogAmount.trimmingCharacters(in: .whitespaces)), amount > 0 else {
            return
        }

        let entry = LogEntry(timestamp: .now, value: amount, boardID: board.id, board: board)
        modelContext.insert(entry)
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            triggerHaptic()
            WidgetRefreshCoordinator.shared.scheduleReload()
            quickLogAmount = ""
        } catch {
            modelContext.rollback()
        }
    }

    private func editEntry(_ entry: LogEntry) {
        editingEntry = entry
    }

    private func deleteEntry(_ entry: LogEntry) {
        modelContext.delete(entry)
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            WidgetRefreshCoordinator.shared.scheduleReload()
        } catch {
            modelContext.rollback()
        }
    }

    private func duplicateEntry(_ entry: LogEntry) {
        let newEntry = LogEntry(
            timestamp: .now,
            value: entry.value,
            note: entry.note,
            boardID: board.id,
            board: board
        )
        modelContext.insert(newEntry)
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            triggerHaptic()
            WidgetRefreshCoordinator.shared.scheduleReload()
        } catch {
            modelContext.rollback()
        }
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - SwipeAction

struct SwipeAction<Content: View>: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let content: () -> Content

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            // Action buttons (hidden, revealed on swipe)
            HStack(spacing: 0) {
                Button(action: onDuplicate) {
                    Image(systemName: "doc.on.doc")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(DS.Color.textSecondary.opacity(0.6))
                }

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(ColorPalette[4])
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(.red.opacity(0.8))
                }
            }

            // Content (foreground, swipeable)
            content()
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = min(0, value.translation.width)
                        }
                        .onEnded { value in
                            if offset < -60 {
                                offset = -132
                            } else {
                                offset = 0
                            }
                        }
                )
        }
        .frame(height: 44)
        .clipped()
    }
}

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
