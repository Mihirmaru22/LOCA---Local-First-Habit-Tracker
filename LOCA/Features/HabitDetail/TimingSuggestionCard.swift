//
//  TimingSuggestionCard.swift
//  LOCA
//
//  Phase 2.3 — Timing suggestion card.
//
//  Shows the inferred logging time and offers reminder at that time.
//  User can accept, adjust, or dismiss.
//

import SwiftUI

struct TimingSuggestionCard: View {

    let board: HabitBoard
    let suggestedHour: Int
    let suggestedMinute: Int
    let onAccept: (Int, Int) -> Void
    let onDismiss: () -> Void

    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var isEditing = false

    init(
        board: HabitBoard,
        suggestedHour: Int,
        suggestedMinute: Int,
        onAccept: @escaping (Int, Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.board = board
        self.suggestedHour = suggestedHour
        self.suggestedMinute = suggestedMinute
        self.onAccept = onAccept
        self.onDismiss = onDismiss
        _selectedHour = State(initialValue: suggestedHour)
        _selectedMinute = State(initialValue: suggestedMinute)
    }

    private var timeString: String {
        String(format: "%02d:%02d", selectedHour, selectedMinute)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.md) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ColorPalette[board.colorIndex])

                Text("Get a reminder")
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
                    Picker("Hour", selection: $selectedHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d", h)).tag(h)
                        }
                    }
                    .frame(maxWidth: 80)

                    Text(":")
                        .font(DS.Text.body)

                    Picker("Minute", selection: $selectedMinute) {
                        ForEach([0, 30], id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                        }
                    }
                    .frame(maxWidth: 80)

                    Spacer()

                    Button("Save") {
                        onAccept(selectedHour, selectedMinute)
                        isEditing = false
                    }
                    .font(DS.Text.caption)
                    .fontWeight(.semibold)
                }
            } else {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("You usually log at this time:")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    HStack(spacing: DS.Space.sm) {
                        Text(timeString)
                            .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ColorPalette[board.colorIndex])

                        Text("daily")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }

                HStack(spacing: DS.Space.md) {
                    Button(action: {
                        selectedHour = suggestedHour
                        selectedMinute = suggestedMinute
                        isEditing = true
                    }) {
                        Text("Change")
                            .font(DS.Text.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { onAccept(selectedHour, selectedMinute) }) {
                        Text("Set reminder")
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
