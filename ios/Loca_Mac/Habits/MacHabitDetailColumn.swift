import SwiftUI
import SwiftData

// MARK: - MacHabitDetailColumn   (H2)

/// Right (detail) column of the Mac three-pane layout for a selected habit.
///
/// Shows a scrollable overview — MacHeatmapCard (H3), MacStatBar (H4),
/// MacWeekdayBarsSection (H5), and quick-log — replacing the iOS tab-based
/// HabitDetailView which assumes a narrow, full-height modal presentation.
///
/// When `habit` is nil (nothing selected) the `MacDetailPlaceholder` from
/// the Foundation shell is shown instead.
struct MacHabitDetailColumn: View {

    let habit: HabitBoard?
    @Environment(\.modelContext) private var modelContext
    @State private var showCheckInError = false

    var body: some View {
        if let habit {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {

                    // Quick-log strip
                    MacQuickLogStrip(board: habit, onCheckInError: { showCheckInError = true })
                        .padding(.horizontal, DS.Space.xl)
                        .padding(.top, DS.Space.xl)

                    // H3 — 182-day heatmap
                    MacHeatmapCard(board: habit)
                        .padding(.horizontal, DS.Space.xl)

                    // H4 — Stat tiles (streak · rate · total)
                    MacStatBar(board: habit)
                        .padding(.horizontal, DS.Space.xl)

                    // H5 — Weekday bar chart
                    MacWeekdayBarsSection(board: habit)
                        .padding(.horizontal, DS.Space.xl)

                    Spacer(minLength: DS.Space.xxxl)
                }
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

// MARK: - MacQuickLogStrip

/// Compact today-status row with a binary check button or a quantitative
/// stepper. Lives at the top of the detail column so the most frequent
/// action requires the least scrolling.
private struct MacQuickLogStrip: View {

    let board: HabitBoard
    let onCheckInError: () -> Void

    @Environment(\.modelContext) private var modelContext

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    private var isDone: Bool {
        todaysTotal >= board.effectiveTarget
    }

    var body: some View {
        HStack(spacing: DS.Space.lg) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Today")
                    .font(DS.Text.heading)
                if board.metric == .quantitative {
                    (Text(todaysTotal.formatted(.number.precision(.fractionLength(0...1))))
                        .font(DS.Text.value) +
                     Text(" / \(board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))) \(board.unitLabel ?? "")")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textSecondary))
                } else {
                    Text(isDone ? "Done ✓" : "Not yet")
                        .font(DS.Text.body)
                        .foregroundStyle(isDone ? ColorPalette[board.colorIndex] : DS.Color.textSecondary)
                }
            }

            Spacer()

            if board.metric == .binary {
                Button(action: checkInBinary) {
                    Label(isDone ? "Undo" : "Mark Done",
                          systemImage: isDone ? "checkmark.circle.fill" : "circle")
                        .labelStyle(.titleAndIcon)
                }
                .controlSize(.large)
                .tint(ColorPalette[board.colorIndex])
                .focusedValue(\.logTodayAction, { checkInBinary() })
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func checkInBinary() {
        do {
            try CheckInWriter.toggleBinary(board: board, context: modelContext)
            Haptics.impact(.rigid)
        } catch {
            onCheckInError()
        }
    }
}
