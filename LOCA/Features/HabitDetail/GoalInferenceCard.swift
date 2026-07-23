//
//  GoalInferenceCard.swift
//  LOCA
//
//  Phase 2.2 — Goal inference suggestion card.
//
//  Non-interruptive card shown once when goal inference becomes available.
//  User can accept the suggestion, adjust, or dismiss.
//

import SwiftUI
import SwiftData

struct GoalInferenceCard: View {

    let board: HabitBoard
    let inferredGoal: Double
    let onAccept: (Double) -> Void
    let onDismiss: () -> Void

    @State private var adjustedValue: String = ""
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.md) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ColorPalette[board.colorIndex])

                Text("Set a goal")
                    .font(DS.Text.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .buttonStyle(.plain)
            }

            if isEditing {
                HStack(spacing: DS.Space.md) {
                    TextField("Goal", text: $adjustedValue)
                        .font(DS.Text.body)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)

                    Text(board.unitLabel ?? "")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(minWidth: 40)

                    Button("Save") {
                        if let value = Double(adjustedValue.trimmingCharacters(in: .whitespaces)), value > 0 {
                            onAccept(value)
                            isEditing = false
                        }
                    }
                    .font(DS.Text.caption)
                    .fontWeight(.semibold)
                    .disabled(Double(adjustedValue.trimmingCharacters(in: .whitespaces)) ?? 0 <= 0)
                }
            } else {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("Based on your first week, we suggest:")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    HStack(spacing: DS.Space.sm) {
                        Text("\(Int(inferredGoal))")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(ColorPalette[board.colorIndex])

                        Text(board.unitLabel ?? "")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)

                        Text("per day")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }

                HStack(spacing: DS.Space.md) {
                    Button(action: {
                        adjustedValue = String(format: "%.0f", inferredGoal)
                        isEditing = true
                    }) {
                        Text("Adjust")
                            .font(DS.Text.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { onAccept(inferredGoal) }) {
                        Text("Accept")
                            .font(DS.Text.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(DS.Space.md)
                            .background(ColorPalette[board.colorIndex], in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(ColorPalette[board.colorIndex].opacity(0.2), lineWidth: 1)
        )
    }
}
