//
//  PatternsView.swift
//  LOCA
//
//  Phase 9, Session 9.1 — Patterns & synthesis view.
//
//  Surface cross-layer patterns: habits that affect your states, people who
//  shift your mood, chapters with distinct emotional tones, habits that persist
//  across your life. Each pattern is a thread you can pull to explore deeper.
//

import SwiftUI
import SwiftData

struct PatternsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var patterns: [LifePattern] = []
    @State private var isLoading = true
    @State private var selectedPattern: LifePattern?
    @State private var showPatternDetail = false
    @State private var patternFeedback: [UUID: Int] = [:] // resonance per pattern

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: DS.Space.lg) {
                    Text("…")
                        .font(.title3)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(DS.Space.xl)
            } else if patterns.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    Text("Patterns")
                        .font(.headline)
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.horizontal, DS.Space.lg)

                    VStack(spacing: DS.Space.md) {
                        ForEach(patterns) { pattern in
                            PatternCard(pattern: pattern)
                                .onTapGesture {
                                    selectedPattern = pattern
                                    showPatternDetail = true
                                }
                        }
                    }
                    .padding(DS.Space.lg)
                }
            }
        }
        .navigationTitle("Patterns")
        .largeNavigationTitleDisplay()
        .task { await loadPatterns() }
        .sheet(isPresented: $showPatternDetail) {
            if let pattern = selectedPattern {
                PatternDetailView(pattern: pattern)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text("Patterns emerging")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("LOCA needs a few weeks of data across habits, states, and people to see patterns in your life.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DS.Space.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadPatterns() async {
        isLoading = true
        do {
            patterns = try PatternDetectionEngine.shared.detectPatterns(modelContext: modelContext)
        } catch {
            patterns = []
        }
        isLoading = false
    }
}

// MARK: - Pattern Card

private struct PatternCard: View {
    let pattern: LifePattern

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(alignment: .top, spacing: DS.Space.md) {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text(pattern.observation)
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: DS.Space.sm) {
                        Label(
                            "\(pattern.sampleCount) observations",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)

                        Spacer()

                        // C5: the pattern's real propagated uncertainty as a band —
                        // replaces a false-precision "NN%" with the same treatment
                        // Traits use.
                        ConfidenceChip(uncertainty: pattern.uncertainty)
                    }
                }

                Spacer()
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - Pattern Detail

private struct PatternDetailView: View {
    let pattern: LifePattern

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var resonance: Int = 0
    @State private var refinement: String = ""
    @State private var feedbackSaved = false
    @State private var context: ContextEnricher.PatternContext?
    @State private var isLoadingContext = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    // Pattern statement
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Pattern")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                            .textCase(.uppercase)

                        Text(pattern.observation)
                            .font(.title3)
                            .fontWeight(.light)
                            .foregroundStyle(DS.Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()

                    // Confidence — shown as a band with the pattern's real
                    // propagated uncertainty rendered as a halo around the estimate.
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        HStack {
                            Text("Confidence")
                                .font(.caption)
                                .foregroundStyle(DS.Color.textTertiary)
                                .textCase(.uppercase)

                            Spacer()

                            ConfidenceChip(uncertainty: pattern.uncertainty)
                        }

                        UncertaintyBar(
                            value: pattern.confidence,
                            uncertainty: pattern.uncertainty,
                            color: .accentColor,
                            showMarker: false
                        )

                        Text("Based on \(pattern.sampleCount) observations")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    Divider()

                    // Layer context
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Pattern type")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                            .textCase(.uppercase)

                        Text(layerDescription)
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    // Pattern context (if loaded)
                    if !isLoadingContext, let context = context {
                        Divider()

                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("Context")
                                .font(.caption)
                                .foregroundStyle(DS.Color.textTertiary)
                                .textCase(.uppercase)

                            Text(ContextEnricher.shared.summarizeContext(context))
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                                .lineSpacing(2)
                        }
                    }

                    Spacer(minLength: DS.Space.xxxl)

                    Divider()

                    // Feedback
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        Text("Does this ring true?")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                            .textCase(.uppercase)

                        HStack(spacing: DS.Space.md) {
                            Button(action: { resonance = -1; saveFeedback() }) {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .font(.title3)
                                    .foregroundStyle(resonance == -1 ? Color(hex: "#EF4444") : DS.Color.textTertiary)
                            }

                            Button(action: { resonance = 0; saveFeedback() }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(resonance == 0 ? Color.accentColor : DS.Color.textTertiary)
                            }

                            Button(action: { resonance = 1; saveFeedback() }) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.title3)
                                    .foregroundStyle(resonance == 1 ? Color(hex: "#10B981") : DS.Color.textTertiary)
                            }

                            Spacer()

                            if feedbackSaved {
                                Text("Feedback saved")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: "#10B981"))
                            }
                        }

                        TextField("Optional: refine or correct this pattern", text: $refinement, axis: .vertical)
                            .font(.caption)
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineLimit(2...4)
                            .padding(DS.Space.sm)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }

                    Spacer(minLength: DS.Space.xxxl)

                    // Explore button
                    Button(action: { /* seed a question */ }) {
                        Text(pattern.explorableQuestion)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(DS.Space.md)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                }
                .padding(DS.Space.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await loadContext() }
        }
    }

    private func loadContext() async {
        isLoadingContext = true
        do {
            let enricher = ContextEnricher.shared
            let processor = FeedbackProcessor.shared
            let feedbackMap = try processor.loadPatternFeedback(modelContext: modelContext)
            let patternFeedback = feedbackMap[pattern.id] ?? []

            context = try enricher.enrichPattern(
                pattern,
                modelContext: modelContext,
                feedback: patternFeedback
            )
        } catch {
            context = nil
        }
        isLoadingContext = false
    }

    private func saveFeedback() {
        do {
            let feedback = PatternFeedback(
                patternId: pattern.id,
                resonance: resonance,
                refinement: refinement.isEmpty ? nil : refinement
            )
            modelContext.insert(feedback)
            try modelContext.save()
            withAnimation(.easeInOut(duration: 0.3)) {
                feedbackSaved = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    feedbackSaved = false
                }
            }
        } catch {
            // Silent fail
        }
    }

    private var layerDescription: String {
        switch pattern.layer {
        case .habitState:
            return "This pattern connects a habit to your state (mood, energy, stress, or focus)."
        case .personState:
            return "This pattern connects time with a person to changes in your state."
        case .chapterState:
            return "This pattern describes a distinct emotional tone during a chapter of your life."
        case .habitChapter:
            return "This pattern shows that a habit is consistent across different chapters — it's part of your core rhythm."
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PatternsView()
    }
}
