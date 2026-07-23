//
//  SimpleHabitCreationView.swift
//  LOCA
//
//  Phase 2.1 — Habit Creation with Metric Type Selection
//
//  Two-step form: (1) habit name, (2) metric type (binary or quantitative with unit).
//  For quantitative, unit is inferred from name with ability to override.
//  Total flow ~15 seconds.
//

import SwiftUI
import SwiftData

struct SimpleHabitCreationView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var habitName = ""
    @State private var metricType: HabitBoard.MetricType = .binary
    @State private var selectedUnit: UnitOption = .minutes
    @State private var isSaving = false
    @State private var showSaveError = false
    @State private var step: Step = .name
    @FocusState private var nameFocused: Bool

    var onHabitCreated: ((UUID) -> Void)?

    var isValid: Bool {
        !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    enum Step {
        case name
        case metricType
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Space.lg) {
                Spacer()

                VStack(spacing: DS.Space.md) {
                    switch step {
                    case .name:
                        nameStep
                    case .metricType:
                        metricTypeStep
                    }
                }
                .padding(DS.Space.lg)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.background)
            .navigationTitle("")
            .inlineNavigationTitleDisplay()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(step == .name ? "Next" : "Start") {
                        if step == .name {
                            advanceToMetricType()
                        } else {
                            createHabit()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled((step == .name && !isValid) || isSaving)
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(400))
                nameFocused = true
            }
            .alert("Couldn't Create Habit", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
    }

    private var nameStep: some View {
        VStack(spacing: DS.Space.md) {
            Text("What habit do you want to build?")
                .font(DS.Text.heading)
                .foregroundStyle(DS.Color.textPrimary)

            TextField("e.g. Morning run", text: $habitName)
                .font(DS.Text.body)
                .textFieldStyle(.roundedBorder)
                .focused($nameFocused)
                .submitLabel(.next)
                .onSubmit {
                    if isValid {
                        advanceToMetricType()
                    }
                }
        }
    }

    private var metricTypeStep: some View {
        VStack(spacing: DS.Space.lg) {
            Text("How do you want to track this?")
                .font(DS.Text.heading)
                .foregroundStyle(DS.Color.textPrimary)

            VStack(spacing: DS.Space.md) {
                Button(action: { metricType = .binary }) {
                    HStack(spacing: DS.Space.md) {
                        Image(systemName: metricType == .binary ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(metricType == .binary ? ColorPalette[0] : .secondary)

                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("Daily check-off")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Done or not done")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                }
                .buttonStyle(.plain)

                Button(action: { metricType = .quantitative }) {
                    HStack(spacing: DS.Space.md) {
                        Image(systemName: metricType == .quantitative ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(metricType == .quantitative ? ColorPalette[0] : .secondary)

                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("Track an amount")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Miles, minutes, pages, etc.")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                }
                .buttonStyle(.plain)
            }

            if metricType == .quantitative {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("Unit")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)

                    Menu {
                        ForEach(UnitOption.Category.allCases, id: \.self) { category in
                            Section(category.rawValue) {
                                ForEach(category.units, id: \.self) { unit in
                                    Button(unit.displayName) {
                                        selectedUnit = unit
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedUnit.displayName)
                                .foregroundStyle(DS.Color.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        .font(DS.Text.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                }
            }
        }
    }

    private func advanceToMetricType() {
        if let inferred = UnitInference.inferUnit(from: habitName) {
            selectedUnit = inferred
        }
        step = .metricType
    }

    private func createHabit() {
        guard isValid else { return }
        isSaving = true

        let trimmed = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextColorIndex = nextColorIndexForNewHabit()
        let unitLabel = metricType == .quantitative ? selectedUnit.label : nil

        let board = HabitBoard(
            name: trimmed,
            metricType: metricType.rawValue,
            targetValue: nil,
            unitLabel: unitLabel,
            colorIndex: nextColorIndex
        )

        modelContext.insert(board)

        do {
            try modelContext.save()
            let createdID = board.id
            dismiss()
            onHabitCreated?(createdID)
        } catch {
            modelContext.rollback()
            isSaving = false
            showSaveError = true
        }
    }

    private func nextColorIndexForNewHabit() -> Int {
        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<HabitBoard>(predicate: #Predicate { $0.archivedAt == nil }))) ?? 0
        return existingCount % ColorPalette.count
    }
}

#Preview {
    @MainActor
    func makePreviewContainer() -> ModelContainer {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }

    NavigationStack {
        SimpleHabitCreationView()
            .modelContainer(makePreviewContainer())
    }
}
