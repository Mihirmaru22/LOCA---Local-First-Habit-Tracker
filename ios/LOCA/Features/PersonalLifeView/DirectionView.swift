//
//  DirectionView.swift
//  LOCA
//
//  Phase 7, Sessions 7.1 + 7.2 — The Direction surface.
//
//  Shows the active Direction (the felt toward-what), its forks, and — 7.2 —
//  the trajectory context: what the life model says about the time this
//  Direction was active. The trajectory is evidence, never advice.
//
//  The "no preacher" refusal is architectural: nothing here suggests what the
//  user should do. The trajectory section shows only what was — states,
//  baselines, chapter shape — and nothing more. No sentences ending in "so
//  you should", no arrows pointing at a recommended choice.
//

import SwiftUI
import SwiftData

// MARK: - Direction View

struct DirectionView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var activeDirection: Direction?
    @State private var forks: [Fork] = []
    @State private var showCapture = false
    @State private var trajectoryContext: TrajectoryContext?
    @State private var currentChapterId: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                if let dir = activeDirection {
                    activeDirectionContent(dir)
                } else {
                    emptyState
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(.top, DS.Space.md)
        }
        .navigationTitle("Your Direction")
        .inlineNavigationTitleDisplay()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if activeDirection != nil {
                    Button("Update") { showCapture = true }
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showCapture) {
            DirectionCaptureView(currentChapterId: currentChapterId) { _ in
                load()
            }
        }
        .task { load() }
    }

    // MARK: - Active Direction Content

    private func activeDirectionContent(_ dir: Direction) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            // The toward-what statement.
            statementCard(dir)

            // Values and Intentions.
            if !dir.values.isEmpty || !dir.intentions.isEmpty {
                valuesIntentionsSection(dir)
            }

            // Settledness.
            settledSection(dir)

            // Trajectory context (7.2): what the life model says about this time.
            if let ctx = trajectoryContext {
                trajectorySection(ctx, dir: dir)
            }

            // Forks.
            if !forks.isEmpty {
                forksSection
            }

            // Add fork.
            addForkButton(dir)
        }
    }

    // MARK: - Statement Card

    private func statementCard(_ dir: Direction) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Where you are")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DS.Space.lg)

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(dir.statement)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(dir.capturedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(DS.Space.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border, lineWidth: 1)
            )
            .padding(.horizontal, DS.Space.lg)
        }
    }

    // MARK: - Values / Intentions

    private func valuesIntentionsSection(_ dir: Direction) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            if !dir.values.isEmpty {
                TokenSection(label: "What matters", tokens: dir.values, color: .accentColor)
            }
            if !dir.intentions.isEmpty {
                TokenSection(label: "Moving toward", tokens: dir.intentions, color: DS.Color.textSecondary)
            }
        }
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Settledness

    private func settledSection(_ dir: Direction) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            SectionLabel(text: "How settled this feels")

            HStack(spacing: DS.Space.sm) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .frame(height: 6)
                            .foregroundStyle(DS.Color.surfaceRecessed)

                        RoundedRectangle(cornerRadius: 3)
                            .frame(width: geo.size.width * dir.settledness, height: 6)
                            .foregroundStyle(settledColor(dir.settledness))
                    }
                }
                .frame(height: 6)

                Text(settledLabel(dir.settledness))
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(width: 100, alignment: .trailing)
            }
        }
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Trajectory Section (7.2)

    private func trajectorySection(_ ctx: TrajectoryContext, dir: Direction) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            SectionLabel(text: "What the life model says about this time")

            if let chapter = ctx.chapter {
                TrajectoryCard(
                    headline: chapter.name ?? "Unnamed Chapter",
                    detail: chapterDetail(chapter),
                    icon: "book.pages"
                )
            }

            if let stateShift = ctx.stateShift {
                TrajectoryCard(
                    headline: stateShift.headline,
                    detail: stateShift.detail,
                    icon: "waveform.path"
                )
            }

            Text("This is what was, not what should be.")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .italic()
        }
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Forks Section

    private var forksSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            SectionLabel(text: "Open Questions")

            ForEach(forks) { fork in
                ForkCard(fork: fork, onResolve: { resolve(fork) })
            }
        }
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Add Fork Button

    private func addForkButton(_ dir: Direction) -> some View {
        Menu {
            ForEach(ForkKind.allCases, id: \.self) { kind in
                Button(kind.label) { addFork(kind: kind, dir: dir) }
            }
        } label: {
            Label("Add an open question", systemImage: "arrow.triangle.branch")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, DS.Space.lg)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        LifeEmptyState(
            icon: "arrow.forward.circle",
            headline: "No direction set",
            message: "Your direction is a statement of where you're headed — what matters to you right now. It's optional, but it helps LOCA understand your context.",
            action: LifeEmptyStateAction(label: "Set my direction") { showCapture = true }
        )
    }

    // MARK: - Data Loading

    private func load() {
        // Active Direction.
        let descriptor = FetchDescriptor<Direction>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        activeDirection = (try? modelContext.fetch(descriptor))?.first

        // Current chapter (for capture linkage and trajectory).
        let chapterDesc = FetchDescriptor<Chapter>(
            predicate: #Predicate { $0.isCurrentChapter }
        )
        let currentChapter = (try? modelContext.fetch(chapterDesc))?.first
        currentChapterId = currentChapter?.id

        // Forks linked to the active direction.
        if let dir = activeDirection {
            let dirId = dir.id
            let forkDesc = FetchDescriptor<Fork>(
                predicate: #Predicate { $0.directionId == dirId },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            forks = (try? modelContext.fetch(forkDesc)) ?? []
        }

        // Trajectory context (7.2).
        trajectoryContext = buildTrajectoryContext(direction: activeDirection, chapter: currentChapter)
    }

    // MARK: - Trajectory Context (7.2)

    /// Assemble the trajectory context: the chapter shape and any notable
    /// state shift during the Direction's active period. Evidence only —
    /// no prescription.
    private func buildTrajectoryContext(direction: Direction?, chapter: Chapter?) -> TrajectoryContext? {
        guard let dir = direction else { return nil }

        var ctx = TrajectoryContext()
        ctx.chapter = chapter

        // State shift: compare mean states in the two weeks before vs. two weeks
        // after the Direction was captured.
        let capturedAt = dir.capturedAt
        let twoWeeks: TimeInterval = 14 * 86400
        let beforeStart = capturedAt.addingTimeInterval(-twoWeeks)
        let afterEnd = capturedAt.addingTimeInterval(twoWeeks)

        let stateDesc = FetchDescriptor<InferredState>(
            predicate: #Predicate { $0.timestamp >= beforeStart && $0.timestamp <= afterEnd },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let states = (try? modelContext.fetch(stateDesc)) ?? []

        let before = states.filter { $0.timestamp < capturedAt }
        let after  = states.filter { $0.timestamp >= capturedAt }

        guard !before.isEmpty, !after.isEmpty else { return ctx }

        let meanMoodBefore = mean(before.map { $0.mood })
        let meanMoodAfter  = mean(after.map  { $0.mood })
        let delta = meanMoodAfter - meanMoodBefore

        if abs(delta) >= 0.04 {
            let dir2 = delta > 0 ? "higher" : "lower"
            ctx.stateShift = StateShift(
                headline: "Mood has been \(dir2) since you named this direction",
                detail: "Mean mood \(delta > 0 ? "+" : "")\(Int((delta * 100).rounded()))% in the two weeks after vs. two weeks before."
            )
        }

        return ctx.chapter != nil || ctx.stateShift != nil ? ctx : nil
    }

    // MARK: - Fork Actions

    private func addFork(kind: ForkKind, dir: Direction) {
        let fork = Fork(statement: "", kind: kind, directionId: dir.id, chapterId: currentChapterId)
        modelContext.insert(fork)
        try? modelContext.save()
        forks.insert(fork, at: 0)
    }

    private func resolve(_ fork: Fork) {
        fork.resolved = true
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func settledColor(_ v: Double) -> Color {
        v < 0.4 ? DS.Color.textTertiary : Color.accentColor
    }

    private func settledLabel(_ v: Double) -> String {
        switch v {
        case ..<0.25: return "Figuring it out"
        case ..<0.5:  return "Getting clearer"
        case ..<0.75: return "Pretty sure"
        default:      return "I know where I'm going"
        }
    }

    private func chapterDetail(_ chapter: Chapter) -> String {
        let b = Int((chapter.baselineMood * 100).rounded())
        return "Baseline mood this chapter: \(b)%. Your current chapter shapes the life model's reading."
    }

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Trajectory Context

private struct TrajectoryContext {
    var chapter: Chapter?
    var stateShift: StateShift?
}

private struct StateShift {
    let headline: String
    let detail: String
}

// MARK: - Sub-Views

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(DS.Text.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.textSecondary)
            .textCase(.uppercase)
    }
}

private struct TokenSection: View {
    let label: String
    let tokens: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .textCase(.uppercase)

            FlowLayout(spacing: DS.Space.xs) {
                ForEach(tokens, id: \.self) { token in
                    Text(token)
                        .font(.caption)
                        .padding(.horizontal, DS.Space.sm)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.12), in: Capsule())
                        .foregroundStyle(color)
                }
            }
        }
    }
}

private struct TrajectoryCard: View {
    let headline: String
    let detail: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(headline)
                    .font(DS.Text.body)
                    .fontWeight(.medium)
                    .foregroundStyle(DS.Color.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
    }
}

private struct ForkCard: View {
    let fork: Fork
    let onResolve: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            Image(systemName: fork.resolved ? "checkmark.circle.fill" : fork.kind.icon)
                .font(.callout)
                .foregroundStyle(fork.resolved ? DS.Color.textTertiary : Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                if fork.statement.isEmpty {
                    Text(fork.kind.label)
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textTertiary)
                        .italic()
                } else {
                    Text(fork.statement)
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                Text(fork.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Spacer()

            if !fork.resolved {
                Button("Mark resolved") { onResolve() }
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
        .opacity(fork.resolved ? 0.6 : 1.0)
    }
}

// MARK: - Flow Layout

/// Simple wrapping horizontal layout for token chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DirectionView()
    }
}
