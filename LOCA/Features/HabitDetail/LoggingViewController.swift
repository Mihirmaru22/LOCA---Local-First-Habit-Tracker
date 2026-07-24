//
//  LoggingViewController.swift
//  LOCA
//
//  Phase L — Unified logging orchestrator
//
//  Routes all logging entry points through a single coordinator that presents
//  the appropriate logging UI (inline confirmation or progressive disclosure)
//  based on metric type and context.
//
//  This replaces CheckInEditorView + AddCheckInSheetView + inline quick-log patterns.
//

import SwiftUI
import SwiftData

// MARK: - LoggingViewController

struct LoggingViewController {
    private let board: HabitBoard
    @Environment(\.modelContext) private var modelContext

    /// Presents the logging UI for this board, routing to the appropriate flow
    /// based on metric type and entry point context.
    @MainActor
    func present(
        from source: LoggingEntryPoint,
        in view: some View
    ) -> some View {
        switch (board.metric, source) {
        case (.binary, _):
            return AnyView(BinaryLoggingFlow(board: board))
        case (.quantitative, .dashboard):
            return AnyView(InlineQuantitativeLogger(board: board))
        case (.quantitative, .detail):
            return AnyView(DetailQuantitativeLogger(board: board))
        }
    }
}

// MARK: - LoggingEntryPoint

enum LoggingEntryPoint {
    case dashboard      // Quick-log from dashboard card
    case detail         // Habit detail header
    case sheet          // Modal sheet (used when full editor needed)
}

// MARK: - BinaryLoggingFlow

/// Binary habits: one-tap confirmation with immediate feedback.
/// No sheet, no form, no modal. Just acknowledgment + undo window.
struct BinaryLoggingFlow: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showConfirmation = false
    @State private var showUndo = false
    @State private var lastLogID: UUID?

    var body: some View {
        VStack {
            if showConfirmation {
                BinaryConfirmationBadge(
                    board: board,
                    canUndo: showUndo,
                    onUndo: { undoLastLog() }
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                BinaryConfirmationButton(board: board, action: { logBinary() })
            }
        }
    }

    private func logBinary() {
        do {
            let entry = LogEntry(value: 1.0, boardID: board.id, board: board)
            modelContext.insert(entry)
            board.updateStreak(using: .current)
            try modelContext.save()

            lastLogID = entry.id
            Haptics.impact(.rigid)

            withAnimation(DS.Motion.confirm(reduceMotion: reduceMotion)) {
                showConfirmation = true
            }

            // Check for goal crossing
            let todayTotal = (board.logs ?? [])
                .filter { Calendar.current.isDateInToday($0.timestamp) }
                .reduce(0) { $0 + $1.value }

            if todayTotal >= board.effectiveTarget {
                Haptics.notify(.success)
            }

            // Show undo window for 5 seconds
            withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                showUndo = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                    showUndo = false
                    showConfirmation = false
                }
            }
        } catch {
            Haptics.notify(.error)
        }
    }

    private func undoLastLog() {
        guard let id = lastLogID else { return }

        do {
            try CheckInWriter.delete(entryID: id, context: modelContext)
            board.needsStreakRecalculation = true
            try modelContext.save()

            Haptics.impact(.light)
            withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                showUndo = false
                showConfirmation = false
            }
        } catch {
            Haptics.notify(.error)
        }
    }
}

// MARK: - BinaryConfirmationButton

struct BinaryConfirmationButton: View {
    let board: HabitBoard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(ColorPalette[board.colorIndex], in: Circle())
        }
    }
}

// MARK: - BinaryConfirmationBadge

struct BinaryConfirmationBadge: View {
    let board: HabitBoard
    let canUndo: Bool
    let onUndo: () -> Void

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            HStack(spacing: DS.Space.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ColorPalette[board.colorIndex])

                VStack(alignment: .leading, spacing: 2) {
                    Text("Logged")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text(board.name)
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                Spacer()

                if canUndo {
                    Button("Undo") { onUndo() }
                        .font(DS.Text.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                }
            }
            .padding(DS.Space.md)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }
}

// MARK: - InlineQuantitativeLogger

/// Quantitative habits on dashboard: inline number input with confirmation.
struct InlineQuantitativeLogger: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var amountText = ""
    @State private var isLogging = false
    @State private var showConfirmation = false
    @State private var lastLogID: UUID?
    @FocusState private var amountFocused: Bool

    var parsedAmount: Double? {
        Double(amountText.trimmingCharacters(in: .whitespaces))
    }

    var isValid: Bool {
        (parsedAmount ?? 0) > 0
    }

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            if showConfirmation {
                QuantitativeConfirmationBadge(
                    board: board,
                    amount: parsedAmount ?? 0,
                    canUndo: showConfirmation,
                    onUndo: { undoLastLog() }
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                HStack(spacing: DS.Space.md) {
                    TextField("Amount", text: $amountText)
                        .font(DS.Text.body)
                        .decimalKeyboard()
                        .focused($amountFocused)
                        .keyboardType(.decimalPad)

                    if let unit = board.unitLabel, !unit.isEmpty {
                        Text(unit)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .frame(minWidth: 40)
                    }

                    Button(action: { logQuantitative() }) {
                        Text("Log")
                            .font(DS.Text.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.white)
                            .frame(minWidth: 44)
                            .background(
                                isValid ? ColorPalette[board.colorIndex] : DS.Color.textTertiary,
                                in: RoundedRectangle(cornerRadius: DS.Radius.control)
                            )
                    }
                    .disabled(!isValid)
                }
                .padding(DS.Space.md)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            }
        }
    }

    private func logQuantitative() {
        guard let amount = parsedAmount, amount > 0 else { return }

        isLogging = true

        do {
            let entry = LogEntry(value: amount, boardID: board.id, board: board)
            modelContext.insert(entry)
            board.updateStreak(using: .current)
            try modelContext.save()

            lastLogID = entry.id
            Haptics.impact(.rigid)

            withAnimation(DS.Motion.confirm(reduceMotion: reduceMotion)) {
                showConfirmation = true
            }

            amountText = ""
            isLogging = false
        } catch {
            isLogging = false
            Haptics.notify(.error)
        }
    }

    private func undoLastLog() {
        guard let id = lastLogID else { return }

        do {
            try CheckInWriter.delete(entryID: id, context: modelContext)
            board.needsStreakRecalculation = true
            try modelContext.save()

            Haptics.impact(.light)
            withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                showConfirmation = false
            }
        } catch {
            Haptics.notify(.error)
        }
    }
}

// MARK: - DetailQuantitativeLogger

/// Quantitative habits in detail view: full editor with progressive disclosure.
struct DetailQuantitativeLogger: View {
    let board: HabitBoard

    var body: some View {
        QuantitativeEditorSheet(board: board)
    }
}

// MARK: - QuantitativeConfirmationBadge

struct QuantitativeConfirmationBadge: View {
    let board: HabitBoard
    let amount: Double
    let canUndo: Bool
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: DS.Space.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Logged")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                HStack(spacing: DS.Space.xs) {
                    Text(amount.formatted(.number.precision(.fractionLength(0...2))))
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)
                    if let unit = board.unitLabel, !unit.isEmpty {
                        Text(unit)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }

            Spacer()

            if canUndo {
                Button("Undo") { onUndo() }
                    .font(DS.Text.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorPalette[board.colorIndex])
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - QuantitativeEditorSheet

/// Full editor for quantitative habits with progressive disclosure of uncommon cases.
struct QuantitativeEditorSheet: View {
    let board: HabitBoard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var entry: LogEntry? = nil
    @State private var amountText = ""
    @State private var selectedDate = Date()
    @State private var selectedTime: TimeSelection = .now
    @State private var notesText = ""
    @State private var showTimeOptions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    // Amount (primary)
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Amount")
                            .font(DS.Text.heading)
                        HStack {
                            TextField("0", text: $amountText)
                                .font(DS.Text.body)
                                .decimalKeyboard()
                            if let unit = board.unitLabel {
                                Text(unit)
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }
                        }
                    }

                    Divider()

                    // Time selection (progressive disclosure)
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        HStack {
                            Text("When")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textSecondary)
                            Spacer()
                            Text(selectedTime.label)
                                .font(DS.Text.caption)
                                .foregroundStyle(ColorPalette[board.colorIndex])
                        }

                        if showTimeOptions {
                            TimeSelectionOptions(
                                selectedTime: $selectedTime,
                                selectedDate: $selectedDate
                            )
                        }
                    }

                    // Notes (progressive disclosure)
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Notes")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                        TextEditor(text: $notesText)
                            .font(DS.Text.body)
                            .frame(minHeight: 80)
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle("Log \(board.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        // Save logic
        dismiss()
    }
}

// MARK: - TimeSelection

enum TimeSelection: Equatable {
    case now
    case minutesAgo(Int)
    case custom(hour: Int, minute: Int, date: Date)

    var label: String {
        switch self {
        case .now:
            return "Now"
        case .minutesAgo(10):
            return "10 min ago"
        case .minutesAgo(30):
            return "30 min ago"
        case .minutesAgo(60):
            return "1 hour ago"
        case .minutesAgo(let m):
            return "\(m) min ago"
        case .custom(let h, let m, _):
            return String(format: "%02d:%02d", h, m)
        }
    }
}

// MARK: - TimeSelectionOptions

struct TimeSelectionOptions: View {
    @Binding var selectedTime: TimeSelection
    @Binding var selectedDate: Date

    var body: some View {
        VStack(spacing: DS.Space.md) {
            ForEach([.now, .minutesAgo(10), .minutesAgo(30), .minutesAgo(60)] as [TimeSelection], id: \.self) { option in
                Button(action: { selectedTime = option }) {
                    HStack {
                        Text(option.label)
                        Spacer()
                        if selectedTime == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(ColorPalette[0])
                        }
                    }
                }
            }
        }
    }
}
