//
//  FeedbackAnalyticsView.swift
//  LOCA
//
//  Phase 10, Session 10.4 — Feedback analytics and learning metrics.
//
//  Show users the impact of their feedback: which patterns and themes
//  resonate most, how feedback is shaping the system's understanding,
//  and metrics about the feedback loop itself.
//

import SwiftUI
import SwiftData

struct FeedbackAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var patternFeedback: [PatternFeedback] = []
    @State private var narrativeFeedback: [NarrativeFeedback] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: DS.Space.lg) {
                    Text("…")
                        .font(.title3)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(DS.Space.xl)
            } else if patternFeedback.isEmpty && narrativeFeedback.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    // Overall feedback summary
                    feedbackSummarySection

                    Divider()

                    // Pattern feedback breakdown
                    if !patternFeedback.isEmpty {
                        patternFeedbackSection
                        Divider()
                    }

                    // Narrative feedback
                    if !narrativeFeedback.isEmpty {
                        narrativeFeedbackSection
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.xl)
            }
        }
        .navigationTitle("Your Feedback")
        .largeNavigationTitleDisplay()
        .task { await loadFeedback() }
    }

    private var emptyState: some View {
        LifeEmptyState(
            icon: "hand.thumbsup",
            headline: "No feedback yet",
            message: "Rate patterns and narratives to track what resonates with you."
        )
    }

    private var feedbackSummarySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("Your feedback summary")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .textCase(.uppercase)

            HStack(spacing: DS.Space.lg) {
                // Pattern feedback count
                StatCard(
                    value: String(patternFeedback.count),
                    label: "Patterns rated",
                    icon: "sparkles"
                )

                // Average resonance (patterns)
                if !patternFeedback.isEmpty {
                    let avgResonance = Double(patternFeedback.map { $0.resonance }.reduce(0, +)) / Double(patternFeedback.count)
                    StatCard(
                        value: String(format: "%.1f", avgResonance),
                        label: "Avg pattern resonance",
                        icon: "star.fill"
                    )
                }

                // Narrative feedback count
                StatCard(
                    value: String(narrativeFeedback.count),
                    label: "Narratives rated",
                    icon: "book.pages.fill"
                )
            }
        }
    }

    private var patternFeedbackSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("Pattern feedback")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .textCase(.uppercase)

            let resonanceGroups = groupPatternsByResonance()

            // High resonance
            if !resonanceGroups.high.isEmpty {
                FeedbackGroup(
                    title: "Resonant patterns",
                    subtitle: "These patterns feel true to you",
                    count: resonanceGroups.high.count,
                    icon: "hand.thumbsup.fill",
                    color: Color(hex: "#10B981")
                )
            }

            // Neutral
            if !resonanceGroups.neutral.isEmpty {
                FeedbackGroup(
                    title: "Uncertain patterns",
                    subtitle: "These patterns need refinement",
                    count: resonanceGroups.neutral.count,
                    icon: "minus.circle.fill",
                    color: Color.accentColor
                )
            }

            // Low resonance
            if !resonanceGroups.low.isEmpty {
                FeedbackGroup(
                    title: "Off patterns",
                    subtitle: "These don't fit your experience",
                    count: resonanceGroups.low.count,
                    icon: "hand.thumbsdown.fill",
                    color: Color(hex: "#EF4444")
                )
            }

            // Refinements
            let refinements = patternFeedback.compactMap { $0.refinement }
            if !refinements.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("\(refinements.count) refinement\(refinements.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)

                    Text("You've added context to help refine patterns.")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(DS.Space.md)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            }
        }
    }

    private var narrativeFeedbackSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("Narrative feedback")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .textCase(.uppercase)

            let avgResonance = narrativeFeedback.map { $0.resonance }.reduce(0, +) / Double(narrativeFeedback.count)

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                HStack {
                    Text("Average narrative resonance")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)

                    Spacer()

                    Text(String(format: "%.0f%%", avgResonance * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .foregroundStyle(DS.Color.surfaceRecessed)

                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: geo.size.width * avgResonance)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(height: 6)
            }

            if !narrativeFeedback.isEmpty {
                Text("You've rated \(narrativeFeedback.count) narrative\(narrativeFeedback.count == 1 ? "" : "s"). Your feedback helps refine how LOCA weaves your life story.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    private func groupPatternsByResonance() -> (high: [PatternFeedback], neutral: [PatternFeedback], low: [PatternFeedback]) {
        let high = patternFeedback.filter { $0.resonance == 1 }
        let neutral = patternFeedback.filter { $0.resonance == 0 }
        let low = patternFeedback.filter { $0.resonance == -1 }
        return (high, neutral, low)
    }

    private func loadFeedback() async {
        isLoading = true
        do {
            patternFeedback = try modelContext.fetch(FetchDescriptor<PatternFeedback>())
            narrativeFeedback = try modelContext.fetch(FetchDescriptor<NarrativeFeedback>())
        } catch {
            patternFeedback = []
            narrativeFeedback = []
        }
        isLoading = false
    }
}

// MARK: - Statistics Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .center, spacing: DS.Space.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Feedback Group

private struct FeedbackGroup: View {
    let title: String
    let subtitle: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeedbackAnalyticsView()
    }
}
