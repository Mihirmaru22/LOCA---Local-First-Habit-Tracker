//
//  CheckInSheet.swift
//  LOCA
//
//  Phase 6.2 — Quantitative Check-In Entry
//
//  Presented by CheckInButton when board.metric == .quantitative.
//  Handles value entry, optional note, validation, persistence,
//  haptic confirmation, and widget reload.
//

import SwiftUI
import SwiftData
import os

// MARK: - CheckInSheet

/// Modal data-entry sheet for quantitative habit check-ins.
///
/// ## Presentation
/// Presented by `CheckInButton` as a `.sheet` when the board's metric is
/// `.quantitative`. Uses `NavigationStack` internally to host Cancel and
/// Log toolbar buttons — the standard iOS pattern for modal data entry
/// (Mail compose, Calendar event, Contacts new entry).
///
/// ## Validation
/// The "Log" confirm button is disabled until `parsedValue` resolves to a
/// positive `Double`. Parsing uses `Double(_:)` on whitespace-trimmed input
/// so locale-specific decimal separators ("2,5" vs "2.5") are NOT handled —
/// `.decimalPad` only produces `.` as a separator on all iOS locales, making
/// locale-aware parsing unnecessary here.
///
/// ## Persistence Sequence
/// Identical to the binary path in `CheckInButton`:
/// `insert → updateStreak → save → haptic → scheduleReload → dismiss`.
/// Save errors are non-blocking: the sheet stays open with an alert rather
/// than silently swallowing the failure or dismissing without confirmation.
///
/// ## Note Handling
/// The note field is optional. An empty or whitespace-only note is coerced
/// to `nil` before being passed to `LogEntry` — no empty strings reach the
/// store (consistent with `LogEntry.note: String?`).
struct CheckInSheet: View {

    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var valueText: String = ""
    @State private var note: String = ""
    @State private var showSaveError = false

    // Auto-focus the value field on appear so the keyboard is immediately
    // available — eliminates a required tap before the user can type.
    @FocusState private var valueFieldFocused: Bool

    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "CheckIn")

    // MARK: - Validation

    /// Parses `valueText` to a positive `Double`.
    /// Returns `nil` if the text is empty, non-numeric, zero, or negative.
    private var parsedValue: Double? {
        guard let v = Double(valueText.trimmingCharacters(in: .whitespaces)), v > 0 else {
            return nil
        }
        return v
    }

    private var isLogEnabled: Bool { parsedValue != nil }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                valueSection
                noteSection
            }
            .navigationTitle("Log \(board.name)")
            .inlineNavigationTitleDisplay()
            .toolbar { toolbarContent }
            .onAppear { valueFieldFocused = true }
            .alert("Couldn't Save Check-In", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your check-in couldn't be saved. Please try again.")
            }
        }
    }

    // MARK: - Value Section

    // MARK: SF Pro Rounded for numeric input (Engineering Principles §3)
    //
    // The value field uses `.system(.title2, design: .rounded, weight: .semibold)`
    // to visually match the StatCard and JournalEntryRow numeric rendering.
    // Consistency here reinforces the app's numeric typographic identity.

    @ViewBuilder
    private var valueSection: some View {
        Section {
            HStack(alignment: .center, spacing: 8) {
                TextField("0", text: $valueText)
                    .decimalKeyboard()
                    .focused($valueFieldFocused)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(parsedValue != nil ? ColorPalette[board.colorIndex] : .primary)
                    .accessibilityLabel("Value")
                    .accessibilityHint("Enter the amount for this check-in")

                if let unit = board.unitLabel, !unit.isEmpty {
                    Text(unit)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Amount")
        } footer: {
            if let target = targetFooterText {
                Text(target)
            }
        }
    }

    /// "Goal: 5.0 mi/day" footer — keeps the target visible while the user types.
    private var targetFooterText: String? {
        let target = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
        let unit = board.unitLabel ?? ""
        return "Goal: \(target)\(unit.isEmpty ? "" : " \(unit)")/day"
    }

    // MARK: - Note Section

    @ViewBuilder
    private var noteSection: some View {
        Section {
            TextField("Add a note (optional)", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .accessibilityLabel("Note")
                .accessibilityHint("Optional journal note for this check-in")
        } header: {
            Text("Note")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Log") { logEntry() }
                .fontWeight(.semibold)
                .disabled(!isLogEnabled)
                // Tint matches the board color so the confirm action reads as
                // contextually branded rather than generic system blue.
                .tint(ColorPalette[board.colorIndex])
        }
    }

    // MARK: - Persistence

    // MARK: Persistence Sequence
    //
    // Identical ordering to CheckInButton.logBinaryEntry():
    //   1. insert(entry)        — in-memory relationship established
    //   2. updateStreak(using:) — streak mutation before save
    //   3. save()               — atomic persistence of entry + streak
    //   4. haptic               — fires on confirmed persistence (EP §7.2)
    //   5. scheduleReload()     — debounced widget invalidation
    //   6. dismiss()            — sheet closes only on success
    //
    // On save failure: rollback() discards insert + streak mutation atomically.
    // Sheet stays open; alert surfaces the error non-blockingly (EP §4.1).

    private func logEntry() {
        guard let value = parsedValue else { return }

        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        let entry = LogEntry(
            value: value,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            boardID: board.id,
            board: board
        )

        modelContext.insert(entry)
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            triggerConfirmationHaptic()
            WidgetRefreshCoordinator.shared.scheduleReload()
            logger.debug(
                "Quantitative check-in saved: \(value, privacy: .public) for board '\(board.name, privacy: .public)'."
            )
            dismiss()
        } catch {
            logger.error(
                "Quantitative check-in save failed for board '\(board.name, privacy: .public)': \(error.localizedDescription, privacy: .public)"
            )
            modelContext.rollback()
            showSaveError = true
        }
    }

    // MARK: - Haptics

    private func triggerConfirmationHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}

// MARK: - Preview

@MainActor
private func makeQuantitativeSheetContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    let board = HabitBoard(
        name: "Running",
        metricType: HabitBoard.MetricType.quantitative.rawValue,
        targetValue: 5.0,
        unitLabel: "mi",
        colorIndex: 0
    )
    container.mainContext.insert(board)
    try? container.mainContext.save()
    return (container, board)
}

#Preview("Sheet — Empty") {
    let (container, board) = makeQuantitativeSheetContainer()
    return CheckInSheet(board: board)
        .modelContainer(container)
}

#Preview("Sheet — Value Entered") {
    // Demonstrates the active Log button state (value field pre-filled
    // via @State is not injectable in previews — shows blank field).
    let (container, board) = makeQuantitativeSheetContainer()
    return CheckInSheet(board: board)
        .modelContainer(container)
}
