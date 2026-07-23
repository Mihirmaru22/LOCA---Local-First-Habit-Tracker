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
    @State private var step: Step = .mode
    @State private var selectedTemplate: HabitTemplate?
    @State private var templateReminderTime: String?
    @FocusState private var nameFocused: Bool

    var onHabitCreated: ((UUID) -> Void)?

    var isValid: Bool {
        !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    enum Step {
        case mode          // Choose: quick start or templates
        case name
        case metricType
        case template      // Template customization
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Space.lg) {
                Spacer()

                VStack(spacing: DS.Space.md) {
                    switch step {
                    case .mode:
                        modeStep
                    case .name:
                        nameStep
                    case .metricType:
                        metricTypeStep
                    case .template:
                        templateStep
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
                    Button(actionButtonLabel) {
                        handleActionButton()
                    }
                    .fontWeight(.semibold)
                    .disabled(isActionDisabled || isSaving)
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

    private var actionButtonLabel: String {
        switch step {
        case .mode, .template:
            return "Next"
        case .name:
            return "Next"
        case .metricType:
            return "Start"
        }
    }

    private var isActionDisabled: Bool {
        switch step {
        case .mode:
            return false
        case .name:
            return !isValid
        case .metricType, .template:
            return false
        }
    }

    private func handleActionButton() {
        switch step {
        case .mode:
            break  // Handled by button actions in modeStep
        case .name:
            advanceToMetricType()
        case .metricType:
            createHabit()
        case .template:
            createHabitFromTemplate()
        }
    }

    private var modeStep: some View {
        VStack(spacing: DS.Space.lg) {
            Text("How would you like to start?")
                .font(DS.Text.heading)
                .foregroundStyle(DS.Color.textPrimary)

            VStack(spacing: DS.Space.md) {
                Button(action: { step = .name }) {
                    HStack(spacing: DS.Space.md) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(ColorPalette[0])

                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("Quick Start")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Create your own habit")
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

                Button(action: { step = .template }) {
                    HStack(spacing: DS.Space.md) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(ColorPalette[0])

                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text("Browse Templates")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Research-backed habits")
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
        }
    }

    private var templateStep: some View {
        TemplatePickerView(
            onSelect: { template in
                selectedTemplate = template
                habitName = template.name
                metricType = template.metricType
                selectedUnit = template.suggestedUnit ?? .minutes
                templateReminderTime = template.suggestedReminderTime
                step = .metricType
            },
            onDismiss: { step = .mode }
        )
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
            if let template = selectedTemplate {
                Text("Review template settings")
                    .font(DS.Text.heading)
                    .foregroundStyle(DS.Color.textPrimary)

                VStack(alignment: .leading, spacing: DS.Space.md) {
                    HStack {
                        Text(template.emoji)
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text(habitName)
                                .font(DS.Text.body)
                                .fontWeight(.semibold)
                            Text(template.description)
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }

                    if let goal = template.suggestedGoal, let unit = template.suggestedUnit {
                        HStack {
                            Text("Goal:")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                            Spacer()
                            Text("\(Int(goal)) \(unit.label) per day")
                                .font(DS.Text.body)
                                .fontWeight(.semibold)
                        }
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }

                    if let time = templateReminderTime {
                        HStack {
                            Text("Reminder:")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                            Spacer()
                            Text(time)
                                .font(DS.Text.body)
                                .fontWeight(.semibold)
                        }
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                }
            } else {
                Text("How do you want to track this?")
                    .font(DS.Text.heading)
                    .foregroundStyle(DS.Color.textPrimary)
            }

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
        if selectedTemplate == nil {
            if let inferred = UnitInference.inferUnit(from: habitName) {
                selectedUnit = inferred
            }
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
            targetValue: selectedTemplate?.suggestedGoal,
            unitLabel: unitLabel,
            colorIndex: nextColorIndex,
            createdAt: Date()
        )

        board.preferredReminderTime = templateReminderTime
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

    private func createHabitFromTemplate() {
        createHabit()
    }

    private func nextColorIndexForNewHabit() -> Int {
        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<HabitBoard>(predicate: #Predicate { $0.archivedAt == nil }))) ?? 0
        return existingCount % ColorPalette.count
    }
}

// MARK: - Preview

@MainActor
private func makeHabitCreationPreviewContainer() -> ModelContainer {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    // try! is acceptable in a #Preview fixture (Engineering Principles §Previews).
    return try! ModelContainer(for: schema, configurations: [config])
}

#Preview {
    NavigationStack {
        SimpleHabitCreationView()
            .modelContainer(makeHabitCreationPreviewContainer())
    }
}
