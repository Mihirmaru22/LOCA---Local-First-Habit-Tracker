//
//  WeeklyInsightCard.swift
//  LOCA
//
//  Phase 3.3 — Weekly progress summary and insights.
//
//  Shows weekly statistics: days completed, consistency %, current streak.
//  Celebrates wins and provides context to sustain motivation.
//

import SwiftUI

struct WeeklyInsightCard: View {

    let board: HabitBoard
    let daysCompletedThisWeek: Int
    let weeklyConsistency: Double
    let currentStreak: Int

    private var consistencyPercentInt: Int {
        Int((weeklyConsistency * 100).rounded())
    }

    private var streakColor: Color {
        currentStreak >= 7 ? ColorPalette[board.colorIndex] : .secondary
    }

    private var headlineMessage: String {
        switch consistencyPercentInt {
        case 90...:
            return "On fire 🔥"
        case 70...:
            return "Strong week"
        case 50...:
            return "Making progress"
        default:
            return "Keep going"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("This Week")
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(headlineMessage)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DS.Space.xs) {
                    HStack(spacing: DS.Space.xs) {
                        Text("\(daysCompletedThisWeek)")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(ColorPalette[board.colorIndex])
                        Text("/ 7 days")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }

            HStack(spacing: DS.Space.lg) {
                // Consistency gauge
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("Consistency")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    HStack(spacing: DS.Space.sm) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule(style: .continuous)
                                    .fill(ColorPalette[board.colorIndex].opacity(0.18))

                                Capsule(style: .continuous)
                                    .fill(ColorPalette[board.colorIndex])
                                    .frame(width: geo.size.width * weeklyConsistency)
                            }
                        }
                        .frame(height: 6)

                        Text("\(consistencyPercentInt)%")
                            .font(DS.Text.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                            .frame(minWidth: 32, alignment: .trailing)
                    }
                }

                // Streak badge
                VStack(alignment: .center, spacing: DS.Space.xs) {
                    Text("\(currentStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(streakColor)

                    Text("day streak")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Space.md)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(ColorPalette[board.colorIndex].opacity(0.1), lineWidth: 1)
        )
    }
}
