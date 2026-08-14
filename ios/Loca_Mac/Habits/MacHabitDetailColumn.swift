import SwiftUI
import SwiftData

// MARK: - MacHabitDetailColumn (Bento Performance Radar)

/// Right (detail) column of the Mac three-pane layout for a selected habit.
/// Dedicated Bento Performance Radar view with Streak Momentum, Monthly Pacing,
/// 182-Day Heatmap, and Weekday Distribution.
struct MacHabitDetailColumn: View {

    let habit: HabitBoard?
    @Environment(\.modelContext) private var modelContext
    @State private var showCheckInError = false

    private var color: Color {
        guard let habit else { return .accentColor }
        return ColorPalette[habit.colorIndex]
    }

    private var todaysTotal: Double {
        guard let habit else { return 0 }
        return (habit.logs ?? []).filter { $0.timestamp.isToday() }.reduce(0.0) { $0 + $1.value }
    }

    private var isDone: Bool {
        guard let habit else { return false }
        return todaysTotal >= habit.effectiveTarget
    }

    private var thisMonthLogsCount: Int {
        guard let habit else { return 0 }
        let cal = Calendar.current
        let now = Date()
        return (habit.logs ?? []).filter { cal.isDate($0.timestamp, equalTo: now, toGranularity: .month) }.count
    }

    private var totalLogsCount: Int {
        guard let habit else { return 0 }
        return (habit.logs ?? []).count
    }

    var body: some View {
        if let habit {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {

                    // Hero Bento Card
                    HStack(spacing: DS.Space.lg) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle().fill(color).frame(width: 8, height: 8)
                                Text(habit.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }

                            Text(isDone ? "Completed for today ✓" : "Pending daily check-in")
                                .font(DS.Text.caption)
                                .foregroundStyle(isDone ? color : DS.Color.textSecondary)
                        }

                        Spacer()

                        Button {
                            do {
                                try CheckInWriter.toggleBinary(board: habit, context: modelContext)
                                Haptics.impact(.rigid)
                            } catch {
                                showCheckInError = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14, weight: .bold))
                                Text(isDone ? "Completed" : "Check In")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(isDone ? Color.white : color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isDone ? color : color.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(DS.Space.lg)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // 2-Column Bento Matrix
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

                    // 182-Day Heatmap Card
                    MacHeatmapCard(board: habit)

                    // Weekday Distribution Chart
                    MacWeekdayBarsSection(board: habit)

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(.horizontal, DS.Space.xl)
                .padding(.top, DS.Space.lg)
            }
            .navigationTitle(habit.name)
            .navigationSubtitle(habit.metric == .binary ? "Binary" : (habit.unitLabel ?? "Quantitative"))
            .alert("Couldn't Save Check-in", isPresented: $showCheckInError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The check-in couldn't be saved. Please try again.")
            }
        } else {
            MacDetailPlaceholder()
        }
    }
}
