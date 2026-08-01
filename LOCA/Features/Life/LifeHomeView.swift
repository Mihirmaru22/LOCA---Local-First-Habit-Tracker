//
//  LifeHomeView.swift
//  LOCA
//
//  P1A — Life tab root. Replaces the eye-icon fullScreenCover flow with a
//  first-class tab. Absorbs PersonalLifeListView; reorganises IA into three
//  clear sections: Today's Read, Browse, Your Questions.
//
//  P1B — Plain-language pass: "Traits" → "Your Tendencies", subtitle dedupe,
//  first-run onboarding, accessibility labels on all icon actions.
//

import SwiftUI
import SwiftData

// MARK: - LifeHomeView

struct LifeHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("life.onboardingSeen") private var onboardingSeen = false

    @State private var scene: PresentScene = .empty
    @State private var composedViews: [ComposedView] = []
    @State private var isLoadingScene = true
    @State private var isComposing = false
    @State private var showPresent = false
    @State private var showNewQuestion = false
    @State private var question = ""
    @State private var selectedDateRange: LifeDateRange = .last6Months

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    todaysReadSection
                    Divider().padding(.horizontal, DS.Space.lg)
                    browseSection
                    Divider().padding(.horizontal, DS.Space.lg)
                    questionsSection
                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.top, DS.Space.md)
            }
            .navigationTitle("Life")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showNewQuestion = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .accessibilityLabel("Ask a question")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPresent) {
            PresentView()
        }
        .sheet(isPresented: $showNewQuestion) {
            LifeNewQuestionSheet(
                isPresented: $showNewQuestion,
                question: $question,
                selectedDateRange: $selectedDateRange,
                onSubmit: handleNewQuestion
            )
        }
        .sheet(isPresented: Binding(
            get: { !onboardingSeen },
            set: { if !$0 { onboardingSeen = true } }
        )) {
            LifeOnboardingSheet { onboardingSeen = true }
        }
        .task { await loadData() }
    }

    // MARK: - Today's Read

    private var todaysReadSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Today's Read")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DS.Space.lg)

            if isLoadingScene {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Color.surface)
                    .frame(height: 100)
                    .padding(.horizontal, DS.Space.lg)
            } else if scene.isEmpty {
                LifeReadEmptyCard()
                    .padding(.horizontal, DS.Space.lg)
            } else {
                Button(action: { showPresent = true }) {
                    LifeReadCard(scene: scene)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open today's read")
                .padding(.horizontal, DS.Space.lg)
            }
        }
    }

    // MARK: - Browse

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            browseTierLabel("Browse")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.md) {
                    LifeExploreCard(title: "This Week", subtitle: "Habits in review", icon: "calendar.badge.checkmark") { WeeklyDigestView() }
                    LifeExploreCard(title: "Monthly", subtitle: "Month at a glance", icon: "calendar") { MonthlyReviewView() }
                    LifeExploreCard(title: "Chapters", subtitle: "Life in intervals", icon: "book.pages") { ChapterListView() }
                    LifeExploreCard(title: "Events", subtitle: "Shifts in your rhythm", icon: "flag") { EventsView() }
                    LifeExploreCard(title: "People", subtitle: "Who's around you", icon: "person.2.fill") { PeopleView() }
                    LifeExploreCard(title: "Patterns", subtitle: "What repeats", icon: "sparkles") { PatternsView() }
                    LifeExploreCard(title: "Your Story", subtitle: "Your life story", icon: "book.pages.fill") { NarrativeView() }
                    LifeExploreCard(title: "Your Tendencies", subtitle: "How you're wired", icon: "person.fill") { TraitSummaryView() }
                    LifeExploreCard(title: "Connections", subtitle: "What moves with what", icon: "point.3.connected.trianglepath.dotted") { RelationshipGraphView() }
                    LifeExploreCard(title: "Your Direction", subtitle: "Where you're headed", icon: "arrow.forward.circle") { DirectionView() }
                    LifeExploreCard(title: "Life Scene", subtitle: "The whole picture", icon: "binoculars") { LifeSceneView() }
                    LifeExploreCard(title: "Your Feedback", subtitle: "What resonates", icon: "hand.thumbsup") { FeedbackAnalyticsView() }
                }
                .padding(.horizontal, DS.Space.lg)
            }

#if DEBUG
            browseTierLabel("Debug")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.md) {
                    LifeExploreCard(title: "Runtime Check", subtitle: "P0 verification gate", icon: "checkmark.shield") { LifeRuntimeSelfCheckView() }
                }
                .padding(.horizontal, DS.Space.lg)
            }
#endif
        }
    }

    private func browseTierLabel(_ label: String) -> some View {
        Text(label)
            .font(DS.Text.caption)
            .foregroundStyle(DS.Color.textSecondary)
            .textCase(.uppercase)
            .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Your Questions

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text("Your Questions")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, DS.Space.lg)

            if isComposing {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(DS.Space.lg)
            } else if composedViews.isEmpty {
                questionsEmptyState
            } else {
                ForEach(composedViews, id: \.id) { view in
                    NavigationLink {
                        PersonalLifeViewUI(composedView: view)
                    } label: {
                        LifeViewCard(composedView: view)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DS.Space.lg)
                }
            }
        }
    }

    private var questionsEmptyState: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Ask a question about your life and LOCA will show you the answer, not tell it.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

            Button(action: { showNewQuestion = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Ask a Question")
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Space.md)
                .background(.tint, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, DS.Space.lg)
    }

    // MARK: - Data Loading

    @MainActor
    private func loadData() async {
        scene = (try? PresentComposer.shared.compose(modelContext: modelContext)) ?? .empty
        isLoadingScene = false

        let cutoff = Date().addingTimeInterval(-365 * 86400)
        let descriptor = FetchDescriptor<ComposedView>(
            predicate: #Predicate { view in view.timestamp >= cutoff }
        )
        composedViews = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - New Question

    private func handleNewQuestion() {
        guard !question.isEmpty else { return }
        isComposing = true
        let (startDate, endDate) = selectedDateRange.dateRange

        Task {
            do {
                let engine = ViewCompositionEngine.shared
                engine.setModelContext(modelContext)
                let newView = try await engine.composeView(
                    question: question,
                    startDate: startDate,
                    endDate: endDate,
                    modelContext: modelContext
                )
                modelContext.insert(newView)
                try modelContext.save()
                await MainActor.run {
                    composedViews.insert(newView, at: 0)
                    question = ""
                    selectedDateRange = .last6Months
                    isComposing = false
                }
            } catch {
                await MainActor.run { isComposing = false }
            }
        }
    }
}

// MARK: - LifeDateRange

enum LifeDateRange: String, CaseIterable {
    case lastMonth   = "Last Month"
    case last3Months = "Last 3 Months"
    case last6Months = "Last 6 Months"
    case lastYear    = "Last Year"

    var dateRange: (Date, Date) {
        let now = Date()
        let cal = Calendar.current
        switch self {
        case .lastMonth:   return (cal.date(byAdding: .month, value: -1, to: now)!, now)
        case .last3Months: return (cal.date(byAdding: .month, value: -3, to: now)!, now)
        case .last6Months: return (cal.date(byAdding: .month, value: -6, to: now)!, now)
        case .lastYear:    return (cal.date(byAdding: .year,  value: -1, to: now)!, now)
        }
    }
}

// MARK: - LifeReadCard

private struct LifeReadCard: View {
    let scene: PresentScene

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            if !scene.timeContext.isEmpty {
                Text(scene.timeContext.capitalized)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            Text(scene.headline)
                .font(.title3)
                .fontWeight(.light)
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let support = scene.support {
                Text(support)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(2)
            }

            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border, lineWidth: 1))
    }
}

// MARK: - LifeReadEmptyCard

private struct LifeReadEmptyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Your daily read isn't ready yet.")
                .font(.title3)
                .fontWeight(.light)
                .foregroundStyle(DS.Color.textSecondary)

            Text("Check in to your habits to start seeing your daily read. LOCA needs a few days of data to say something honest.")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border, lineWidth: 1))
    }
}

// MARK: - LifeExploreCard

struct LifeExploreCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.tint)

                Text(title)
                    .font(DS.Text.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
            .padding(DS.Space.md)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LifeViewCard

private struct LifeViewCard: View {
    let composedView: ComposedView

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(composedView.question)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(2)

            HStack(spacing: DS.Space.md) {
                Label(
                    formattedDateRange(composedView.startDate, composedView.endDate),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
    }

    private func formattedDateRange(_ start: Date, _ end: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
}

// MARK: - LifeNewQuestionSheet

private struct LifeNewQuestionSheet: View {
    @Binding var isPresented: Bool
    @Binding var question: String
    @Binding var selectedDateRange: LifeDateRange
    let onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("What would you like to explore?")) {
                    TextEditor(text: $question)
                        .frame(minHeight: 80)
                }

                Section(header: Text("Time Period")) {
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(LifeDateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }

                Section {
                    Button(action: {
                        onSubmit()
                        isPresented = false
                    }) {
                        HStack {
                            Spacer()
                            Text("Compose View")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(question.isEmpty)
                }
            }
            .navigationTitle("Ask About Your Life")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}

// MARK: - LifeRuntimeSelfCheckView (DEBUG only)

#if DEBUG
struct LifeRuntimeSelfCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var checks: [CheckRow] = []
    @State private var isReseeding = false

    struct CheckRow: Identifiable {
        let id = UUID()
        let label: String
        let actual: String
        let expected: String
        let pass: Bool
    }

    var body: some View {
        List {
            Section("Entity Counts") {
                ForEach(checks.filter {
                    let dataIntegrity = ["Provenance JSON", "UncertaintyType", "Chapter→Event link"]
                    let p0Gate = ["Habit bridge signals", "Dimension-tagged signals", "Organic state (today)"]
                    return !dataIntegrity.contains($0.label) && !p0Gate.contains($0.label)
                }) { row in checkCell(row) }
            }
            Section("Data Integrity") {
                ForEach(checks.filter {
                    ["Provenance JSON", "UncertaintyType", "Chapter→Event link"].contains($0.label)
                }) { row in checkCell(row) }
            }
            Section("P0 Runtime Gate") {
                ForEach(checks.filter {
                    ["Habit bridge signals", "Dimension-tagged signals", "Organic state (today)"].contains($0.label)
                }) { row in checkCell(row) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Runtime Check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isReseeding ? "Reseeding…" : "Reset & Reseed") {
                    isReseeding = true
                    LifeSeeder.resetAndReseed(context: modelContext)
                    runChecks()
                    isReseeding = false
                }
                .disabled(isReseeding)
            }
        }
        .onAppear { runChecks() }
    }

    @ViewBuilder
    private func checkCell(_ row: CheckRow) -> some View {
        HStack(spacing: DS.Space.sm) {
            Image(systemName: row.pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(row.pass ? .green : .red)
                .font(.body)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.label)
                    .font(.body)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("\(row.actual)  /  expected \(row.expected)")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func runChecks() {
        var rows: [CheckRow] = []

        func countOf<T: PersistentModel>(_ type: T.Type) -> Int {
            (try? modelContext.fetchCount(FetchDescriptor<T>())) ?? -1
        }

        func countCheck(_ label: String, count: Int, expected: Int, tolerance: Int = 0) -> CheckRow {
            CheckRow(label: label, actual: "\(count)", expected: "\(expected)",
                     pass: abs(count - expected) <= tolerance)
        }

        rows.append(countCheck("InferredState",    count: countOf(InferredState.self),    expected: 720, tolerance: 4))
        rows.append(countCheck("LifeEvent",        count: countOf(LifeEvent.self),         expected: 1))
        rows.append(countCheck("Chapter",          count: countOf(Chapter.self),           expected: 2))
        rows.append(countCheck("Person",           count: countOf(Person.self),            expected: 3))
        rows.append(countCheck("PersonAppearance", count: countOf(PersonAppearance.self),  expected: 72, tolerance: 10))
        rows.append(countCheck("Trait",            count: countOf(Trait.self),             expected: 6))
        rows.append(countCheck("Direction",        count: countOf(Direction.self),         expected: 1))
        rows.append(countCheck("Fork",             count: countOf(Fork.self),              expected: 2))
        rows.append(countCheck("SignalEvent",      count: countOf(SignalEvent.self),       expected: 28, tolerance: 2))

        var stateDesc = FetchDescriptor<InferredState>(); stateDesc.fetchLimit = 1
        let firstState = (try? modelContext.fetch(stateDesc))?.first
        let hasProvenance = firstState?.energyProvenanceJSON != nil
        rows.append(CheckRow(label: "Provenance JSON", actual: hasProvenance ? "present" : "nil",
                             expected: "present", pass: hasProvenance))

        let hasUncType = firstState?.energyUncertaintyTypeRaw != nil
        rows.append(CheckRow(label: "UncertaintyType", actual: hasUncType ? "present" : "nil",
                             expected: "present", pass: hasUncType))

        let chaptersWithEvent = ((try? modelContext.fetch(FetchDescriptor<Chapter>())) ?? [])
            .filter { $0.openingEventId != nil }.count
        rows.append(CheckRow(label: "Chapter→Event link", actual: "\(chaptersWithEvent)",
                             expected: "≥1", pass: chaptersWithEvent >= 1))

        // P0 Runtime Gate — verifies organic pipeline production without seeded data.
        let now = Date()
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -90, to: now)!
        let recentSignals = (try? modelContext.fetch(
            FetchDescriptor<SignalEvent>(predicate: #Predicate { $0.timestamp >= windowStart })
        )) ?? []
        let explicitLogs = recentSignals.filter { $0.source == .explicitLog }
        let dimensionKeys: Set<String> = ["energy", "mood", "stress", "focus"]
        let dimensionTagged = explicitLogs.filter { signal in
            dimensionKeys.contains { signal.metadata[$0] != nil }
        }
        rows.append(CheckRow(label: "Habit bridge signals",
                             actual: "\(explicitLogs.count)", expected: "≥1",
                             pass: explicitLogs.count >= 1))
        rows.append(CheckRow(label: "Dimension-tagged signals",
                             actual: "\(dimensionTagged.count)", expected: "≥1",
                             pass: dimensionTagged.count >= 1))

        let todayStart = calendar.startOfDay(for: now)
        let todayStateCount = (try? modelContext.fetchCount(
            FetchDescriptor<InferredState>(predicate: #Predicate { $0.hourStart >= todayStart })
        )) ?? 0
        rows.append(CheckRow(label: "Organic state (today)",
                             actual: "\(todayStateCount)", expected: "≥1",
                             pass: todayStateCount >= 1))

        checks = rows
    }
}
#endif

// MARK: - Preview

#Preview {
    LifeHomeView()
}
