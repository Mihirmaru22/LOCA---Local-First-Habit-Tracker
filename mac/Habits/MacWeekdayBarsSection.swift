import SwiftUI

// MARK: - MacWeekdayBarsSection   (H5)

/// Weekday distribution chart in the Mac detail column.
///
/// `WeekdaysChartView` is already Canvas-based and fully cross-platform —
/// no adaptation is required. This wrapper just owns the section header and
/// the standard horizontal padding so the chart stays consistent with the
/// other sections above it.
struct MacWeekdayBarsSection: View {

    let board: HabitBoard

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            WeekdaysChartView(board: board)
        }
    }
}
