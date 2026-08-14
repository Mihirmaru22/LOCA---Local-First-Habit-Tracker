import SwiftUI
import SwiftData

// MARK: - MacHabitDetailColumn (Bento Performance Radar & Quantitative Logger)

/// Right (detail) column of the Mac three-pane layout for a selected habit.
/// Dedicated Bento Performance Radar with real-time Quantitative Amount Logging,
/// Streak Momentum, Monthly Pacing, 182-Day Heatmap, and Weekday Distribution.
struct MacHabitDetailColumn: View {

    let habit: HabitBoard?
    @Environment(\.modelContext) private var modelContext
    @State private var showCheckInError = false
    @State private var customAmountText = ""
    @FocusState private var isAmountFocused: Bool

    private var color: Color {
        guard let habit else { return .accentColor }
        return ColorPalette[habit.colorIndex]
    }

    private var todaysLogs: [LogEntry] {
        guard let habit else { return [] }
        return (habit.logs ?? [])
            .filter { $0.timestamp.isToday() && $0.archivedAt == nil }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var todaysTotal: Double {
        todaysLogs.reduce(0.0) { $0 + $1.value }
    }

    private var progressFraction: Double {
        guard let habit, habit.effectiveTarget > 0 else { return 0 }
        return max(0, min(1, todaysTotal / habit.effectiveTarget))
    }

    private var isDone: Bool {
        guard let habit else { return false }
        if habit.metric == .binary {
            return todaysTotal >= 1.0
        }
        return todaysTotal >= habit.effectiveTarget
    }

    private var thisMonthLogsCount: Int {
        guard let habit else { return 0 }
        let cal = Calendar.current
        let now = Date()
        return (habit.logs ?? []).filter { $0.archivedAt == nil && cal.isDate($0.timestamp, equalTo: now, toGranularity: .month) }.count
    }

    private var totalLogsCount: Int {
        guard let habit else { return 0 }
        return (habit.logs ?? []).filter { $0.archivedAt == nil }.count
    }

    private var unit: String {
        habit?.unitLabel ?? (habit?.metric == .quantitative ? "units" : "check")
    }

    var body: some View {
        if let habit {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {

                    // MARK: 1. Hero Performance & Logging Card
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        // Title + Status Row
                        HStack(spacing: DS.Space.lg) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Circle().fill(color).frame(width: 10, height: 10)
                                    Text(habit.name)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(DS.Color.textPrimary)
                                }

                                if habit.metric == .quantitative {
                                    Text("\(todaysTotal.formatted(.number.precision(.fractionLength(0...1)))) / \(habit.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))) \(unit) logged today")
                                        .font(DS.Text.caption)
                                        .foregroundStyle(isDone ? color : DS.Color.textSecondary)
                                } else {
                                    Text(isDone ? "Completed for today ✓" : "Pending daily check-in")
                                        .font(DS.Text.caption)
                                        .foregroundStyle(isDone ? color : DS.Color.textSecondary)
                                }
                            }

                            Spacer()

                            // Primary Complete / Reset Button
                            Button {
                                handleMainAction(habit)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 13, weight: .bold))
                                    Text(isDone ? "Completed ✓" : (habit.metric == .quantitative ? "Mark Target Done" : "Check In"))
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(isDone ? Color.white : color)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isDone ? color : color.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }

                        // Quantitative Progress Bar & Quick Stepper (If Quantitative)
                        if habit.metric == .quantitative {
                            VStack(alignment: .leading, spacing: 10) {
                                // Progress Track
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(DS.Color.surfaceRecessed)
                                            .frame(height: 8)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [color, color.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(0, geo.size.width * CGFloat(progressFraction)), height: 8)
                                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: progressFraction)
                                    }
                                }
                                .frame(height: 8)

                                // Quick Increment Stepper Buttons
                                HStack(spacing: 8) {
                                    Text("Quick Add:")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(DS.Color.textTertiary)

                                    ForEach(smartSteps(for: habit.effectiveTarget), id: \.self) { step in
                                        Button {
                                            logAmount(step, for: habit)
                                        } label: {
                                            Text("+\(formatStep(step)) \(unit)")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(DS.Color.textPrimary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 5))
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Spacer()

                                    // Percentage Indicator
                                    Text("\(Int(progressFraction * 100))%")
                                        .font(.system(size: 12, weight: .bold))
                                        .monospacedDigit()
                                        .foregroundStyle(isDone ? color : DS.Color.textSecondary)
                                }

                                Divider().padding(.vertical, 2)

                                // Custom Amount Input Bar
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.forwardslash.minus")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.Color.textTertiary)

                                    TextField("Add custom amount (e.g. 5.5)", text: $customAmountText)
                                        .font(.system(size: 12))
                                        .textFieldStyle(.plain)
                                        .focused($isAmountFocused)
                                        .onSubmit {
                                            submitCustomAmount(for: habit)
                                        }

                                    if !customAmountText.isEmpty {
                                        Button("Add \(unit)") {
                                            submitCustomAmount(for: habit)
                                        }
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(color, in: RoundedRectangle(cornerRadius: 5))
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(DS.Space.lg)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // MARK: 2. Today's Log Entries Breakdown
                    if !todaysLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TODAY'S LOG ENTRIES (\(todaysLogs.count))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                                .tracking(0.6)

                            VStack(spacing: 6) {
                                ForEach(todaysLogs, id: \.id) { entry in
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.system(size: 10))
                                            .foregroundStyle(DS.Color.textTertiary)

                                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(DS.Color.textSecondary)

                                        Spacer()

                                        Text("+\(entry.value.formatted(.number.precision(.fractionLength(0...1)))) \(unit)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(color)

                                        Button {
                                            deleteEntry(entry, board: habit)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(DS.Color.textTertiary.opacity(0.6))
                                        }
                                        .buttonStyle(.plain)
                                        .help("Delete this check-in entry")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                        .padding(DS.Space.lg)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                    }

                    // MARK: 3. 2-Column Bento Matrix
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.md) {

                        // Box 1: Streak Momentum
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STREAK MOMENTUM")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                                .tracking(0.6)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                                        Text("\(habit.currentStreak)")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(DS.Color.textPrimary)
                                    }
                                    Text("Current Streak").font(.system(size: 10)).foregroundStyle(DS.Color.textTertiary)
                                }

                                Divider().frame(height: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill").foregroundStyle(.yellow)
                                        Text("\(max(habit.currentStreak, habit.longestStreak))")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(DS.Color.textPrimary)
                                    }
                                    Text("All-Time Best").font(.system(size: 10)).foregroundStyle(DS.Color.textTertiary)
                                }
                            }
                        }
                        .padding(DS.Space.lg)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                        // Box 2: Monthly Pacing
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MONTHLY PACING")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                                .tracking(0.6)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(thisMonthLogsCount) days")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(color)
                                    Text("Logged this month").font(.system(size: 10)).foregroundStyle(DS.Color.textTertiary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(totalLogsCount) total")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(DS.Color.textPrimary)
                                    Text("Lifetime Reps").font(.system(size: 10)).foregroundStyle(DS.Color.textTertiary)
                                }
                            }
                        }
                        .padding(DS.Space.lg)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                    }

                    // MARK: 4. 182-Day Heatmap Card
                    MacHeatmapCard(board: habit)

                    // MARK: 5. Weekday Distribution Chart
                    MacWeekdayBarsSection(board: habit)

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.xl)
                .padding(.top, DS.Space.lg)
            }
            .navigationTitle(habit.name)
            .navigationSubtitle(habit.metric == .binary ? "Check-off Habit" : "Tracking: \(habit.effectiveTarget.formatted()) \(unit)/day")
            .alert("Couldn't Save Check-in", isPresented: $showCheckInError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The check-in couldn't be saved. Please try again.")
            }
        } else {
            MacDetailPlaceholder()
        }
    }

    // MARK: - Actions

    private func handleMainAction(_ habit: HabitBoard) {
        do {
            if habit.metric == .binary {
                try CheckInWriter.toggleBinary(board: habit, context: modelContext)
                PlutoTelemetryEngine.shared.trackHabitCheckIn(board: habit, value: habit.effectiveTarget, isDone: isDone)
            } else {
                if isDone {
                    // Reset today's entries
                    for entry in todaysLogs {
                        try CheckInWriter.delete(entry, board: habit, context: modelContext)
                    }
                } else {
                    // Fill the remaining amount to reach target
                    let remaining = max(1.0, habit.effectiveTarget - todaysTotal)
                    try CheckInWriter.insert(value: remaining, board: habit, context: modelContext)
                    PlutoTelemetryEngine.shared.trackHabitCheckIn(board: habit, value: remaining, isDone: true)
                }
            }
            Haptics.impact(.rigid)
        } catch {
            showCheckInError = true
        }
    }

    private func logAmount(_ amount: Double, for habit: HabitBoard) {
        guard amount > 0 else { return }
        do {
            try CheckInWriter.insert(value: amount, board: habit, context: modelContext)
            PlutoTelemetryEngine.shared.trackHabitCheckIn(board: habit, value: amount, isDone: (todaysTotal + amount) >= habit.effectiveTarget)
            Haptics.impact(.light)
        } catch {
            showCheckInError = true
        }
    }

    private func submitCustomAmount(for habit: HabitBoard) {
        guard let value = Double(customAmountText.trimmingCharacters(in: .whitespacesAndNewlines)), value > 0 else {
            return
        }
        logAmount(value, for: habit)
        customAmountText = ""
        isAmountFocused = false
    }

    private func deleteEntry(_ entry: LogEntry, board: HabitBoard) {
        do {
            try CheckInWriter.delete(entry, board: board, context: modelContext)
            Haptics.impact(.light)
        } catch {
            showCheckInError = true
        }
    }

    private func smartSteps(for target: Double) -> [Double] {
        if target <= 5 {
            return [0.5, 1.0, 2.0]
        } else if target <= 15 {
            return [1.0, 2.0, 5.0]
        } else if target <= 50 {
            return [5.0, 10.0, 20.0]
        } else if target <= 100 {
            return [10.0, 25.0, 50.0]
        } else if target <= 1000 {
            return [50.0, 100.0, 250.0]
        } else {
            return [500.0, 1000.0, 2500.0]
        }
    }

    private func formatStep(_ val: Double) -> String {
        val.formatted(.number.precision(.fractionLength(0...1)))
    }
}
