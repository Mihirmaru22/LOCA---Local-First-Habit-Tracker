//
//  PersonalLifeListView.swift
//  LOCA
//
//  Phase 4 — Personal Life list and question entry
//  Gateway to browsing composed Views and asking new questions
//

import SwiftUI
import SwiftData

struct PersonalLifeListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var composedViews: [ComposedView] = []
    @State private var showNewQuestionSheet = false
    @State private var isLoading = false
    @State private var question = ""
    @State private var selectedDateRange: DateRange = .last6Months

    enum DateRange: String, CaseIterable {
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case last6Months = "Last 6 Months"
        case lastYear = "Last Year"

        var dateRange: (Date, Date) {
            let now = Date()
            let calendar = Calendar.current

            switch self {
            case .lastMonth:
                let start = calendar.date(byAdding: .month, value: -1, to: now)!
                return (start, now)
            case .last3Months:
                let start = calendar.date(byAdding: .month, value: -3, to: now)!
                return (start, now)
            case .last6Months:
                let start = calendar.date(byAdding: .month, value: -6, to: now)!
                return (start, now)
            case .lastYear:
                let start = calendar.date(byAdding: .year, value: -1, to: now)!
                return (start, now)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Personal Life")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("See your life as you do—through your own lens, not ours.")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                    // MARK: - Explore (the auto-built structure)
                    exploreSection

                    Divider()
                        .padding(.horizontal, DS.Space.lg)

                    // MARK: - Questions (Ask → View)
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        Text("Your Questions")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, DS.Space.lg)

                        if isLoading {
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
                                    ViewCard(composedView: view)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, DS.Space.lg)
                            }
                        }
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
            }
            .navigationTitle("Personal Life")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showNewQuestionSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showNewQuestionSheet) {
                NewQuestionSheet(
                    isPresented: $showNewQuestionSheet,
                    question: $question,
                    selectedDateRange: $selectedDateRange,
                    onSubmit: handleNewQuestion
                )
            }
            .onAppear {
                loadComposedViews()
            }
        }
    }

    // MARK: - Explore Section

    private var exploreSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.md) {
                ExploreCard(title: "Your Life", subtitle: "The whole picture", icon: "binoculars") {
                    LifeSceneView()
                }
                ExploreCard(title: "Chapters", subtitle: "Life in intervals", icon: "book.pages") {
                    ChapterListView()
                }
                ExploreCard(title: "Events", subtitle: "Shifts in your rhythm", icon: "flag") {
                    EventsView()
                }
                ExploreCard(title: "People", subtitle: "Who's around you", icon: "person.2.fill") {
                    PeopleView()
                }
                ExploreCard(title: "Traits", subtitle: "Your dispositions", icon: "person.fill") {
                    TraitSummaryView()
                }
                ExploreCard(title: "Connections", subtitle: "What moves together", icon: "point.3.connected.trianglepath.dotted") {
                    RelationshipGraphView()
                }
                ExploreCard(title: "Direction", subtitle: "Where you're headed", icon: "arrow.forward.circle") {
                    DirectionView()
                }
                ExploreCard(title: "Patterns", subtitle: "What moves together", icon: "sparkles") {
                    PatternsView()
                }
                ExploreCard(title: "Narrative", subtitle: "Your life story", icon: "book.pages.fill") {
                    NarrativeView()
                }
                ExploreCard(title: "Feedback", subtitle: "Your learning loop", icon: "hand.thumbsup.fill") {
                    FeedbackAnalyticsView()
                }
                ExploreCard(title: "Sensor Gaps", subtitle: "Where data disagreed", icon: "exclamationmark.triangle") {
                    SensorConflictView()
                }
#if DEBUG
                ExploreCard(title: "Runtime Check", subtitle: "P0 verification gate", icon: "checkmark.shield") {
                    RuntimeSelfCheckView()
                }
#endif
            }
            .padding(.horizontal, DS.Space.lg)
        }
    }

    // MARK: - Questions Empty State

    private var questionsEmptyState: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Ask a question about your life and LOCA will show you the answer, not tell it.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

            Button(action: { showNewQuestionSheet = true }) {
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

    private func loadComposedViews() {
        let cutoff = Date().addingTimeInterval(-365 * 86400)
        let descriptor = FetchDescriptor<ComposedView>(
            predicate: #Predicate { view in
                view.timestamp >= cutoff
            }
        )
        composedViews = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func handleNewQuestion() {
        guard !question.isEmpty else { return }

        isLoading = true
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
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Show error toast
                }
            }
        }
    }
}

// MARK: - Explore Card

/// A tappable card in the horizontal Explore row that pushes one of the
/// auto-built structure surfaces (Life Scene, Chapters, People, Traits).
private struct ExploreCard<Destination: View>: View {
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

// MARK: - View Card

private struct ViewCard: View {
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
        let formatter = DateFormatter()
        formatter.dateStyle = .short

        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)

        return "\(startStr) – \(endStr)"
    }
}

// MARK: - New Question Sheet

private struct NewQuestionSheet: View {
    @Binding var isPresented: Bool
    @Binding var question: String
    @Binding var selectedDateRange: PersonalLifeListView.DateRange
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
                        ForEach(PersonalLifeListView.DateRange.allCases, id: \.self) { range in
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

// MARK: - P0 Runtime Self-Check (DEBUG only)

#if DEBUG
struct RuntimeSelfCheckView: View {
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
                ForEach(checks.filter { $0.label != "Provenance JSON" && $0.label != "UncertaintyType" && $0.label != "Chapter→Event link" }) { row in
                    checkCell(row)
                }
            }
            Section("Data Integrity") {
                ForEach(checks.filter { ["Provenance JSON", "UncertaintyType", "Chapter→Event link"].contains($0.label) }) { row in
                    checkCell(row)
                }
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
            let pass = abs(count - expected) <= tolerance
            return CheckRow(label: label, actual: "\(count)", expected: "\(expected)", pass: pass)
        }

        rows.append(countCheck("InferredState",    count: countOf(InferredState.self),     expected: 720, tolerance: 4))
        rows.append(countCheck("LifeEvent",        count: countOf(LifeEvent.self),          expected: 1))
        rows.append(countCheck("Chapter",          count: countOf(Chapter.self),            expected: 2))
        rows.append(countCheck("Person",           count: countOf(Person.self),             expected: 3))
        rows.append(countCheck("PersonAppearance", count: countOf(PersonAppearance.self),   expected: 72, tolerance: 10))
        rows.append(countCheck("Trait",            count: countOf(Trait.self),              expected: 6))
        rows.append(countCheck("Direction",        count: countOf(Direction.self),          expected: 1))
        rows.append(countCheck("Fork",             count: countOf(Fork.self),               expected: 2))
        rows.append(countCheck("SignalEvent",      count: countOf(SignalEvent.self),        expected: 28, tolerance: 2))

        // Integrity: provenance JSON on first state
        var stateDesc = FetchDescriptor<InferredState>(); stateDesc.fetchLimit = 1
        let firstState = (try? modelContext.fetch(stateDesc))?.first
        let hasProvenance = firstState?.energyProvenanceJSON != nil
        rows.append(CheckRow(label: "Provenance JSON", actual: hasProvenance ? "present" : "nil",
                             expected: "present", pass: hasProvenance))

        // Integrity: uncertainty type on first state
        let hasUncType = firstState?.energyUncertaintyTypeRaw != nil
        rows.append(CheckRow(label: "UncertaintyType", actual: hasUncType ? "present" : "nil",
                             expected: "present", pass: hasUncType))

        // Integrity: at least one chapter has openingEventId set
        var chapterDesc = FetchDescriptor<Chapter>()
        let chaptersWithEvent = ((try? modelContext.fetch(chapterDesc)) ?? [])
            .filter { $0.openingEventId != nil }.count
        rows.append(CheckRow(label: "Chapter→Event link", actual: "\(chaptersWithEvent)",
                             expected: "≥1", pass: chaptersWithEvent >= 1))

        checks = rows
    }
}
#endif

// MARK: - Preview

#Preview {
    PersonalLifeListView()
}
