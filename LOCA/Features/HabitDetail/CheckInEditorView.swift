//
//  CheckInEditorView.swift
//  LOCA
//
//  Phase L — Unified check-in editor
//  Common case optimized: today+now assumed, metadata progressive.
//

import SwiftUI
import SwiftData

// MARK: - CheckInMode

enum CheckInMode {
    case create
    case edit
    case view
}

// MARK: - TimeQuickSelect

enum TimeQuickSelect: Equatable, Identifiable {
    case now
    case minutesAgo(Int)

    var id: String {
        switch self {
        case .now: return "now"
        case .minutesAgo(let m): return "ago-\(m)"
        }
    }

    var label: String {
        switch self {
        case .now: return "Now"
        case .minutesAgo(10): return "10 min ago"
        case .minutesAgo(30): return "30 min ago"
        case .minutesAgo(60): return "1 hour ago"
        case .minutesAgo(let m): return "\(m) min ago"
        }
    }

    var timestamp: Date {
        let now = Date()
        switch self {
        case .now: return now
        case .minutesAgo(let minutes): return now.addingTimeInterval(Double(-minutes * 60))
        }
    }
}

// MARK: - CheckInEditorView

struct CheckInEditorView: View {
    let mode: CheckInMode
    let board: HabitBoard
    var entry: LogEntry? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var amountText: String = ""
    @State private var noteText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTimeQuick: TimeQuickSelect = .now
    @State private var showAdvancedOptions = false
    @State private var isSubmitting = false
    @State private var showSaveError = false
    @State private var showDeleteConfirmation = false
    @FocusState private var amountFocused: Bool

    // MARK: - Computed Properties

    private var isReadOnly: Bool { mode == .view }
    private var isBinary: Bool { board.metric == .binary }
    private var isEditMode: Bool { mode == .edit }

    private var parsedAmount: Double? {
        Double(amountText.trimmingCharacters(in: .whitespaces))
    }

    private var isAmountValid: Bool {
        guard let amount = parsedAmount, amount > 0, amount <= 999.9 else { return false }
        return true
    }

    private var canSave: Bool {
        !isReadOnly && (isBinary || isAmountValid)
    }

    private var timestamp: Date {
        let baseTime = selectedTimeQuick.timestamp
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: baseTime)
        var combined = dateComponents
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        return calendar.date(from: combined) ?? Date()
    }

    // MARK: - Lifecycle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    if !isBinary {
                        amountSection
                    }

                    if showAdvancedOptions {
                        dateTimeSection
                        notesSection
                    } else if !isEditMode {
                        summaryRow
                    }

                    if isEditMode && isBinary {
                        notesSection
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                            .tint(ColorPalette[board.colorIndex])
                    } else if isReadOnly {
                        EmptyView()
                    } else if isEditMode {
                        Button("Update") { save() }
                            .disabled(!canSave)
                    } else {
                        Button("Log") { save() }
                            .disabled(!canSave)
                    }
                }
            }
            .onAppear { initializeState() }
            .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) { deleteEntry() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // MARK: - UI Sections

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "Log \(board.name)"
        case .edit:
            return "Edit Entry"
        case .view:
            return board.name
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Amount")
                .font(DS.Text.heading)
                .foregroundStyle(DS.Color.textPrimary)

            HStack(spacing: DS.Space.md) {
                TextField("0", text: $amountText)
                    .font(DS.Text.body)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .frame(height: 44)
                    .padding(.horizontal, DS.Space.md)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))

                if let unit = board.unitLabel, !unit.isEmpty {
                    Text(unit)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(minWidth: 50, alignment: .leading)
                }
            }
        }
    }

    private var summaryRow: some View {
        VStack(spacing: DS.Space.sm) {
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showAdvancedOptions.toggle()
            }}) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logging today")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        Text(selectedTimeQuick.label)
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)
                    }
                    Spacer()
                    Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                        .foregroundStyle(ColorPalette[board.colorIndex])
                        .font(.caption)
                }
                .padding(DS.Space.md)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            }
            .disabled(isReadOnly)

            if isEditMode && isBinary {
                Button("Delete", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("When")
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                Text("Date")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(maxHeight: 300)
                    .tint(ColorPalette[board.colorIndex])
            }

            Divider()

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                Text("Time")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                VStack(spacing: DS.Space.sm) {
                    ForEach([TimeQuickSelect.now, .minutesAgo(10), .minutesAgo(30), .minutesAgo(60)], id: \.id) { option in
                        timeButton(option)
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func timeButton(_ option: TimeQuickSelect) -> some View {
        Button(action: { selectedTimeQuick = option }) {
            HStack {
                Text(option.label)
                    .font(DS.Text.body)
                Spacer()
                if selectedTimeQuick == option {
                    Image(systemName: "checkmark")
                        .foregroundStyle(ColorPalette[board.colorIndex])
                }
            }
            .frame(height: 44)
            .padding(.horizontal, DS.Space.md)
            .background(selectedTimeQuick == option ? DS.Color.surfaceRecessed : DS.Color.surface,
                       in: RoundedRectangle(cornerRadius: DS.Radius.control))
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Notes")
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            TextEditor(text: $noteText)
                .font(DS.Text.body)
                .frame(minHeight: 100)
                .padding(DS.Space.sm)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                .onChange(of: noteText) { _, new in
                    if new.count > 500 { noteText = String(new.prefix(500)) }
                }
        }
    }

    // MARK: - Actions

    private func initializeState() {
        if let entry = entry {
            let calendar = Calendar.current
            selectedDate = calendar.startOfDay(for: entry.timestamp)

            if !isBinary {
                let format = entry.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"
                amountText = String(format: format, entry.value)
            }

            noteText = entry.note ?? ""
        } else if !isBinary {
            amountFocused = true
        }
    }

    private func save() {
        isSubmitting = true
        Haptics.impact(.rigid)

        let timestamp = self.timestamp
        let amount = isBinary ? 1.0 : (parsedAmount ?? 0)
        let note = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if isEditMode, let existing = entry {
                try CheckInWriter.update(
                    existing,
                    value: amount,
                    timestamp: timestamp,
                    note: note.isEmpty ? nil : note,
                    in: modelContext
                )
            } else {
                try CheckInWriter.insert(
                    value: amount,
                    timestamp: timestamp,
                    note: note.isEmpty ? nil : note,
                    board: board,
                    context: modelContext
                )

                if Calendar.current.isDateInToday(timestamp) {
                    board.updateStreak(using: .current)
                } else {
                    board.needsStreakRecalculation = true
                }
            }

            Haptics.notify(.success)
            isSubmitting = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
            try CheckInWriter.delete(entryID: entry.id, context: modelContext)
            board.needsStreakRecalculation = true
            try modelContext.save()

            Haptics.notify(.success)
            dismiss()
        } catch {
            isSubmitting = false
            showSaveError = true
            Haptics.notify(.error)
        }
    }
}

// MARK: - Preview

struct CheckInEditorViewPreview: PreviewProvider {
    static var previews: some View {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
        container.mainContext.insert(habit)
        try? container.mainContext.save()

        return NavigationStack {
            CheckInEditorView(mode: .create, board: habit)
        }
        .modelContainer(container)
    }
}
