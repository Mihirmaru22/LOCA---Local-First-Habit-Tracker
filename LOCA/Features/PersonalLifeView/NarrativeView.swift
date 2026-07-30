//
//  NarrativeView.swift
//  LOCA
//
//  Phase 9, Session 9.2 — Life narrative view.
//
//  Read the composed narrative of your life: the arc, the supporting themes,
//  and how they weave together. Tap a thread to explore it more deeply.
//

import SwiftUI
import SwiftData

struct NarrativeView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var narrative: LifeNarrative?
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
            } else if let narrative = narrative {
                narrativeContent(narrative)
            } else {
                emptyState
            }
        }
        .navigationTitle("Your Narrative")
        .largeNavigationTitleDisplay()
        .task { await loadNarrative() }
    }

    @State private var arcResonance: Double = 0.5
    @State private var narrativeNotes: String = ""
    @State private var feedbackSaved = false

    private func narrativeContent(_ narrative: LifeNarrative) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            // Arc
            VStack(alignment: .leading, spacing: DS.Space.md) {
                Text("Your arc")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                    .textCase(.uppercase)

                Text(narrative.arc)
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(4)

                // C5: the arc's confidence — Rule D (weakest-link) over its patterns.
                // Previously computed but never shown.
                ConfidenceChip(uncertainty: narrative.arcUncertainty)

                // Arc feedback
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    HStack {
                        Text("Does this ring true?")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                        Slider(value: $arcResonance, in: 0...1)
                            .tint(Color.accentColor)
                            .onChange(of: arcResonance) { _ in saveNarrativeFeedback() }
                    }
                }
            }

            Divider()

            // Threads
            if !narrative.threads.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    Text("Supporting themes")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        ForEach(narrative.threads, id: \.title) { thread in
                            VStack(alignment: .leading, spacing: DS.Space.sm) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(thread.title)
                                        .font(.headline)
                                        .foregroundStyle(DS.Color.textPrimary)

                                    Spacer()

                                    // C5: thread confidence (Rule D over its patterns).
                                    ConfidenceChip(uncertainty: thread.uncertainty)
                                }

                                Text(thread.body)
                                    .font(DS.Text.body)
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(DS.Space.md)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                        }
                    }
                }

                Divider()
            }

            // Full narrative
            VStack(alignment: .leading, spacing: DS.Space.md) {
                Text("The full story")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                    .textCase(.uppercase)

                Text(narrative.body)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                Text("Composed on \(narrative.generatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
                    .italic()
            }

            Spacer(minLength: DS.Space.xxxl)
        }
        .padding(DS.Space.xl)
    }

    private var emptyState: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "book.pages.fill")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text("Your narrative")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("LOCA will weave your patterns into a life story when enough patterns emerge.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DS.Space.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadNarrative() async {
        isLoading = true
        do {
            let patterns = try PatternDetectionEngine.shared.detectPatterns(modelContext: modelContext)
            let chapters = try modelContext.fetch(FetchDescriptor<Chapter>())
            let directions = try modelContext.fetch(
                FetchDescriptor<Direction>(predicate: #Predicate { $0.isActive })
            )

            let composer = NarrativeComposer.shared
            narrative = composer.composeNarrative(
                patterns: patterns,
                chapters: chapters,
                direction: directions.first,
                modelContext: modelContext
            )
        } catch {
            narrative = nil
        }
        isLoading = false
    }

    private func saveNarrativeFeedback() {
        guard let narrative = narrative else { return }
        do {
            let feedback = NarrativeFeedback(
                arc: narrative.arc,
                resonance: arcResonance,
                notes: narrativeNotes.isEmpty ? nil : narrativeNotes
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NarrativeView()
    }
}
