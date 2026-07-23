//
//  HabitRecommendationCard.swift
//  LOCA
//
//  Phase 3.4 — Habit recommendation suggestion card.
//
//  Shows personalized habit recommendations based on existing habits
//  and user patterns. Non-intrusive; user can dismiss to hide for session.
//

import SwiftUI

struct HabitRecommendationCard: View {

    let recommendations: [HabitRecommendation]
    let onSelect: (HabitTemplate) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex = 0

    private var currentRecommendation: HabitRecommendation {
        recommendations[selectedIndex % recommendations.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(spacing: DS.Space.md) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ColorPalette[0])

                Text("Discover habits")
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

            VStack(alignment: .leading, spacing: DS.Space.md) {
                HStack(spacing: DS.Space.md) {
                    Text(currentRecommendation.template.emoji)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text(currentRecommendation.template.name)
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)

                        Text(currentRecommendation.reason)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()
                }

                HStack(spacing: DS.Space.md) {
                    if recommendations.count > 1 {
                        HStack(spacing: DS.Space.xs) {
                            ForEach(0..<recommendations.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedIndex ? ColorPalette[0] : DS.Color.textTertiary.opacity(0.3))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }

                    Spacer()

                    Button(action: { onSelect(currentRecommendation.template) }) {
                        Text("Try it")
                            .font(DS.Text.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(DS.Space.md)
                            .background(ColorPalette[0], in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(ColorPalette[0].opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            if recommendations.count > 1 {
                withAnimation {
                    selectedIndex = (selectedIndex + 1) % recommendations.count
                }
            }
        }
    }
}
