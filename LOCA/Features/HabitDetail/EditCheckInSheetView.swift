//
//  EditCheckInSheetView.swift
//  LOCA
//
//  Phase 15.1 — Edit Check-in Sheet.
//
//  Presented from HabitCheckInsView's SwipeAction "Edit" button.
//  Pre-fills all fields from the existing LogEntry and saves
//  mutations in-place: no insert, just modify + save.
//

import SwiftUI
import SwiftData
import os

struct EditCheckInSheetView: View {

    let entry: LogEntry
    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Pre-filled from entry
    @State private var selectedDate: Date
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var amountText: String
    @State private var notesText: String
    @State private var isSaving = false
    @State private var showSaveError = false

    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "CheckIn")

    init(entry: LogEntry, board: HabitBoard) {
        self.entry = entry
        self.board = board
        let cal = Calendar.current
        _selectedDate   = State(initialValue: entry.timestamp)
        _selectedHour   = State(initialValue: cal.component(.hour,   from: entry.timestamp))
        _selectedMinute = State(initialValue: cal.component(.minute, from: entry.timestamp))
        _notesText      = State(initialValue: entry.note ?? "")

        // Extract amount text separately to avoid compiler complexity limit
        if board.metric == .quantitative {
            let fmt = entry.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f"
            _amountText = State(initialValue: String(format: fmt, entry.value))
        } else {
            _amountText = State(initialValue: "")
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        board.metric == .binary || (parsedAmount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {

                    // Date
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Date")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textPrimary)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(ColorPalette[board.colorIndex])
                    }

                    Divider()

                    // Time
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Time")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textPrimary)
                        HStack(spacing: DS.Space.md) {
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text(String(format: "%02d", h)).tag(h)
                                }
                            }
                            .frame(maxWidth: 80)
                            Text(":").font(DS.Text.body)
                            Picker("Minute", selection: $selectedMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 15)), id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .frame(maxWidth: 80)
                            Spacer()
                        }
                    }

                    Divider()

                    // Amount (quantitative only)
                    if board.metric == .quantitative {
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("Amount")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            HStack(spacing: DS.Space.md) {
                                TextField("0", text: $amountText)
                                    .font(DS.Text.body)
                                    .decimalKeyboard()
                                    .textFieldStyle(.roundedBorder)
                                if let unit = board.unitLabel, !unit.isEmpty {
                                    Text(unit)
                                        .font(DS.Text.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                        .frame(minWidth: 60)
                                }
                            }
                        }
                        Divider()
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Notes (Optional)")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textPrimary)
                        TextEditor(text: $notesText)
                            .font(DS.Text.body)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(DS.Color.surface)
                            .cornerRadius(DS.Radius.sm)
                    }
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isSaving)
                        .tint(ColorPalette[board.colorIndex])
                }
            }
            .alert("Couldn't Save Entry", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your changes couldn't be saved. Please try again.")
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard isValid else { return }
        isSaving = true

        // Build the new timestamp from date + hour/minute pickers
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: selectedDate)
        comps.hour   = selectedHour
        comps.minute = selectedMinute
        comps.second = 0
        let newTimestamp = cal.date(from: comps) ?? selectedDate

        // Capture old values for rollback
        let oldTimestamp = entry.timestamp
        let oldValue     = entry.value
        let oldNote      = entry.note

        // Mutate in-place — entry is already in the store
        entry.timestamp = newTimestamp
        entry.value     = board.metric == .quantitative ? (parsedAmount ?? oldValue) : 1.0
        entry.note      = notesText.isEmpty ? nil : notesText

        // Recompute streak — the change may shift which day is "completed"
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            logger.debug("LogEntry edited: \(entry.id, privacy: .public)")
            WidgetRefreshCoordinator.shared.scheduleReload()
            isSaving = false
            dismiss()
        } catch {
            // Roll back in-memory mutations
            entry.timestamp = oldTimestamp
            entry.value     = oldValue
            entry.note      = oldNote
            modelContext.rollback()
            logger.error("LogEntry edit save failed: \(error.localizedDescription, privacy: .public)")
            isSaving = false
            showSaveError = true
        }
    }
}
