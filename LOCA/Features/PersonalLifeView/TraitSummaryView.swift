//
//  TraitSummaryView.swift
//  LOCA
//
//  Phase 5 — Trait summary for the Personal Life view
//  Shows the 6 traits with values, uncertainty, and chapter context
//

import SwiftUI
import SwiftData

struct TraitSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Trait> { trait in trait.chapterId == nil },
        sort: \Trait.updatedAt,
        order: .reverse
    ) private var traits: [Trait]

    var body: some View {
        Group {
            if traits.isEmpty {
                emptyState
            } else {
                traitList
            }
        }
        .navigationTitle("Your Traits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: refreshTraits) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    // MARK: - Trait List

    private var traitList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                headerNote
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                ForEach(TraitType.allCases, id: \.self) { traitType in
                    if let trait = traits.first(where: { $0.traitType == traitType }) {
                        TraitCard(trait: trait)
                            .padding(.horizontal, DS.Space.lg)
                    }
                }

                updatedNote
                    .padding(.horizontal, DS.Space.lg)

                Spacer(minLength: DS.Space.xxxl)
            }
        }
    }

    private var headerNote: some View {
        Text("Inferred from the past 30 days of your patterns")
            .font(DS.Text.caption)
            .foregroundStyle(DS.Color.textSecondary)
    }

    private var updatedNote: some View {
        Group {
            if let latest = traits.first {
                Text("Last updated \(latest.updatedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text("No Traits Yet")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("LOCA needs at least 2 weeks of data before it can infer stable traits.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DS.Space.xl)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Refresh

    private func refreshTraits() {
        try? TraitInferenceEngine.shared.updateTraits(modelContext: modelContext)
    }
}

// MARK: - Trait Card

struct TraitCard: View {
    let trait: Trait

    private var confidenceLevel: ConfidenceLevel {
        ConfidenceLevel(uncertainty: trait.uncertainty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trait.traitType.displayName)
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(trait.traitType.description)
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                ConfidenceChip(level: confidenceLevel)
            }

            TraitBar(value: trait.value, uncertainty: trait.uncertainty, color: trait.traitType.color)

            HStack {
                Text(trait.traitType.lowLabel)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)

                Spacer()

                Text(trait.traitType.highLabel)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Text("\(trait.sampleCount) observations · \(trait.windowDays)-day window")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Trait Bar

private struct TraitBar: View {
    let value: Double
    let uncertainty: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .frame(height: 6)
                    .foregroundStyle(DS.Color.surfaceRecessed)

                // Uncertainty halo
                let haloStart = max(0, value - uncertainty)
                let haloWidth = min(1, value + uncertainty) - haloStart
                RoundedRectangle(cornerRadius: 3)
                    .frame(
                        width: geo.size.width * haloWidth,
                        height: 6
                    )
                    .offset(x: geo.size.width * haloStart)
                    .foregroundStyle(color.opacity(0.25))

                // Value bar
                RoundedRectangle(cornerRadius: 3)
                    .frame(width: geo.size.width * value, height: 6)
                    .foregroundStyle(color)

                // Point marker
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(color)
                    .offset(x: geo.size.width * value - 5, y: -2)
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Confidence Chip

private struct ConfidenceChip: View {
    let level: ConfidenceLevel

    private var label: String {
        switch level {
        case .crisp:       return "Confident"
        case .soft:        return "Emerging"
        case .speculative: return "Uncertain"
        }
    }

    private var chipColor: Color {
        switch level {
        case .crisp:       return Color(hex: "#10B981")
        case .soft:        return Color(hex: "#F59E0B")
        case .speculative: return Color(hex: "#6B7280")
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(chipColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(chipColor.opacity(0.12), in: Capsule())
    }
}

// MARK: - TraitType Display Extensions

extension TraitType {
    var displayName: String {
        switch self {
        case .resilience:    return "Resilience"
        case .consistency:   return "Consistency"
        case .socialDrive:   return "Social Drive"
        case .activityDrive: return "Activity Drive"
        case .focusDepth:    return "Focus Depth"
        case .moodStability: return "Mood Stability"
        }
    }

    var description: String {
        switch self {
        case .resilience:    return "How quickly you recover after stressful periods"
        case .consistency:   return "How regular your daily patterns are across weeks"
        case .socialDrive:   return "Your tendency to seek social engagement"
        case .activityDrive: return "Your tendency toward physical activity"
        case .focusDepth:    return "Your ability to sustain long concentration sessions"
        case .moodStability: return "How steady your mood is over time"
        }
    }

    var lowLabel: String {
        switch self {
        case .resilience:    return "Slow recovery"
        case .consistency:   return "Variable"
        case .socialDrive:   return "Solitary"
        case .activityDrive: return "Sedentary"
        case .focusDepth:    return "Scattered"
        case .moodStability: return "Variable"
        }
    }

    var highLabel: String {
        switch self {
        case .resilience:    return "Fast recovery"
        case .consistency:   return "Highly regular"
        case .socialDrive:   return "Social"
        case .activityDrive: return "Active"
        case .focusDepth:    return "Deep focus"
        case .moodStability: return "Steady"
        }
    }

    var color: Color {
        switch self {
        case .resilience:    return Color(hex: "#10B981")
        case .consistency:   return Color(hex: "#3B82F6")
        case .socialDrive:   return Color(hex: "#F59E0B")
        case .activityDrive: return Color(hex: "#EF4444")
        case .focusDepth:    return Color(hex: "#8B5CF6")
        case .moodStability: return Color(hex: "#06B6D4")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TraitSummaryView()
    }
}
