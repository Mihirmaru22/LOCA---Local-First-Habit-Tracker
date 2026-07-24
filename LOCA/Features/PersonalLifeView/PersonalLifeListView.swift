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
            ZStack {
                if composedViews.isEmpty && !isLoading {
                    EmptyStateView(
                        action: { showNewQuestionSheet = true }
                    )
                } else {
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
                            .padding(DS.Space.lg)

                            // MARK: - Views List
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(DS.Space.lg)
                            } else {
                                ForEach(composedViews, id: \.id) { view in
                                    NavigationLink(destination: {
                                        PersonalLifeViewUI(composedView: view)
                                    }) {
                                        ViewCard(composedView: view)
                                    }
                                }
                            }

                            Spacer(minLength: DS.Space.xxxl)
                        }
                    }
                }
            }
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

// MARK: - Empty State

private struct EmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "eye.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            VStack(spacing: DS.Space.sm) {
                Text("No Perspectives Yet")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Ask a question about your life. LOCA will show you the answer, not tell it.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                HStack {
                    Image(systemName: "plus")
                    Text("Ask a Question")
                }
                .frame(maxWidth: .infinity)
                .padding(DS.Space.md)
                .background(.tint, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(DS.Space.lg)
        .frame(maxHeight: .infinity, alignment: .center)
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
