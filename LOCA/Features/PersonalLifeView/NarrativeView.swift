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
                                Text(thread.title)
                                    .font(.headline)
                                    .foregroundStyle(DS.Color.textPrimary)

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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NarrativeView()
    }
}
