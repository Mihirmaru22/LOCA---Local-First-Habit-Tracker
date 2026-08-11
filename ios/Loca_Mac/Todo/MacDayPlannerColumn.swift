import SwiftUI
import SwiftData

// MARK: - MacDayPlannerColumn  (T10 — real proportional timeline)

struct MacDayPlannerColumn: View {

    @Binding var selection: TodoItem?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: [SortDescriptor(\TodoItem.startTime)], animation: .default)
    private var allItems: [TodoItem]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)

    // Drag-to-move state
    @State private var draggingID:        UUID?  = nil
    @State private var dragOriginalStart: Date?  = nil
    @State private var dragDeltaMinutes:  Int    = 0

    // Resize state
    @State private var resizingID:            UUID? = nil
    @State private var resizeOriginalMinutes: Int   = 0
    @State private var resizeDeltaMinutes:    Int   = 0

    // Ghost affordance
    @State private var hoverY: CGFloat? = nil

    private let cal = Calendar.current

    // MARK: - Derived collections

    private var active: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil }
    }

    private var scheduled: [TodoItem] {
        active
            .filter { item in
                guard let s = item.startTime else { return false }
                return cal.isDate(s, inSameDayAs: selectedDate)
            }
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    private var unscheduled: [TodoItem] {
        active.filter { item in
            guard item.startTime == nil, let due = item.dueDate else { return false }
            return cal.isDate(due, inSameDayAs: selectedDate)
        }
    }

    private var weekDays: [Date] {
        guard let interval = cal.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
    }

    // MARK: - Timeline geometry

    private enum TM {
        static let ppm:        CGFloat = 1.0   // points per minute
        static let gutter:     CGFloat = 52    // hour-label column width
        static let blockInset: CGFloat = 4     // horizontal breathing room per block
        static let minHeight:  CGFloat = 34    // minimum block height
        static let bottomPad:  CGFloat = 48    // breathing room below last hour
        static let resizeZone: CGFloat = 14    // bottom pt that triggers resize
    }

    private var railStart: Date {
        let day7 = cal.date(bySettingHour: 7, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let earliest = scheduled.compactMap { $0.startTime }.min()
        if let e = earliest, e < day7 { return floorHour(e) }
        return day7
    }

    private var railEnd: Date {
        let day21 = cal.date(bySettingHour: 21, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let latest = scheduled.compactMap { $0.endTime }.max()
        if let l = latest, l > day21 { return ceilHour(l) }
        return day21
    }

    private var totalMinutes: CGFloat {
        CGFloat(max(60, cal.dateComponents([.minute], from: railStart, to: railEnd).minute ?? 840))
    }

    private var totalHeight: CGFloat { totalMinutes * TM.ppm + TM.bottomPad }

    private func yFor(_ date: Date) -> CGFloat {
        let m = CGFloat(cal.dateComponents([.minute], from: railStart, to: date).minute ?? 0)
        return m * TM.ppm
    }

    private func timeAt(_ y: CGFloat) -> Date {
        let minutes = Int(max(0, y / TM.ppm))
        return cal.date(byAdding: .minute, value: minutes, to: railStart) ?? railStart
    }

    private func snap5(_ date: Date) -> Date {
        var c = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let m = c.minute else { return date }
        c.minute = (m / 5) * 5; c.second = 0
        return cal.date(from: c) ?? date
    }

    private func floorHour(_ date: Date) -> Date {
        var c = cal.dateComponents([.year, .month, .day, .hour], from: date)
        c.minute = 0; c.second = 0
        return cal.date(from: c) ?? date
    }

    private func ceilHour(_ date: Date) -> Date {
        var c = cal.dateComponents([.year, .month, .day, .hour], from: date)
        c.hour = (c.hour ?? 0) + 1; c.minute = 0; c.second = 0
        return cal.date(from: c) ?? date
    }

    private var railHours: [Date] {
        var result: [Date] = []
        var cursor = floorHour(railStart)
        while cursor <= railEnd {
            result.append(cursor)
            cursor = cal.date(byAdding: .hour, value: 1, to: cursor) ?? cursor.addingTimeInterval(3600)
        }
        return result
    }

    // Effective start time of a block — accounts for live drag delta
    private func effectiveStart(_ item: TodoItem) -> Date {
        guard draggingID == item.id, let orig = dragOriginalStart else {
            return item.startTime ?? selectedDate
        }
        return cal.date(byAdding: .minute, value: dragDeltaMinutes, to: orig) ?? orig
    }

    private func blockHeight(_ item: TodoItem) -> CGFloat {
        var mins = item.durationMinutes
        if resizingID == item.id { mins = max(5, mins + resizeDeltaMinutes) }
        return max(TM.minHeight, CGFloat(mins) * TM.ppm)
    }

    // MARK: - Overlap layout

    struct LayoutBlock {
        let item: TodoItem
        let column: Int
        let totalColumns: Int
    }

    private var layoutBlocks: [LayoutBlock] {
        guard !scheduled.isEmpty else { return [] }

        // Greedy column assignment (interval graph coloring)
        var assignments: [UUID: Int] = [:]
        for item in scheduled {
            guard let start = item.startTime else { continue }
            let end = item.endTime ?? cal.date(byAdding: .minute, value: 1, to: start)!
            var occupied = Set<Int>()
            for other in scheduled where other.id != item.id {
                guard let oStart = other.startTime else { continue }
                let oEnd = other.endTime ?? cal.date(byAdding: .minute, value: 1, to: oStart)!
                if start < oEnd && end > oStart, let col = assignments[other.id] {
                    occupied.insert(col)
                }
            }
            var col = 0; while occupied.contains(col) { col += 1 }
            assignments[item.id] = col
        }

        return scheduled.compactMap { item in
            guard let start = item.startTime, let col = assignments[item.id] else { return nil }
            let end = item.endTime ?? cal.date(byAdding: .minute, value: 1, to: start)!
            var maxCol = col
            for other in scheduled where other.id != item.id {
                guard let oStart = other.startTime else { continue }
                let oEnd = other.endTime ?? cal.date(byAdding: .minute, value: 1, to: oStart)!
                if start < oEnd && end > oStart, let oCol = assignments[other.id] {
                    maxCol = max(maxCol, oCol)
                }
            }
            return LayoutBlock(item: item, column: col, totalColumns: maxCol + 1)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            weekStrip
            Divider()
            timeline
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaShiftDay)) { note in
            if let delta = note.object as? Int { shiftDay(delta) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaJumpToToday)) { _ in
            withAnimation(reduceMotion ? nil : DS.Motion.settle) {
                selectedDate = cal.startOfDay(for: .now)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaNudgeBlock)) { note in
            guard let delta = note.object as? Int,
                  let item = selection, let start = item.startTime else { return }
            item.startTime = snap5(cal.date(byAdding: .minute, value: delta, to: start) ?? start)
            try? modelContext.save()
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaAddBlock)) { _ in
            addBlock()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: DS.Space.sm) {
            Button { shiftDay(-1) } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .help("Previous day  ←")

            Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(DS.Text.heading)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { selectedDate = cal.startOfDay(for: .now) }
                .help("Jump to today  ⌘T")

            Button { shiftDay(1) } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .help("Next day  →")

            Button(action: addBlock) {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .help("Add a time block  ⌘N")
        }
        .font(DS.Text.body)
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { dayCell($0) }
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
                .foregroundStyle(isSelected ? .white : DS.Color.textPrimary)
                .frame(width: 30, height: 30)
                .background { Circle().fill(isSelected ? Color.accentColor : Color.clear) }
                .overlay {
                    if isToday && !isSelected { Circle().stroke(Color.accentColor, lineWidth: 1.5) }
                }

            Circle()
                .fill(count > 0 ? Color.accentColor.opacity(0.7) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(reduceMotion ? nil : DS.Motion.settle) {
                selectedDate = cal.startOfDay(for: day)
            }
        }
    }

    // MARK: - Timeline shell

    private var timeline: some View {
        ScrollView {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    timelineCanvas(width: geo.size.width)
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let loc):
                                hoverY = loc.x > TM.gutter ? loc.y : nil
                            case .ended:
                                hoverY = nil
                            }
                        }
                }
                .frame(height: totalHeight)

                if !unscheduled.isEmpty {
                    unscheduledSection
                        .padding(.horizontal, DS.Space.md)
                }
            }
        }
        .scrollDisabled(draggingID != nil || resizingID != nil)
    }

    // MARK: - Timeline canvas

    @ViewBuilder
    private func timelineCanvas(width: CGFloat) -> some View {
        let blockAreaWidth = width - TM.gutter

        ZStack(alignment: .topLeading) {
            // Size anchor
            Color.clear.frame(width: width, height: totalHeight)

            // Hour rail: guide lines + labels
            ForEach(railHours, id: \.self) { hour in
                hourTick(hour, totalWidth: width)
            }

            // Scheduled blocks
            ForEach(layoutBlocks, id: \.item.id) { lb in
                plannerBlockView(lb, blockAreaWidth: blockAreaWidth)
            }

            // Floating time bubble during drag
            if let did = draggingID,
               let lb  = layoutBlocks.first(where: { $0.item.id == did }) {
                let colW  = blockAreaWidth / CGFloat(lb.totalColumns)
                let xPos  = TM.gutter + CGFloat(lb.column) * colW + colW + TM.blockInset
                let startY = yFor(effectiveStart(lb.item))

                Text(effectiveStart(lb.item), format: .dateTime.hour().minute())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor, in: Capsule())
                    .offset(x: min(xPos, width - 70), y: startY - 2)
                    .animation(nil, value: startY)
            }

            // Now line — today only, updates every minute
            if cal.isDateInToday(selectedDate) {
                TimelineView(.periodic(from: .now, by: 60)) { ctx in
                    nowLine(at: ctx.date, totalWidth: width)
                }
            }

            // Ghost affordance
            ghostAffordance(totalWidth: width, blockAreaWidth: blockAreaWidth)
        }
    }

    // MARK: - Hour tick

    @ViewBuilder
    private func hourTick(_ hour: Date, totalWidth: CGFloat) -> some View {
        let y = yFor(hour)

        // Guide line
        Rectangle()
            .fill(DS.Color.separator.opacity(0.25))
            .frame(width: totalWidth - TM.gutter, height: 0.5)
            .offset(x: TM.gutter, y: y)

        // Hour label (10pt rounded, right-aligned in gutter)
        Text(hour, format: .dateTime.hour())
            .font(.system(size: 10, design: .rounded))
            .foregroundStyle(DS.Color.textTertiary)
            .frame(width: TM.gutter - 8, alignment: .trailing)
            .offset(x: 0, y: y - 7)
    }

    // MARK: - Block view

    @ViewBuilder
    private func plannerBlockView(_ lb: LayoutBlock, blockAreaWidth: CGFloat) -> some View {
        let item    = lb.item
        let startY  = yFor(effectiveStart(item))
        let height  = blockHeight(item)
        let colW    = blockAreaWidth / CGFloat(lb.totalColumns)
        let xPos    = TM.gutter + CGFloat(lb.column) * colW + TM.blockInset
        let width   = colW - TM.blockInset * 2

        PlannerBlock(
            item:       item,
            height:     height,
            isSelected: selection?.id == item.id,
            isDragging: draggingID == item.id,
            isResizing: resizingID == item.id,
            reduceMotion: reduceMotion,
            onSelect:   {
                withAnimation(reduceMotion ? .linear(duration: 0.1) : DS.Motion.settle) {
                    selection = item
                }
            },
            onToggle:   { toggleComplete(item) },
            onDragChanged:  { delta in
                if draggingID == nil {
                    draggingID        = item.id
                    dragOriginalStart = item.startTime
                    dragDeltaMinutes  = 0
                }
                let raw = Int(delta / TM.ppm)
                dragDeltaMinutes = (raw / 5) * 5
            },
            onDragEnded: {
                if let orig = dragOriginalStart {
                    item.startTime = snap5(
                        cal.date(byAdding: .minute, value: dragDeltaMinutes, to: orig) ?? orig
                    )
                    if let startTime = item.startTime, let dueDate = item.dueDate {
                        // Keep dueDate in sync if it was on the original day
                        if cal.isDate(dueDate, inSameDayAs: selectedDate) {
                            item.dueDate = cal.startOfDay(for: startTime)
                        }
                    }
                    try? modelContext.save()
                    Haptics.impact(.light)
                }
                draggingID = nil; dragOriginalStart = nil; dragDeltaMinutes = 0
            },
            onResizeChanged: { delta in
                if resizingID == nil {
                    resizingID            = item.id
                    resizeOriginalMinutes = item.durationMinutes
                }
                let raw = Int(delta / TM.ppm)
                resizeDeltaMinutes = (raw / 5) * 5
            },
            onResizeEnded: {
                if resizingID == item.id {
                    item.durationMinutes = max(5, resizeOriginalMinutes + resizeDeltaMinutes)
                    try? modelContext.save()
                    Haptics.impact(.light)
                }
                resizingID = nil; resizeDeltaMinutes = 0; resizeOriginalMinutes = 0
            }
        )
        .frame(width: width, height: height)
        .offset(x: xPos, y: startY)
        .animation(
            (draggingID == item.id || resizingID == item.id) ? .none :
                (reduceMotion ? .linear(duration: 0.1) : DS.Motion.settle),
            value: startY
        )
        .animation(
            (resizingID == item.id) ? .none :
                (reduceMotion ? .linear(duration: 0.1) : DS.Motion.settle),
            value: height
        )
        .zIndex(selection?.id == item.id || draggingID == item.id ? 10 : 1)
    }

    // MARK: - Now line

    @ViewBuilder
    private func nowLine(at now: Date, totalWidth: CGFloat) -> some View {
        let y = yFor(now)
        if y >= 0 && y <= totalHeight {
            // Leading dot
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: TM.gutter - 4, y: y - 4)

            // Hairline
            Rectangle()
                .fill(Color.red.opacity(0.85))
                .frame(width: totalWidth - TM.gutter, height: 1.5)
                .offset(x: TM.gutter, y: y)
        }
    }

    // MARK: - Ghost affordance

    @ViewBuilder
    private func ghostAffordance(totalWidth: CGFloat, blockAreaWidth: CGFloat) -> some View {
        if let y = hoverY, draggingID == nil, resizingID == nil, !isOverBlock(y: y) {
            let snappedTime = snap5(timeAt(y))
            Button {
                addBlockAt(snappedTime)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                    Text(snappedTime, format: .dateTime.hour().minute())
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.accentColor.opacity(0.75))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
            .offset(x: TM.gutter + TM.blockInset, y: y - 12)
            .animation(nil, value: y)  // no spring-follow on mouse position
        }
    }

    private func isOverBlock(y: CGFloat) -> Bool {
        layoutBlocks.contains { lb in
            guard let start = lb.item.startTime else { return false }
            let blockY = yFor(start)
            return y >= blockY && y <= blockY + blockHeight(lb.item)
        }
    }

    // MARK: - Unscheduled tray

    private var unscheduledSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Divider().padding(.top, DS.Space.md)
            Label("Unscheduled", systemImage: "tray")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.top, DS.Space.sm)
                .padding(.bottom, DS.Space.xs)

            ForEach(unscheduled, id: \.id) { item in
                HStack(spacing: DS.Space.sm) {
                    Button { toggleComplete(item) } label: {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? Color.accentColor : DS.Color.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Text(item.title)
                        .font(DS.Text.body)
                        .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                        .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button { schedule(item) } label: { Image(systemName: "clock.badge.plus") }
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

    // MARK: - Actions

    private func shiftDay(_ delta: Int) {
        if let d = cal.date(byAdding: .day, value: delta, to: selectedDate) {
            withAnimation(reduceMotion ? nil : DS.Motion.settle) { selectedDate = d }
        }
    }

    private func addBlock() { addBlockAt(defaultStart()) }

    private func addBlockAt(_ time: Date) {
        let item = TodoItem(
            title: "New block",
            dueDate: cal.startOfDay(for: selectedDate),
            startTime: time,
            durationMinutes: 30
        )
        modelContext.insert(item)
        try? modelContext.save()
        withAnimation(reduceMotion ? nil : DS.Motion.settle) { selection = item }
        Haptics.impact(.light)
    }

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

    private func defaultStart() -> Date {
        if let last = scheduled.last, let end = last.endTime { return end }
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
    }
}

// MARK: - PlannerBlock

/// An interactive time block on the proportional timeline.
/// A single DragGesture on the whole block handles both move (top area) and resize
/// (bottom 14 pt), determined at gesture-start time.
private struct PlannerBlock: View {

    let item:          TodoItem
    let height:        CGFloat
    let isSelected:    Bool
    let isDragging:    Bool
    let isResizing:    Bool
    let reduceMotion:  Bool

    let onSelect:         () -> Void
    let onToggle:         () -> Void
    let onDragChanged:    (CGFloat) -> Void
    let onDragEnded:      () -> Void
    let onResizeChanged:  (CGFloat) -> Void
    let onResizeEnded:    () -> Void

    @State private var isHovered = false
    @State private var dragMode: BlockDragMode = .none

    private enum BlockDragMode { case none, move, resize }

    var body: some View {
        ZStack(alignment: .bottom) {
            blockBody

            // Resize affordance strip — visible when hovered or selected
            if (isHovered || isSelected) && height > 40 {
                Capsule()
                    .fill(Color.accentColor.opacity(isResizing ? 0.8 : 0.4))
                    .frame(width: 32, height: 3)
                    .padding(.bottom, 4)
            }
        }
        .onHover { isHovered = $0 }
        .scaleEffect(isDragging && !reduceMotion ? 1.02 : 1.0)
        .shadow(
            color: isDragging ? Color.accentColor.opacity(0.3) : .clear,
            radius: isDragging ? 10 : 0, x: 0, y: 4
        )
        .animation(reduceMotion ? .linear(duration: 0.05) : .spring(response: 0.2, dampingFraction: 0.75),
                   value: isDragging)
    }

    private var blockBody: some View {
        HStack(alignment: .top, spacing: DS.Space.sm) {
            // Icon bubble — compact at 28pt
            Image(systemName: item.iconName ?? "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .todoBubble(diameter: 28, done: item.isCompleted)

            // Title + time/duration
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(DS.Text.body)
                    .lineLimit(height < 52 ? 1 : 3)
                    .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)

                if height > 44 {
                    if let start = item.startTime {
                        Text(start, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            // Completion button
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundStyle(item.isCompleted ? Color.accentColor : DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? "Mark not done" : "Mark done")
        }
        .padding(.horizontal, DS.Space.sm)
        .padding(.top, DS.Space.xs)
        .padding(.bottom, DS.Space.xs)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control)
                .fill(blockFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.control)
                .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .highPriorityGesture(
            DragGesture(minimumDistance: 3)
                .onChanged { v in
                    if dragMode == .none {
                        dragMode = v.startLocation.y > (height - TM.resizeZone) ? .resize : .move
                    }
                    switch dragMode {
                    case .move:   onDragChanged(v.translation.height)
                    case .resize: onResizeChanged(v.translation.height)
                    case .none:   break
                    }
                }
                .onEnded { _ in
                    switch dragMode {
                    case .move:   onDragEnded()
                    case .resize: onResizeEnded()
                    case .none:   break
                    }
                    dragMode = .none
                }
        )
    }

    private var blockFill: Color {
        if isSelected  { return Color.accentColor.opacity(0.13) }
        if isDragging  { return Color.accentColor.opacity(0.09) }
        if isHovered   { return DS.Color.textPrimary.opacity(0.04) }
        return DS.Color.surface
    }

    private enum TM {
        static let resizeZone: CGFloat = 14
    }
}
