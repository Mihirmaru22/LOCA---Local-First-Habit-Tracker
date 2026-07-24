//
//  GoalTuningCard.swift
//  LOCA
//
//  Phase 3.2 — Goal tuning suggestion card.
//
//  Recommends goal adjustments based on consistency and difficulty
//  feedback. User can accept, skip, or adjust manually.
//

import SwiftUI

struct GoalTuningCard: View {

    let board: HabitBoard
    let suggestedGoal: Double
    let currentGoal: Double
    let reason: String
    let onAccept: (Double) -> Void
    let onDismiss: () -> Void

    @State private var adjustedValue: String = ""
    @State private var isEditing = false

    private var changePercent: Int {
        let percent = ((suggestedGoal - currentGoal) / currentGoal) * 100
        return Int(percent.rounded())
    }

    private var directionIcon: String {
        changePercent > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.md) {
                Image(systemName: directionIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(changePercent > 0 ? ColorPalette[0] : .orange)

                Text("Adjust your goal")
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
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

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
                    Text(reason)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    HStack(spacing: DS.Space.sm) {
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("Now:")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textTertiary)
                            Text("\(Int(currentGoal))")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.Color.textTertiary)

                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            HStack(spacing: DS.Space.xs) {
                                Text("Try:")
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textTertiary)
                                Text("\(changePercent > 0 ? "+" : "")\(changePercent)%")
                                    .font(DS.Text.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(changePercent > 0 ? ColorPalette[0] : .orange)
                            }
                            Text("\(Int(suggestedGoal))")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(ColorPalette[board.colorIndex])
                        }

                        Spacer()
                    }
                }

                HStack(spacing: DS.Space.md) {
                    Button(action: {
                        adjustedValue = String(format: "%.0f", suggestedGoal)
                        isEditing = true
                    }) {
                        Text("Adjust")
                            .font(DS.Text.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { onAccept(suggestedGoal) }) {
                        Text("Apply")
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
