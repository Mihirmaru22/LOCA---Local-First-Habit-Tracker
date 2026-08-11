import SwiftUI
import SwiftData

// MARK: - MacDayPlannerColumn   (Plan sub-pillar — time-blocked day planner)

/// A Structured-style day planner: a vertical timeline of tasks placed at
/// specific times on a chosen day.
///
/// Layout, top → bottom:
/// - **Date header** — the selected day's full date with prev/next day chevrons
///   and an "add block" button.
/// - **Week strip** — Sun…Sat for the selected day's week; tap a day to switch.
/// - **Timeline** — scheduled blocks in time order, each with an icon bubble,
///   time range, duration and a completion circle. Free gaps between blocks are
///   labelled ("1h 30m free"). Below the timeline, an **Unscheduled** tray lists
///   tasks due today that don't yet have a time.
///
/// A task appears here when its `startTime` falls on the selected day. Give any
/// task a time in the detail column (or with the ＋ button) to place it on the
/// timeline; clear the time to send it back to the bucket list.
struct MacDayPlannerColumn: View {

    @Binding var selection: TodoItem?
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\TodoItem.startTime)], animation: .default)
    private var allItems: [TodoItem]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)

    private let cal = Calendar.current

    // MARK: Derived collections

    private var active: [TodoItem] { allItems.filter { !$0.isArchived && $0.parentID == nil } }

    /// Scheduled blocks on the selected day, ordered by start time.
    private var scheduled: [TodoItem] {
        active
            .filter { item in
                guard let start = item.startTime else { return false }
                return cal.isDate(start, inSameDayAs: selectedDate)
            }
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    /// Tasks due on the selected day that don't have a time yet.
    private var unscheduled: [TodoItem] {
        active.filter { item in
            guard item.startTime == nil, let due = item.dueDate else { return false }
            return cal.isDate(due, inSameDayAs: selectedDate)
        }
    }

    /// The seven days (Sun…Sat) of the week containing the selected day.
    private var weekDays: [Date] {
        guard let interval = cal.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            header
            weekStrip
            Divider()
            timeline
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: DS.Space.sm) {
            Button { shiftDay(-1) } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .help("Previous day")

            Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(DS.Text.heading)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { selectedDate = cal.startOfDay(for: .now) }
                .help("Jump to today")

            Button { shiftDay(1) } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .help("Next day")

            Button(action: addBlock) {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .help("Add a time block")
        }
        .font(DS.Text.body)
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
    }

    // MARK: Week strip

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                dayCell(day)
            }
        }
        .padding(.horizontal, DS.Space.sm)
        .padding(.bottom, DS.Space.sm)
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = cal.isDate(day, inSameDayAs: selectedDate)
        let isToday    = cal.isDateInToday(day)
        let count      = active.filter { $0.startTime.map { cal.isDate($0, inSameDayAs: day) } ?? false }.count

        return VStack(spacing: 4) {
            Text(day, format: .dateTime.weekday(.abbreviated))
                .font(DS.Text.footnote)
                .foregroundStyle(DS.Color.textTertiary)

            Text(day, format: .dateTime.day())
                .font(DS.Text.body)
                .foregroundStyle(isSelected ? Color.white : DS.Color.textPrimary)
                .frame(width: 30, height: 30)
                .background {
                    Circle().fill(isSelected ? Color.accentColor : Color.clear)
                }
                .overlay {
                    if isToday && !isSelected {
                        Circle().stroke(Color.accentColor, lineWidth: 1.5)
                    }
                }

            // Activity dot — shows a day carries scheduled blocks.
            Circle()
                .fill(count > 0 ? Color.accentColor.opacity(0.7) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { selectedDate = cal.startOfDay(for: day) }
    }

    // MARK: Timeline

    private var timeline: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if scheduled.isEmpty && unscheduled.isEmpty {
                    emptyState
                        .padding(.top, DS.Space.xxxl)
                }

                ForEach(Array(scheduled.enumerated()), id: \.element.id) { index, item in
                    PlannerBlockRow(
                        item: item,
                        isSelected: selection?.id == item.id,
                        onSelect: { selection = item },
                        onToggle: { toggleComplete(item) }
                    )

                    if let gap = freeGap(afterIndex: index) {
                        gapLabel(gap)
                    }
                }

                if !unscheduled.isEmpty {
                    unscheduledSection
                }
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)
        }
    }

    private func gapLabel(_ minutes: Int) -> some View {
        HStack(spacing: DS.Space.sm) {
            // Align under the icon bubble column.
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(width: PlannerMetrics.bubble)

            Text("\(durationText(minutes)) free")
                .font(DS.Text.footnote)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(.vertical, DS.Space.xs)
        .padding(.leading, PlannerMetrics.timeGutter)
    }

    private var unscheduledSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Divider()
                .padding(.top, DS.Space.md)
            Label("Unscheduled", systemImage: "tray")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.top, DS.Space.sm)
                .padding(.bottom, DS.Space.xs)

            ForEach(unscheduled, id: \.id) { item in
                HStack(spacing: DS.Space.sm) {
                    Button { toggleComplete(item) } label: {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Text(item.title)
                        .font(DS.Text.body)
                        .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                        .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button { schedule(item) } label: {
                        Image(systemName: "clock.badge.plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .help("Add to timeline")
                }
                .padding(.vertical, DS.Space.xs)
                .padding(.horizontal, DS.Space.sm)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                .contentShape(Rectangle())
                .onTapGesture { selection = item }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing Planned", systemImage: "calendar.day.timeline.left")
        } description: {
            Text("Add a time block with ＋, or give a task a time in its detail.")
        }
    }

    // MARK: Actions

    private func shiftDay(_ delta: Int) {
        if let d = cal.date(byAdding: .day, value: delta, to: selectedDate) {
            selectedDate = d
        }
    }

    /// Create a fresh block at the next open slot and select it for editing.
    private func addBlock() {
        let start = defaultStart()
        let item = TodoItem(
            title: "New block",
            dueDate: selectedDate,
            startTime: start,
            durationMinutes: 30
        )
        modelContext.insert(item)
        try? modelContext.save()
        selection = item
        Haptics.impact(.light)
    }

    /// Move an unscheduled task onto the timeline at the next open slot.
    private func schedule(_ item: TodoItem) {
        item.startTime = defaultStart()
        if item.durationMinutes == 0 { item.durationMinutes = 30 }
        try? modelContext.save()
        selection = item
        Haptics.impact(.light)
    }

    private func toggleComplete(_ item: TodoItem) {
        item.completedAt = item.isCompleted ? nil : Date()
        try? modelContext.save()
        Haptics.impact(.light)
    }

    /// Next free time on the selected day: the end of the last block, or 9:00 AM.
    private func defaultStart() -> Date {
        if let last = scheduled.last, let end = last.endTime {
            return end
        }
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
    }

    /// Minutes of free time between block `index` and the next block.
    private func freeGap(afterIndex index: Int) -> Int? {
        guard index < scheduled.count - 1,
              let end  = scheduled[index].endTime,
              let next = scheduled[index + 1].startTime else { return nil }
        let minutes = cal.dateComponents([.minute], from: end, to: next).minute ?? 0
        return minutes > 0 ? minutes : nil
    }

    private func durationText(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0          { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - PlannerMetrics

/// Shared layout constants so the time gutter, icon bubble and connector line
/// stay aligned across block rows and gap labels.
private enum PlannerMetrics {
    static let timeGutter: CGFloat = 56   // width reserved for the time label
    static let bubble:     CGFloat = 36   // icon bubble diameter
}

// MARK: - PlannerBlockRow

/// One scheduled block on the timeline.
private struct PlannerBlockRow: View {

    let item: TodoItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.sm) {
            // Time gutter
            VStack(alignment: .trailing, spacing: 2) {
                Text(startText)
                    .font(DS.Text.valueSmall)
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                if item.durationMinutes > 0, let end = item.endTime {
                    Text(timeString(end))
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
            .frame(width: PlannerMetrics.timeGutter, alignment: .trailing)

            // Icon bubble — gradient fill + white gloss highlight
            Image(systemName: item.iconName ?? "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: PlannerMetrics.bubble, height: PlannerMetrics.bubble)
                .background {
                    Circle()
                        .fill(item.isCompleted ? DS.Color.textTertiary : Color.accentColor)
                        .overlay {
                            Circle().fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(item.isCompleted ? 0 : 0.28), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                        }
                }

            // Title + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(DS.Text.body)
                    .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .lineLimit(1)

                if item.durationMinutes > 0 {
                    Text(durationLabel)
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DS.Color.surface, in: Capsule())
                }
            }

            Spacer(minLength: DS.Space.sm)

            // Completion circle
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? "Mark not done" : "Mark done")
        }
        .padding(DS.Space.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control)
                .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        )
        .overlay(alignment: .leading) {
            if isSelected {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.accentColor)
                    .frame(width: 3)
                    .padding(.vertical, DS.Space.xs)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private var startText: String {
        item.startTime.map(timeString) ?? "—"
    }

    private var durationLabel: String {
        let h = item.durationMinutes / 60, m = item.durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m) min"
    }

    private func timeString(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}
