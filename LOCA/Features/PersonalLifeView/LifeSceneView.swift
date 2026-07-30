//
//  LifeSceneView.swift
//  LOCA
//
//  Phase 5 — The composed multi-entity Life Scene view
//  Shows chapters, traits, people, and cross-entity insights in one scroll
//

import SwiftUI
import SwiftData

struct LifeSceneView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var scene: ComposedScene?
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Composing your life scene…")
                    .frame(maxHeight: .infinity, alignment: .center)
            } else if let scene, !scene.isDataAbsent {
                // C1.4: only render sceneContent when real data exists.
                // isDataAbsent means no chapters and no global traits — the scene
                // is structurally absent, not merely uncertain.
                sceneContent(scene)
            } else {
                emptyState
            }
        }
        .navigationTitle("Your Life")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: refresh) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .disabled(isLoading)
            }
        }
        .task {
            if scene == nil { await compose() }
        }
    }

    // MARK: - Scene Content

    private func sceneContent(_ scene: ComposedScene) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                // Insights header
                if !scene.insights.isEmpty {
                    insightsSection(scene.insights)
                }

                // Chapter-by-chapter timeline
                if !scene.chapters.isEmpty {
                    chapterTimelineSection(scene.chapters)
                }

                // Global traits summary
                if !scene.traits.isEmpty {
                    traitsSection(scene.traits)
                }

                // People
                if !scene.people.isEmpty {
                    peopleSection(scene.people)
                }

                sceneFooter(scene)

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
    }

    // MARK: - Sections

    private func insightsSection(_ insights: [SceneInsight]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            LifeSceneSectionHeader(title: "Patterns", icon: "sparkles")

            VStack(spacing: DS.Space.sm) {
                ForEach(Array(insights.prefix(4).enumerated()), id: \.offset) { _, insight in
                    InsightRow(insight: insight)
                }
            }
        }
    }

    private func chapterTimelineSection(_ chapters: [ChapterSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            LifeSceneSectionHeader(title: "Chapters", icon: "book.pages")

            VStack(spacing: DS.Space.sm) {
                ForEach(chapters, id: \.chapter.id) { snapshot in
                    ChapterSceneCard(snapshot: snapshot)
                }
            }
        }
    }

    private func traitsSection(_ traits: [TraitSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            LifeSceneSectionHeader(title: "Your Traits", icon: "person.fill")

            VStack(spacing: DS.Space.sm) {
                ForEach(traits, id: \.traitType) { trait in
                    TraitSceneRow(trait: trait)
                }
            }
            .padding(DS.Space.md)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    private func peopleSection(_ snapshots: [PersonSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            LifeSceneSectionHeader(title: "People", icon: "person.2.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.sm) {
                    ForEach(snapshots.prefix(8), id: \.person.id) { snapshot in
                        PersonPill(snapshot: snapshot)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func sceneFooter(_ scene: ComposedScene) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Composed \(scene.generatedAt.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)

            if scene.overallUncertainty > 0.5 {
                Text("More data will sharpen this picture")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "binoculars")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text("Your Life Scene")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("LOCA needs a few weeks of data to compose your full life picture.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Compose Now") { Task { await compose() } }
                .buttonStyle(.bordered)
        }
        .padding(DS.Space.xl)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Compose

    private func refresh() {
        Task { await compose() }
    }

    private func compose() async {
        isLoading = true
        scene = try? MultiEntityComposer.shared.composeLifeScene(modelContext: modelContext)
        isLoading = false
    }
}

// MARK: - Section Header

private struct LifeSceneSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)
            Text(title)
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)
        }
    }
}

// MARK: - Insight Row

private struct InsightRow: View {
    let insight: SceneInsight

    private var iconName: String {
        switch insight.type {
        case .traitShift:        return "arrow.up.arrow.down"
        case .personPresence:    return "person.crop.circle"
        case .chapterContrast:   return "book.pages"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.sm) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
                .padding(.top, 2)

            Text(insight.text)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            ConfidenceDot(confidence: insight.confidence)
                .padding(.top, 5)
        }
        .padding(DS.Space.sm)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
    }
}

// MARK: - Chapter Scene Card

private struct ChapterSceneCard: View {
    let snapshot: ChapterSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if snapshot.chapter.isCurrentChapter {
                        Text("NOW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.tint)
                    }
                    if let chapterName = snapshot.chapter.name {
                        Text(chapterName)
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)
                    } else {
                        Text("Name this chapter →")
                            .font(DS.Text.body)
                            .fontWeight(.regular)
                            .italic()
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
                Spacer()
                Text("\(snapshot.chapter.durationInDays)d")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            // Top trait for this chapter
            if let topTrait = snapshot.traitsForChapter.max(by: { $0.value < $1.value }) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                    Text(topTrait.label)
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // People in this chapter
            if !snapshot.peopleForChapter.isEmpty {
                HStack(spacing: 4) {
                    ForEach(snapshot.peopleForChapter.prefix(3), id: \.person.id) { personSnapshot in
                        Text(personSnapshot.person.initials)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.accentColor.opacity(0.7), in: Circle())
                    }

                    if snapshot.peopleForChapter.count > 3 {
                        Text("+\(snapshot.peopleForChapter.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
            }
        }
        .padding(DS.Space.sm)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.control)
                .stroke(
                    snapshot.chapter.isCurrentChapter ? Color.accentColor.opacity(0.4) : DS.Color.border,
                    lineWidth: snapshot.chapter.isCurrentChapter ? 1.5 : 1
                )
        )
    }
}

// MARK: - Trait Scene Row

private struct TraitSceneRow: View {
    let trait: TraitSnapshot

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Text(trait.traitType.displayName)
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 90, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundStyle(DS.Color.surfaceRecessed)

                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: geo.size.width * trait.value, height: 4)
                        .foregroundStyle(trait.traitType.color)
                }
            }
            .frame(height: 4)

            Text(String(format: "%.0f%%", trait.value * 100))
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - Person Pill

private struct PersonPill: View {
    let snapshot: PersonSnapshot

    var body: some View {
        VStack(spacing: DS.Space.xs) {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(snapshot.person.primaryContext.color.opacity(0.15))

                Text(snapshot.person.initials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(snapshot.person.primaryContext.color)
            }

            Text(snapshot.person.name.components(separatedBy: " ").first ?? snapshot.person.name)
                .font(.caption2)
                .foregroundStyle(DS.Color.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 60)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LifeSceneView()
    }
}
