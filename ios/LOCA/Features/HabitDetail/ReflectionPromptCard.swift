//
//  ReflectionPromptCard.swift
//  LOCA
//
//  Phase 2.4 — Weekly reflection prompt card.
//
//  Asks for sentiment about how the habit is going. Helps LOCA understand
//  if goals are right-sized and informs future adjustments.
//

import SwiftUI

struct ReflectionPromptCard: View {

    let board: HabitBoard
    let onResponse: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.md) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ColorPalette[board.colorIndex])

                Text("How's this going?")
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

            VStack(spacing: DS.Space.sm) {
                ForEach([
                    ("😊", "It's easy", "easy"),
                    ("✨", "Just right", "right"),
                    ("😰", "It's hard", "hard"),
                    ("🤔", "Not sure", "unsure")
                ], id: \.2) { emoji, label, value in
                    Button(action: {
                        Haptics.selection()
                        onResponse(value)
                    }) {
                        HStack(spacing: DS.Space.md) {
                            Text(emoji)
                                .font(.system(size: 18))

                            Text(label)
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
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
