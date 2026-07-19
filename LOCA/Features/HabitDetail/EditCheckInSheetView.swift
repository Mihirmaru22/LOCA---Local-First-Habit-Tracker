//
//  EditCheckInSheetView.swift
//  LOCA — Phase 15.1
//

import SwiftUI
import SwiftData
import os

struct EditCheckInSheetView: View {

    let entry: LogEntry
    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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
        // Flatten nested ternary — compiler cannot type-check it inline
        let isQuant = board.metric == .quantitative
        let fmt     = entry.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f"
        _amountText = State(initialValue: isQuant ? String(format: fmt, entry.value) : "")
    }

    // MARK: - Derived

    private var parsedAmount: Double? {
        Double(amountText.trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        board.metric == .binary || (parsedAmount ?? 0) > 0
    }

    // MARK: - Body (broken into sub-views to stay under type-checker limit)

    var body: some View {
        NavigationStack {
            editForm
                .navigationTitle("Edit Entry")
                .inlineNavigationTitleDisplay()
                .toolbar { editToolbar }
                .alert("Couldn't Save Entry", isPresented: $showSaveError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your changes couldn't be saved. Please try again.")
                }
        }
    }

    // MARK: - Form (extracted to lower complexity)

    private var editForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                dateSection
                Divider()
                timeSection
                Divider()
                if board.metric == .quantitative {
                    amountSection
                    Divider()
                }
                notesSection
            }
            .padding(DS.Space.lg)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Date")
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textPrimary)
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(ColorPalette[board.colorIndex])
        }
    }

    private var timeSection: some View {
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
    }

    private var amountSection: some View {
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
    }

    private var notesSection: some View {
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
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

    // MARK: - Save

    private func save() {
        guard isValid else { return }
        isSaving = true

        let cal  = Calendar.current
        var comp = cal.dateComponents([.year, .month, .day], from: selectedDate)
        comp.hour   = selectedHour
        comp.minute = selectedMinute
        comp.second = 0
        let newTS = cal.date(from: comp) ?? selectedDate

        let oldTS    = entry.timestamp
        let oldVal   = entry.value
        let oldNote  = entry.note

        entry.timestamp = newTS
        entry.value     = board.metric == .quantitative ? (parsedAmount ?? oldVal) : 1.0
        entry.note      = notesText.isEmpty ? nil : notesText
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            logger.debug("LogEntry edited: \(entry.id, privacy: .public)")
            WidgetRefreshCoordinator.shared.scheduleReload()
            isSaving = false
            dismiss()
        } catch {
            entry.timestamp = oldTS
            entry.value     = oldVal
            entry.note      = oldNote
            modelContext.rollback()
            logger.error("Edit save failed: \(error.localizedDescription, privacy: .public)")
            isSaving = false
            showSaveError = true
        }
    }
}
