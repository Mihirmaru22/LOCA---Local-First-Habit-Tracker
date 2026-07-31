//
//  LifePatternCard.swift
//  LOCA
//
//  P1B — Life × Habit integration card shown in HabitDetailView's overview tab.
//  Surfaces any habitState patterns detected for this specific habit board.
//  Shows an honest empty state when data is too thin for a pattern.
//

import SwiftUI
import SwiftData

struct LifePatternCard: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @State private var patterns: [LifePattern] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Life")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Space.sm)
            } else if let pattern = patterns.first {
                patternContent(pattern)
            } else {
                emptyContent
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border, lineWidth: 1))
        .task { await loadPatterns() }
    }

    private func patternContent(_ pattern: LifePattern) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(pattern.observation)
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DS.Space.sm) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DS.Color.border)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.tint.opacity(0.7))
                            .frame(width: geo.size.width * pattern.confidence)
                    }
                }
                .frame(height: 4)

                Text("\(Int(pattern.confidence * 100))%")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
                    .monospacedDigit()
            }

            Text("\(pattern.sampleCount) days of data")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
    }

    private var emptyContent: some View {
        Text("No pattern detected yet. As you check in over time, LOCA will look for connections between this habit and your state.")
            .font(.caption)
            .foregroundStyle(DS.Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func loadPatterns() async {
        let engine = PatternDetectionEngine.shared
        let all = (try? engine.detectPatterns(modelContext: modelContext)) ?? []
        let name = board.name.lowercased()
        patterns = all.filter {
            $0.layer == .habitState &&
            $0.observation.localizedCaseInsensitiveContains(name)
        }
        isLoading = false
    }
}
