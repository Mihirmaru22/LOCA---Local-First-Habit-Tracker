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
                ExploreCard(title: "Your Life", subtitle: "The whole picture", icon: "telescope") {
                    LifeSceneView()
                }
                ExploreCard(title: "Chapters", subtitle: "Life in intervals", icon: "book.pages") {
                    ChapterListView()
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

// MARK: - Preview

#Preview {
    PersonalLifeListView()
}
