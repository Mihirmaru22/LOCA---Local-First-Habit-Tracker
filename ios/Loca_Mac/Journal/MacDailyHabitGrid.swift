import SwiftUI
import SwiftData

// MARK: - MacDailyHabitGrid   (J4)

/// 30-day cross-habit completion grid.
///
/// Habits are rows; the last 30 calendar days are columns (oldest left, today right).
/// Each cell is filled with the habit's accent color when the day's logs met the target,
/// or a muted surface color when the day was missed or not yet reached.
///
/// Rendered in a horizontal ScrollView so the grid never clips the habit names regardless
/// of how many habits the user has, even in the narrower Mac content column.
struct MacDailyHabitGrid: View {

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var allBoards: [HabitBoard]

    private var activeBoards: [HabitBoard] { allBoards.filter { $0.archivedAt == nil } }

    private static let dayCount = 30
    private let cellSize: CGFloat = 10
    private let cellGap: CGFloat  = 2

    // The last 30 calendar days, oldest first.
    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<Self.dayCount).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
    }

    var body: some View {
        if activeBoards.isEmpty {
            Text("No habits to show.")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textTertiary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: cellGap) {
                    columnHeaders
                    ForEach(activeBoards, id: \.id) { board in
                        habitRow(board)
                    }
                }
            }
        }
    }

    // MARK: - Column headers (day-of-month labels every 5 days)

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            // Spacer to align with the habit-name labels
            Text("").frame(width: nameColumnWidth)
            HStack(spacing: cellGap) {
                ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                    let dom = Calendar.current.component(.day, from: day)
                    Text(idx % 5 == 0 ? "\(dom)" : "")
                        .font(.system(size: 7))
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(width: cellSize)
                }
            }
        }
    }

    // MARK: - Habit row

    private func habitRow(_ board: HabitBoard) -> some View {
        let completedDays = completedDaySet(for: board)
        return HStack(spacing: 0) {
            Text(board.name)
                .font(.system(size: 10))
                .lineLimit(1)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: nameColumnWidth, alignment: .trailing)
                .padding(.trailing, DS.Space.xs)

            HStack(spacing: cellGap) {
                ForEach(days, id: \.self) { day in
                    let done = completedDays.contains(day)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(done
                              ? ColorPalette[board.colorIndex]
                              : DS.Color.surfaceRecessed)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }

    // MARK: - Helpers

    private let nameColumnWidth: CGFloat = 64

    /// Returns the set of `startOfDay` dates where the board met its target.
    private func completedDaySet(for board: HabitBoard) -> Set<Date> {
        let cal = Calendar.current
        let target = board.effectiveTarget
        var dayTotals: [Date: Double] = [:]
        for log in board.activeLogs {
            let day = cal.startOfDay(for: log.timestamp)
            dayTotals[day, default: 0] += log.value
        }
        return Set(dayTotals.filter { $0.value >= target }.keys)
    }
}
