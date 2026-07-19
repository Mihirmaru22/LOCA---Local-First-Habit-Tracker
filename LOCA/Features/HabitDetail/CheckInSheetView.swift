//
//  CheckInSheetView.swift
//  LOCA
//
//  Phase 12.1 — Check-in input sheet for quantitative habits.
//
//  A modal sheet that appears when logging a quantitative habit amount.
//  Provides a number input field, unit display, and a save button that triggers
//  haptic feedback and a spring-confirm animation on completion.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - CheckInSheetView

struct CheckInSheetView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var inputValue: String = ""
    @State private var isSubmitting = false

    let board: HabitBoard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var parsedValue: Double? {
        Double(inputValue.trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        (parsedValue ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Space.lg) {

                // MARK: - Header
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("Log Amount")
                        .font(DS.Text.heading)
                    Text(board.name)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // MARK: - Input Field
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    HStack(spacing: DS.Space.md) {
                        TextField("0", text: $inputValue)
                            .font(DS.Text.value)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                            Text(unitLabel)
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                                .frame(minWidth: 50)
                        }
                    }
                }

                // MARK: - Target Info
                if let target = board.targetValue, target > 0 {
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        HStack {
                            Text("Daily Goal")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                            Spacer()
                            ValueText(
                                target.formatted(.number.precision(.fractionLength(0...1))),
                                font: DS.Text.valueSmall
                            )
                            .foregroundStyle(ColorPalette[board.colorIndex])
                        }
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                }

                Spacer()

                // MARK: - Submit Button
                Button(action: { submitCheckIn() }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Log Amount")
                            .font(DS.Text.body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DS.Space.md)
                    .background(ColorPalette[board.colorIndex])
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.control))
                }
                .disabled(!isValid || isSubmitting)
                .opacity(isValid ? 1.0 : 0.5)
            }
            .padding(DS.Space.lg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Cancel", action: { dismiss() })
                }
            }
        }
    }

    // MARK: - Submission

    private func submitCheckIn() {
        guard let value = parsedValue, value > 0 else { return }

        isSubmitting = true

        // Create log entry
        let logEntry = LogEntry(
            timestamp: Date(),
            value: value,
            boardID: board.id,
            board: board
        )
        modelContext.insert(logEntry)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Spring animation + dismiss
        withAnimation(DS.Motion.confirm(reduceMotion: reduceMotion)) {
            isSubmitting = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
            }
        }

        try? modelContext.save()
    }
}

// MARK: - Preview

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
    return CheckInSheetView(board: habit)
        .modelContainer(container)
}
