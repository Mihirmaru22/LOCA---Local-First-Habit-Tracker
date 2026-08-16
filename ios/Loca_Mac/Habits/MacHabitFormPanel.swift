import SwiftUI
import SwiftData

// MARK: - MacHabitFormPanel (Native Inset Grouped Habit Creation Modal)

/// Clean, native macOS Inset Grouped dialog for creating a new habit with strict title & value validation.
struct MacHabitFormPanel: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Form State
    @State private var habitName: String = ""
    @State private var colorIndex: Int = 1
    @State private var metricType: HabitBoard.MetricType = .binary
    @State private var targetValue: Double = 10.0
    @State private var selectedUnit: UnitOption = .minutes
    @State private var selectedSchedule: String = "Anytime"

    @FocusState private var isNameFocused: Bool

    private static let schedules = ["Anytime", "Morning", "Afternoon", "Evening"]
    private static let maxTitleLength: Int = 60

    private var trimmedName: String {
        String(habitName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxTitleLength))
    }

    private var isValid: Bool {
        guard !trimmedName.isEmpty else { return false }
        if metricType == .quantitative {
            return targetValue > 0
        }
        return true
    }

    private var activeColor: Color {
        ColorPalette[colorIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Header
            HStack {
                Text("New Habit")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                templateDropdownMenu
            }

            // Inset Grouped Table Container
            VStack(spacing: 0) {

                // Row 1: Habit Name
                HStack(spacing: 12) {
                    Text("Title")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    TextField("e.g. Morning Meditation", text: $habitName)
                        .font(.system(size: 12))
                        .textFieldStyle(.plain)
                        .focused($isNameFocused)
                        .onSubmit {
                            if isValid { saveHabit() }
                        }

                    if habitName.count > 45 {
                        Text("\(habitName.count)/\(Self.maxTitleLength)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(habitName.count > Self.maxTitleLength ? Color.red : DS.Color.textTertiary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().padding(.leading, 12)

                // Row 2: Metric Type Segment
                HStack(spacing: 12) {
                    Text("Goal Type")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    Picker("", selection: $metricType) {
                        Text("Check-In (Yes/No)").tag(HabitBoard.MetricType.binary)
                        Text("Target Amount").tag(HabitBoard.MetricType.quantitative)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                // Row 3: Target Details (If quantitative)
                if metricType == .quantitative {
                    Divider().padding(.leading, 12)

                    HStack(spacing: 12) {
                        Text("Daily Target")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .frame(width: 80, alignment: .leading)

                        HStack(spacing: 8) {
                            HStack(spacing: 0) {
                                Button {
                                    if targetValue > 1 { targetValue -= 1 }
                                } label: {
                                    Text("–").font(.system(size: 11, weight: .bold)).frame(width: 20, height: 20)
                                }
                                .buttonStyle(.plain)

                                Text(targetValue.formatted(.number.precision(.fractionLength(0...1))))
                                    .font(.system(size: 11, weight: .bold))
                                    .monospacedDigit()
                                    .frame(minWidth: 32)

                                Button {
                                    targetValue += 1
                                } label: {
                                    Text("+").font(.system(size: 11, weight: .bold)).frame(width: 20, height: 20)
                                }
                                .buttonStyle(.plain)
                            }
                            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 4))

                            Picker("", selection: $selectedUnit) {
                                ForEach(UnitOption.allCases) { u in
                                    Text(u.displayName).tag(u)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                Divider().padding(.leading, 12)

                // Row 4: Schedule
                HStack(spacing: 12) {
                    Text("Schedule")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    Picker("", selection: $selectedSchedule) {
                        ForEach(Self.schedules, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .labelsHidden()

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider().padding(.leading, 12)

                // Row 5: Color Swatches
                HStack(spacing: 12) {
                    Text("Theme")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    colorSwatchesRow
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )

            // Footer Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button {
                    saveHabit()
                } label: {
                    Text("Create Habit")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .foregroundStyle(isValid ? Color.white : DS.Color.textTertiary)
                        .background(
                            isValid ? activeColor : DS.Color.surfaceRecessed,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.top, 4)
        }
        .padding(DS.Space.lg)
        .frame(width: 460)
        .background(DS.Color.surface)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNameFocused = true
            }
        }
    }

    // MARK: - Subcomponents

    private var templateDropdownMenu: some View {
        Menu {
            Section("Popular Templates") {
                ForEach(Self.curatedTemplates, id: \.name) { tmpl in
                    Button {
                        applyTemplate(tmpl)
                    } label: {
                        Label(tmpl.name, systemImage: tmpl.icon)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 10))
                Text("Templates")
                    .font(.system(size: 10, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .foregroundStyle(DS.Color.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 5))
        }
        .menuStyle(.borderlessButton)
    }

    private var colorSwatchesRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<ColorPalette.count, id: \.self) { idx in
                let col = ColorPalette[idx]
                Button {
                    colorIndex = idx
                    Haptics.impact(.light)
                } label: {
                    ZStack {
                        Circle()
                            .fill(col)
                            .frame(width: 18, height: 18)

                        if colorIndex == idx {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Template Application

    private func applyTemplate(_ tmpl: HabitTemplateItem) {
        habitName = tmpl.name
        colorIndex = tmpl.colorIndex
        metricType = tmpl.metricType
        targetValue = max(tmpl.targetValue, 1.0)
        selectedUnit = tmpl.unit
        Haptics.impact(.light)
    }

    @State private var isSaving: Bool = false

    private func saveHabit() {
        guard isValid && !isSaving else { return }
        isSaving = true
        let cleanName = trimmedName

        let target: Double? = metricType == .quantitative ? max(targetValue, 1.0) : nil
        let unit: String? = metricType == .quantitative ? selectedUnit.label : nil

        let newHabit = HabitBoard(
            name: cleanName,
            metricType: metricType.rawValue,
            targetValue: target,
            unitLabel: unit,
            colorIndex: colorIndex
        )

        modelContext.insert(newHabit)
        do {
            try modelContext.save()
            PlutoTelemetryEngine.shared.trackHabitCreated(board: newHabit)
            Haptics.impact(.rigid)
            dismiss()
        } catch {
            isSaving = false
            modelContext.rollback()
        }
    }

    // MARK: - Curated Templates Data

    struct HabitTemplateItem {
        let name: String
        let icon: String
        let colorIndex: Int
        let metricType: HabitBoard.MetricType
        let targetValue: Double
        let unit: UnitOption
    }

    private static let curatedTemplates: [HabitTemplateItem] = [
        HabitTemplateItem(name: "Morning Run", icon: "figure.run", colorIndex: 0, metricType: .quantitative, targetValue: 5, unit: .km),
        HabitTemplateItem(name: "Mindful Meditation", icon: "sparkles", colorIndex: 1, metricType: .quantitative, targetValue: 15, unit: .minutes),
        HabitTemplateItem(name: "Book Reading", icon: "book", colorIndex: 3, metricType: .quantitative, targetValue: 20, unit: .pages),
        HabitTemplateItem(name: "Hydration Target", icon: "drop.fill", colorIndex: 5, metricType: .quantitative, targetValue: 8, unit: .glasses),
        HabitTemplateItem(name: "Strength Workout", icon: "dumbbell.fill", colorIndex: 2, metricType: .binary, targetValue: 1, unit: .sessions),
        HabitTemplateItem(name: "Deep Work Sprint", icon: "laptopcomputer", colorIndex: 4, metricType: .quantitative, targetValue: 60, unit: .minutes),
        HabitTemplateItem(name: "Daily Journaling", icon: "pencil.line", colorIndex: 6, metricType: .binary, targetValue: 1, unit: .sessions),
        HabitTemplateItem(name: "Night Sleep Routine", icon: "moon.fill", colorIndex: 9, metricType: .binary, targetValue: 1, unit: .sessions)
    ]
}
