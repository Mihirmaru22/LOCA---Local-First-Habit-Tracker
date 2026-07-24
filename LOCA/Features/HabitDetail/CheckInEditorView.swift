//
//  CheckInEditorView.swift
//  LOCA
//
//  Phase X.2 — Unified check-in editor (create, edit, view, quick-log modes)
//

import SwiftUI
import SwiftData

// MARK: - CheckInMode

enum CheckInMode {
    case create
    case edit
    case view
    case quickLog
}

// MARK: - TimeSelectionMode

enum TimeSelectionMode: Equatable {
    case now
    case minutesAgo(Int)
    case custom(hour: Int, minute: Int)

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
        case .custom(let h, let m):
            return String(format: "%02d:%02d", h, m)
        }
    }

    var timestamp: Date {
        let now = Date()
        switch self {
        case .now:
            return now
        case .minutesAgo(let minutes):
            return now.addingTimeInterval(Double(-minutes * 60))
        case .custom(let hour, let minute):
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            let components = DateComponents(hour: hour, minute: minute)
            return calendar.date(byAdding: components, to: today) ?? now
        }
    }
}

// MARK: - CheckInEditorView

struct CheckInEditorView: View {
    let mode: CheckInMode
    let board: HabitBoard
    var entry: LogEntry? = nil

    var onSave: (LogEntry) -> Void = { _ in }
    var onDelete: () -> Void = { }
    var onCancel: () -> Void = { }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var selectedDate: Date = Date()
    @State private var selectedTimeMode: TimeSelectionMode = .now
    @State private var amountText: String = ""
    @State private var noteText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSaveError: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showTimeMenu: Bool = false

    // MARK: - Computed Properties

    private var isReadOnly: Bool {
        mode == .view
    }

    private var isBinary: Bool {
        board.metric == .binary
    }

    private var parsedAmount: Double? {
        Double(amountText.trimmingCharacters(in: .whitespaces))
    }

    private var isAmountValid: Bool {
        guard let amount = parsedAmount else { return false }
        return amount > 0 && amount <= 999.9
    }

    private var canSave: Bool {
        if isReadOnly { return false }
        if isBinary { return true }
        return isAmountValid
    }

    private var combinedTimestamp: Date {
        var calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeTimestamp = selectedTimeMode.timestamp
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeTimestamp)

        var combined = dateComponents
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? Date()
    }

    // MARK: - Lifecycle

    var body: some View {
        ZStack(alignment: .bottom) {
            scrollView
                .disabled(isSubmitting || isReadOnly)

            if showSaveError {
                VStack {
                    Spacer()
                    errorAlert
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: showSaveError)
        .onAppear { initializeState() }
        .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteEntry() }
        }
    }

    // MARK: - UI Components

    private var scrollView: some View {
        ScrollView {
            VStack(spacing: DS.Space.lg) {
                dateTimeSection
                if !isBinary {
                    amountSection
                }
                noteSection
                actionButtons
            }
            .padding(DS.Space.lg)
        }
    }

    // MARK: Date & Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("When?")
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            // Date Selector
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                Text("Date")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .frame(maxHeight: 300)
                .tint(ColorPalette[board.colorIndex])
            }

            Divider()

            // Time Selection
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                Text("Time")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                timeSelectionButtons
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private var timeSelectionButtons: some View {
        VStack(spacing: DS.Space.sm) {
            HStack(spacing: DS.Space.sm) {
                timeButton("Now", for: .now)
                timeButton("10 min", for: .minutesAgo(10))
                timeButton("30 min", for: .minutesAgo(30))
            }
            HStack(spacing: DS.Space.sm) {
                timeButton("1 hour", for: .minutesAgo(60))
                Spacer()
            }
        }
    }

    private func timeButton(_ label: String, for mode: TimeSelectionMode) -> some View {
        Button(action: { selectedTimeMode = mode }) {
            Text(label)
                .font(DS.Text.body)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(selectedTimeMode == mode ? ColorPalette[board.colorIndex] : DS.Color.surfaceRecessed,
                           in: RoundedRectangle(cornerRadius: DS.Radius.control))
                .foregroundStyle(selectedTimeMode == mode ? Color.white : DS.Color.textPrimary)
        }
    }

    // MARK: Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("How much?")
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            HStack(spacing: DS.Space.md) {
                TextField("Amount", text: $amountText)
                    .font(DS.Text.body)
                    .keyboardType(.decimalPad)
                    .frame(height: 44)
                    .padding(.horizontal, DS.Space.md)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))

                if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                    Text(unitLabel)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(maxWidth: 60)
                }
            }

            if let amount = parsedAmount, amount > 0, !isAmountValid {
                Text("Amount must be between 0.1 and 999.9")
                    .font(DS.Text.caption)
                    .foregroundStyle(Color(red: 1, green: 0.3, blue: 0.3))
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("Notes (optional)")
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            TextEditor(text: $noteText)
                .font(DS.Text.body)
                .frame(minHeight: 80)
                .padding(.horizontal, DS.Space.sm)
                .padding(.vertical, DS.Space.sm)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))

            HStack {
                Text("\(noteText.count) / 500 characters")
                    .font(DS.Text.caption)
                    .foregroundStyle(noteText.count >= 400 ? Color(red: 1, green: 0.65, blue: 0) : DS.Color.textSecondary)
                Spacer()
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .onChange(of: noteText) { _, newValue in
            if newValue.count > 500 {
                noteText = String(newValue.prefix(500))
            }
        }
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        HStack(spacing: DS.Space.md) {
            if mode == .edit {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Text("Delete")
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(.white)
                        .background(Color(red: 1, green: 0.3, blue: 0.3), in: RoundedRectangle(cornerRadius: DS.Radius.control))
                }
                .disabled(isSubmitting)
            }

            HStack(spacing: DS.Space.md) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(DS.Color.textPrimary)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                }
                .disabled(isSubmitting)

                Button(action: { saveEntry() }) {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .tint(Color.white)
                        } else if showSuccess {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                        } else {
                            Text("Save")
                                .font(DS.Text.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(.white)
                    .background(canSave ? ColorPalette[board.colorIndex] : DS.Color.textTertiary,
                               in: RoundedRectangle(cornerRadius: DS.Radius.control))
                }
                .disabled(!canSave || isSubmitting)
            }
        }
    }

    // MARK: Error Alert

    private var errorAlert: some View {
        HStack(spacing: DS.Space.md) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color(red: 1, green: 0.3, blue: 0.3))

            VStack(alignment: .leading, spacing: 4) {
                Text("Couldn't Save")
                    .font(DS.Text.body)
                    .fontWeight(.semibold)
                Text("Please try again")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            Button("Dismiss") {
                showSaveError = false
            }
            .foregroundStyle(ColorPalette[board.colorIndex])
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .padding(DS.Space.lg)
    }

    // MARK: - Actions

    private func initializeState() {
        if let entry = entry {
            let calendar = Calendar.current
            selectedDate = calendar.startOfDay(for: entry.timestamp)
            let components = calendar.dateComponents([.hour, .minute], from: entry.timestamp)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            selectedTimeMode = .custom(hour: hour, minute: minute)

            if !isBinary {
                amountText = String(format: entry.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", entry.value)
            }
            noteText = entry.note ?? ""
        } else {
            selectedDate = Calendar.current.startOfDay(for: Date())
            selectedTimeMode = .now
            amountText = ""
            noteText = ""
        }
    }

    private func saveEntry() {
        isSubmitting = true
        Haptics.impact(.light)

        do {
            let amount = isBinary ? 1.0 : (parsedAmount ?? 0)

            if mode == .create {
                try CheckInWriter.insert(
                    value: amount,
                    timestamp: combinedTimestamp,
                    note: noteText.isEmpty ? nil : noteText,
                    board: board,
                    context: modelContext
                )
            } else if mode == .edit, let entry = entry {
                try CheckInWriter.update(
                    entry: entry,
                    timestamp: combinedTimestamp,
                    value: amount,
                    note: noteText.isEmpty ? nil : noteText,
                    board: board,
                    context: modelContext
                )
            }

            withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                showSuccess = true
            }
            Haptics.notify(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismiss()
            }
        } catch {
            isSubmitting = false
            showSaveError = true
            Haptics.notify(.error)
        }
    }

    private func deleteEntry() {
        isSubmitting = true
        Haptics.notify(.warning)

        guard let entry = entry else { return }

        do {
            try CheckInWriter.delete(entry, board: board, context: modelContext)
            Haptics.notify(.success)
            onDelete()
            dismiss()
        } catch {
            isSubmitting = false
            showSaveError = true
            Haptics.notify(.error)
        }
    }
}
