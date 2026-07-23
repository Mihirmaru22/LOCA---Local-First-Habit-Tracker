//
//  AddCheckInSheetView.swift
//  LOCA
//
//  Phase 14.1 — Add Check-in Sheet
//
//  Modal sheet for comprehensive habit entry: date selector, time picker,
//  quantitative amount input, and optional notes. Replaces quick inline
//  logging for deeper reflection and backdating capability.
//

import SwiftUI
import SwiftData

struct AddCheckInSheetView: View {

    let board: HabitBoard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedDate = Date()
    @State private var selectedHour = 12
    @State private var selectedMinute = 0
    @State private var amountText = ""
    @State private var notesText = ""
    @State private var isSubmitting = false
    @State private var showSaveError = false
    @State private var showSuccess = false

    @FocusState private var amountFocused: Bool
    @FocusState private var notesFocused: Bool

    private var parsedAmount: Double? {
        Double(amountText.trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        if board.metric == .quantitative {
            return (parsedAmount ?? 0) > 0
        } else {
            return true  // Binary just needs a date
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    // MARK: - Date & Time (Secondary fields)
                    VStack(alignment: .leading, spacing: DS.Space.lg) {
                        Text("When")
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textSecondary)

                        // Date Selector
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("Date")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)

                            DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(ColorPalette[board.colorIndex])
                        }

                        // Time Picker
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("Time")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)

                            HStack(spacing: DS.Space.md) {
                                Picker("Hour", selection: $selectedHour) {
                                    ForEach(0..<24, id: \.self) { h in
                                        Text(String(format: "%02d", h)).tag(h)
                                    }
                                }
                                .frame(maxWidth: 80)

                                Text(":")
                                    .font(DS.Text.body)

                                Picker("Minute", selection: $selectedMinute) {
                                    ForEach(Array(stride(from: 0, to: 60, by: 15)), id: \.self) { m in
                                        Text(String(format: "%02d", m)).tag(m)
                                    }
                                }
                                .frame(maxWidth: 80)

                                Spacer()
                            }
                        }
                    }

                    // MARK: - Amount (PRIMARY field for quantitative)
                    if board.metric == .quantitative {
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("Amount")
                                .font(DS.Text.heading)
                                .foregroundStyle(DS.Color.textPrimary)

                            HStack(spacing: DS.Space.md) {
                                TextField("0", text: $amountText)
                                    .font(DS.Text.body)
                                    .decimalKeyboard()
                                    .textFieldStyle(.roundedBorder)
                                    .focused($amountFocused)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                amountFocused ? ColorPalette[board.colorIndex] : Color.clear,
                                                lineWidth: 2
                                            )
                                            .padding(-4)
                                    )

                                if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                                    Text(unitLabel)
                                        .font(DS.Text.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                        .frame(minWidth: 60)
                                }
                            }
                        }
                    }

                    // MARK: - Notes (Optional secondary)
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Notes")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                        Text("Optional")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textTertiary)

                        TextEditor(text: $notesText)
                            .font(DS.Text.body)
                            .frame(minHeight: 80)
                            .padding(DS.Space.xs)
                            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.card)
                                    .stroke(
                                        notesFocused ? ColorPalette[board.colorIndex] : DS.Color.textTertiary.opacity(0.2),
                                        lineWidth: notesFocused ? 2 : 1
                                    )
                            )
                            .focused($notesFocused)
                            .onChange(of: notesText) { _, new in
                                if new.count > 500 { notesText = String(new.prefix(500)) }
                            }
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle("Add Check-in")
            .inlineNavigationTitleDisplay()
            .alert("Couldn't Save Check-in", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The check-in couldn't be saved. Please try again.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { dismiss() })
                }

                ToolbarItem(placement: .confirmationAction) {
                    if showSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ColorPalette[board.colorIndex])
                            .font(.title3)
                    } else if isSubmitting {
                        ProgressView()
                            .tint(ColorPalette[board.colorIndex])
                    } else {
                        Button(action: { submitCheckIn() }) {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func submitCheckIn() {
        guard isValid else { return }
        isSubmitting = true

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        let timestamp = calendar.date(from: components) ?? selectedDate

        let value: Double = board.metric == .quantitative ? (parsedAmount ?? 0) : 1.0

        // P4.2: Detect goal crossing for success haptic
        let isToday = calendar.isDateInToday(timestamp)
        let oldTotal = isToday ? (board.logs ?? [])
            .filter { calendar.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.value } : 0

        do {
            try CheckInWriter.insert(
                value: value,
                timestamp: timestamp,
                note: notesText.isEmpty ? nil : notesText,
                board: board,
                context: modelContext
            )
            Haptics.impact(.rigid)

            if isToday {
                let newTotal = oldTotal + value
                if oldTotal < board.effectiveTarget && newTotal >= board.effectiveTarget {
                    Haptics.notify(.success)
                }
            }

            withAnimation(DS.Motion.confirm(reduceMotion: reduceMotion)) {
                isSubmitting = false
                showSuccess = true
            }

            // Brief success acknowledgment before dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismiss()
            }
        } catch {
            isSubmitting = false
            showSaveError = true
        }
    }

}

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Morning Run", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
        container.mainContext.insert(habit)
        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return AddCheckInSheetView(board: habit)
        .modelContainer(container)
}
