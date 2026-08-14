import SwiftUI
import SwiftData

// MARK: - HorizonCategory

enum HorizonCategory: String, CaseIterable, Identifiable {
    case all     = "All Horizons"
    case quarter = "This Quarter (Q3)"
    case year    = "This Year (2026)"
    case vision  = "3-Year Vision"
    case bucket  = "Lifetime Bucket List"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:     return "line.3.horizontal.decrease.circle"
        case .quarter: return "clock.badge.checkmark"
        case .year:    return "calendar"
        case .vision:  return "binoculars.fill"
        case .bucket:  return "trophy.fill"
        }
    }
}

// MARK: - GoalCategory

enum GoalCategory: String, CaseIterable, Identifiable {
    case health   = "Health & Fitness"
    case craft    = "Craft & Career"
    case mind     = "Mind & Growth"
    case finance  = "Wealth & Finance"
    case personal = "Personal Growth"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .health:   return "figure.run"
        case .craft:    return "laptopcomputer"
        case .mind:     return "book.closed.fill"
        case .finance:  return "chart.line.uptrend.xyaxis"
        case .personal: return "target"
        }
    }
}

// MARK: - MacAuditView (Minimalist Executive Strategic Goals & Milestones)

/// Dedicated Strategic Milestone Roadmap Studio for macOS following LOCA's sleek, unified minimalist design.
struct MacAuditView: View {

    @AppStorage("mac_audit_selected_horizon") var selectedHorizon: HorizonCategory = .all
    @AppStorage("mac_selected_accent_index") private var selectedAccentIndex: Int = 0

    struct MilestoneCheckpoint: Identifiable, Equatable {
        let id: String
        var title: String
        var isDone: Bool
    }

    struct DetailedGoalItem: Identifiable, Equatable {
        let id: String
        var title: String
        var category: GoalCategory
        var horizon: HorizonCategory
        var progress: Double // 0.0 to 1.0
        var targetDate: String
        var engineHabit: String
        var checkpoints: [MilestoneCheckpoint]
    }

    @State private var goals: [DetailedGoalItem] = [
        DetailedGoalItem(
            id: "1",
            title: "Run First Half-Marathon (21.1 km)",
            category: .health,
            horizon: .quarter,
            progress: 0.40,
            targetDate: "October 2026",
            engineHabit: "Morning Run · 5 km / day",
            checkpoints: [
                MilestoneCheckpoint(id: "c1", title: "Build 5 km continuous aerobic base", isDone: true),
                MilestoneCheckpoint(id: "c2", title: "Complete 10 km weekend long run", isDone: true),
                MilestoneCheckpoint(id: "c3", title: "15 km steady-state threshold pacing", isDone: false),
                MilestoneCheckpoint(id: "c4", title: "Race day simulation (18 km)", isDone: false),
                MilestoneCheckpoint(id: "c5", title: "Official Half-Marathon Finish Line", isDone: false)
            ]
        ),
        DetailedGoalItem(
            id: "2",
            title: "Ship PLUTO App Version 3.5",
            category: .craft,
            horizon: .quarter,
            progress: 0.80,
            targetDate: "September 2026",
            engineHabit: "Deep Focus Coding · 60 min",
            checkpoints: [
                MilestoneCheckpoint(id: "l1", title: "Local-First SwiftData schema architecture", isDone: true),
                MilestoneCheckpoint(id: "l2", title: "Habit Heatmap & Streak Calculation engine", isDone: true),
                MilestoneCheckpoint(id: "l3", title: "Nocturnal Sleep Timeline & Matrix", isDone: true),
                MilestoneCheckpoint(id: "l4", title: "Life & Audit Suite layouts polish", isDone: true),
                MilestoneCheckpoint(id: "l5", title: "TestFlight beta & App Store release", isDone: false)
            ]
        ),
        DetailedGoalItem(
            id: "3",
            title: "Read 24 High-Impact Strategic Books",
            category: .mind,
            horizon: .year,
            progress: 0.75,
            targetDate: "December 2026",
            engineHabit: "High-Density Reading · 20 pages / day",
            checkpoints: [
                MilestoneCheckpoint(id: "b1", title: "Complete Q1 Reading Sprint (6 books)", isDone: true),
                MilestoneCheckpoint(id: "b2", title: "Complete Q2 Deep Tech & Philosophy (6 books)", isDone: true),
                MilestoneCheckpoint(id: "b3", title: "Q3 Strategy & Biography Sprint (6 books)", isDone: true),
                MilestoneCheckpoint(id: "b4", title: "Q4 Final Stretch (6 books)", isDone: false)
            ]
        )
    ]

    // New Goal Creator State
    @State private var showingAddGoalSheet = false
    @State private var newGoalTitle = ""
    @State private var newGoalCategory: GoalCategory = .health
    @State private var newGoalHorizon: HorizonCategory = .quarter
    @State private var newGoalTargetDate = "October 2026"
    @State private var newGoalEngineHabit = "Daily Keystone Habit"

    // Inline Card Point Addition State
    @State private var addingPointGoalId: String? = nil
    @State private var inlinePointText: String = ""

    // Inline Title Editing State
    @State private var editingTitleGoalId: String? = nil
    @State private var editedTitleText: String = ""

    private var accentColor: Color {
        ColorPalette[selectedAccentIndex]
    }

    private var filteredGoals: [DetailedGoalItem] {
        if selectedHorizon == .all {
            return goals
        }
        return goals.filter { $0.horizon == selectedHorizon }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top Bar: Clean Horizon Dropdown Filter + New Goal Button
            HStack(spacing: 12) {
                Menu {
                    ForEach(HorizonCategory.allCases) { horizon in
                        Button {
                            selectedHorizon = horizon
                            Haptics.impact(.light)
                        } label: {
                            HStack {
                                Image(systemName: horizon.icon)
                                Text(horizon.rawValue)
                                if selectedHorizon == horizon {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedHorizon.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textSecondary)

                        Text(selectedHorizon.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .help("Filter by Horizon")

                Spacer()

                // + New Goal Action Button
                Button {
                    newGoalTitle = ""
                    newGoalHorizon = selectedHorizon == .all ? .quarter : selectedHorizon
                    showingAddGoalSheet = true
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("New Goal")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DS.Color.border.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingAddGoalSheet) {
                    newGoalStudioModal
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.md)
            .background(DS.Color.background)

            Divider()

            // Main Scrollable Body
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    if filteredGoals.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "flag.slash")
                                .font(.system(size: 24))
                                .foregroundStyle(DS.Color.textTertiary)
                            Text("No goals in \(selectedHorizon.rawValue)")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(DS.Space.xxl)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
                    } else {
                        VStack(spacing: DS.Space.lg) {
                            ForEach(filteredGoals) { goal in
                                minimalistGoalCard(goal)
                            }
                        }
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.xl)
                .padding(.vertical, DS.Space.lg)
                .frame(maxWidth: 1000, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.background)
    }

    // MARK: - New Goal Modal

    private var newGoalStudioModal: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Goal")
                        .font(DS.Text.title)
                        .fontWeight(.bold)
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Define your objective and anchor it to habit execution.")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer()
                Button {
                    showingAddGoalSheet = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("GOAL TITLE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                TextField("What do you want to achieve? (e.g. Build $10k MRR App)…", text: $newGoalTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("CATEGORY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                Picker("Category", selection: $newGoalCategory) {
                    ForEach(GoalCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("HORIZON")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                Picker("Horizon", selection: $newGoalHorizon) {
                    ForEach(HorizonCategory.allCases.filter { $0 != .all }) { h in
                        Text(h.rawValue).tag(h)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TARGET TIMEFRAME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                    TextField("e.g. October 2026", text: $newGoalTargetDate)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("ENGINE HABIT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                    TextField("e.g. Deep Work 90m", text: $newGoalEngineHabit)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Divider()

            HStack {
                Button("Cancel") {
                    showingAddGoalSheet = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(DS.Color.textSecondary)

                Spacer()

                Button {
                    createGoalFromModal()
                } label: {
                    Text("Create Goal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(accentColor, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(newGoalTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(DS.Space.xl)
        .frame(width: 440)
        .background(DS.Color.surface)
    }

    private func createGoalFromModal() {
        let trimmedTitle = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let newGoal = DetailedGoalItem(
            id: UUID().uuidString,
            title: trimmedTitle,
            category: newGoalCategory,
            horizon: newGoalHorizon,
            progress: 0.0,
            targetDate: newGoalTargetDate,
            engineHabit: newGoalEngineHabit,
            checkpoints: [
                MilestoneCheckpoint(id: UUID().uuidString, title: "Initial milestone kickoff", isDone: false),
                MilestoneCheckpoint(id: UUID().uuidString, title: "Core benchmark achieved", isDone: false),
                MilestoneCheckpoint(id: UUID().uuidString, title: "Final target completed", isDone: false)
            ]
        )

        goals.insert(newGoal, at: 0)
        showingAddGoalSheet = false
        Haptics.impact(.rigid)
    }

    // MARK: - Minimalist Goal Card View (Clean Uniform Neutral Styling)

    private func minimalistGoalCard(_ goal: DetailedGoalItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header Row: Category / Horizon Tag + Title + Steppers + Trash
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: goal.category.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(DS.Color.textSecondary)

                        Text(goal.category.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textSecondary)
                            .tracking(0.6)

                        Text("· \(goal.horizon.rawValue)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    // Editable Title
                    if editingTitleGoalId == goal.id {
                        HStack {
                            TextField("Goal title…", text: $editedTitleText)
                                .font(.system(size: 15, weight: .bold))
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                                        goals[idx].title = editedTitleText
                                    }
                                    editingTitleGoalId = nil
                                }

                            Button("Done") {
                                if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                                    goals[idx].title = editedTitleText
                                }
                                editingTitleGoalId = nil
                            }
                            .font(.system(size: 11, weight: .bold))
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Text(goal.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)

                            Button {
                                editedTitleText = goal.title
                                editingTitleGoalId = goal.id
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                // Progress Badge & Steppers
                HStack(spacing: 6) {
                    Button {
                        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                            goals[idx].progress = max(0.0, goals[idx].progress - 0.05)
                            Haptics.impact(.light)
                        }
                    } label: {
                        Text("–")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DS.Color.textSecondary)
                            .frame(width: 22, height: 22)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 40)

                    Button {
                        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                            goals[idx].progress = min(1.0, goals[idx].progress + 0.05)
                            Haptics.impact(.light)
                        }
                    } label: {
                        Text("+")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DS.Color.textSecondary)
                            .frame(width: 22, height: 22)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)

                    // Delete Goal Button
                    Button {
                        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                            goals.remove(at: idx)
                            Haptics.impact(.light)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textTertiary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("Delete Goal")
                }
            }

            // Clean Crisp Progress Bar
            GeometryReader { p in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DS.Color.surfaceRecessed)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(DS.Color.success)
                        .frame(width: max(0, p.size.width * CGFloat(goal.progress)), height: 4)
                }
            }
            .frame(height: 4)

            // Milestone Stages & Checkpoints Box
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("MILESTONE STAGES & CHECKPOINTS:")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)

                    Spacer()

                    let doneCount = goal.checkpoints.filter { $0.isDone }.count
                    Text("\(doneCount) of \(goal.checkpoints.count) complete")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                // Checkpoint Items List
                VStack(spacing: 2) {
                    ForEach(goal.checkpoints) { cp in
                        HStack(spacing: 8) {
                            // Checkbox Toggle
                            Button {
                                toggleCheckpoint(goalId: goal.id, checkpointId: cp.id)
                            } label: {
                                Image(systemName: cp.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(cp.isDone ? DS.Color.success : DS.Color.textTertiary)
                            }
                            .buttonStyle(.plain)

                            // Checkpoint Title Text
                            Text(cp.title)
                                .font(.system(size: 12))
                                .foregroundStyle(cp.isDone ? DS.Color.textTertiary : DS.Color.textPrimary)
                                .strikethrough(cp.isDone)

                            Spacer()

                            // Delete Checkpoint Button
                            Button {
                                deleteCheckpoint(goalId: goal.id, checkpointId: cp.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // + Inline Add Point Row
                if addingPointGoalId == goal.id {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Color.textTertiary)

                        TextField("Type milestone checkpoint and press Enter…", text: $inlinePointText)
                            .font(.system(size: 12))
                            .textFieldStyle(.plain)
                            .onSubmit {
                                saveInlinePoint(goalId: goal.id)
                            }

                        Button("Add") {
                            saveInlinePoint(goalId: goal.id)
                        }
                        .font(.system(size: 10, weight: .bold))
                        .buttonStyle(.plain)

                        Button("Cancel") {
                            addingPointGoalId = nil
                            inlinePointText = ""
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textTertiary)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                } else {
                    Button {
                        addingPointGoalId = goal.id
                        inlinePointText = ""
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                            Text("Add milestone point…")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(DS.Color.surfaceRecessed.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))

            Divider()

            // Footer: Target Date & Engine Habit
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Target: \(goal.targetDate)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                // Engine Habit Badge
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textTertiary)

                    Text("Engine Habit: \(goal.engineHabit)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    private func toggleCheckpoint(goalId: String, checkpointId: String) {
        if let gIdx = goals.firstIndex(where: { $0.id == goalId }),
           let cIdx = goals[gIdx].checkpoints.firstIndex(where: { $0.id == checkpointId }) {
            goals[gIdx].checkpoints[cIdx].isDone.toggle()
            recalculateProgress(goalIdx: gIdx)
            Haptics.impact(.rigid)
        }
    }

    private func deleteCheckpoint(goalId: String, checkpointId: String) {
        if let gIdx = goals.firstIndex(where: { $0.id == goalId }) {
            goals[gIdx].checkpoints.removeAll { $0.id == checkpointId }
            recalculateProgress(goalIdx: gIdx)
            Haptics.impact(.light)
        }
    }

    private func saveInlinePoint(goalId: String) {
        let trimmed = inlinePointText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            addingPointGoalId = nil
            return
        }

        if let gIdx = goals.firstIndex(where: { $0.id == goalId }) {
            let newCP = MilestoneCheckpoint(id: UUID().uuidString, title: trimmed, isDone: false)
            goals[gIdx].checkpoints.append(newCP)
            recalculateProgress(goalIdx: gIdx)
            inlinePointText = ""
            Haptics.impact(.light)
        }
    }

    private func recalculateProgress(goalIdx: Int) {
        guard goalIdx >= 0 && goalIdx < goals.count else { return }
        let total = goals[goalIdx].checkpoints.count
        guard total > 0 else {
            goals[goalIdx].progress = 0
            return
        }
        let done = goals[goalIdx].checkpoints.filter { $0.isDone }.count
        goals[goalIdx].progress = Double(done) / Double(total)
    }
}
