import SwiftUI
import SwiftData

// MARK: - HabitDesignVariant

enum HabitDesignVariant: String, CaseIterable, Identifiable {
    case habit1 = "Bento Ring Cards"
    case habit2 = "Weekly Horizon Strips"
    case habit3 = "Executive Progress Matrix"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .habit1: return "circle.grid.2x2"
        case .habit2: return "calendar.day.timeline.leading"
        case .habit3: return "chart.bar.xaxis"
        }
    }
}

// MARK: - MacHabitContentColumn (H1)

/// Middle column for the Habits section with Layout dropdown and Quantitative/Binary logging support.
struct MacHabitContentColumn: View {

    @Binding var selection: HabitBoard?

    @Query(filter: #Predicate<HabitBoard> { $0.habitKindRaw == 0 },
           sort: [SortDescriptor(\HabitBoard.name)], animation: .default)
    private var keystoneBoards: [HabitBoard]

    private var boards: [HabitBoard] { keystoneBoards.filter { $0.archivedAt == nil } }

    @Environment(\.modelContext) private var modelContext
    @AppStorage("mac_habit_layout_v2") private var selectedVariant: HabitDesignVariant = .habit1
    @State private var showingCreateSheet = false
    @State private var showCheckInError   = false

    init(selection: Binding<HabitBoard?>) {
        self._selection = selection
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top Toolbar Row: Count + Plus Button
            HStack(spacing: DS.Space.sm) {
                Text("\(boards.count) habits")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)

                Spacer()

                // Plus Button
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .padding(5)
                        .background(Color.accentColor.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .help("New Habit (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)

            Divider()

            // Main List Content
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.md) {
                    switch selectedVariant {
                    case .habit1:
                        Habit1BentoRingsView(boards: boards, selection: $selection, onCheck: handleHabitAction, onAddAmount: logAmountDirect, onArchive: archiveHabit)
                    case .habit2:
                        Habit2HorizonStripsView(boards: boards, selection: $selection, onCheck: handleHabitAction, onArchive: archiveHabit)
                    case .habit3:
                        Habit3ProgressMatrixView(boards: boards, selection: $selection, onCheck: handleHabitAction, onAddAmount: logAmountDirect, onArchive: archiveHabit)
                    }
                }
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.md)
            }
            .overlay {
                if boards.isEmpty {
                    ContentUnavailableView {
                        Label("No Habits", systemImage: "checkmark.circle")
                    } description: {
                        Text("Press ⌘N or the + button to create your first habit.")
                    }
                }
            }
        }
        .navigationTitle("Habits")
        .sheet(isPresented: $showingCreateSheet) {
            MacHabitFormPanel()
        }
        .alert("Couldn't Save Check-in", isPresented: $showCheckInError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The check-in couldn't be saved. Please try again.")
        }
    }

    private func handleHabitAction(_ board: HabitBoard) {
        do {
            if board.metric == .binary {
                try CheckInWriter.toggleBinary(board: board, context: modelContext)
            } else {
                let todayLogs = (board.logs ?? []).filter { $0.timestamp.isToday() && $0.archivedAt == nil }
                let currentTotal = todayLogs.reduce(0.0) { $0 + $1.value }
                if currentTotal >= board.effectiveTarget {
                    // Already complete: reset/delete today's logs
                    for entry in todayLogs {
                        try CheckInWriter.delete(entry, board: board, context: modelContext)
                    }
                } else {
                    // Incomplete: fill remaining target
                    let remaining = max(1.0, board.effectiveTarget - currentTotal)
                    try CheckInWriter.insert(value: remaining, board: board, context: modelContext)
                }
            }
            Haptics.impact(.rigid)
        } catch {
            showCheckInError = true
        }
    }

    private func logAmountDirect(_ amount: Double, for board: HabitBoard) {
        do {
            try CheckInWriter.insert(value: amount, board: board, context: modelContext)
            Haptics.impact(.light)
        } catch {
            showCheckInError = true
        }
    }

    private func archiveHabit(_ board: HabitBoard) {
        do {
            if selection?.id == board.id {
                selection = nil
            }
            try board.archive(in: modelContext)
            Haptics.impact(.light)
        } catch {
            showCheckInError = true
        }
    }
}

// MARK: - Design 1: Habit1BentoRingsView (Bento Cards with Progress Rings)

private struct Habit1BentoRingsView: View {

    let boards: [HabitBoard]
    @Binding var selection: HabitBoard?
    let onCheck: (HabitBoard) -> Void
    let onAddAmount: (Double, HabitBoard) -> Void
    let onArchive: (HabitBoard) -> Void

    var body: some View {
        LazyVStack(spacing: 6) {
            ForEach(boards, id: \.id) { board in
                Habit1CardRow(
                    board: board, 
                    isSelected: selection?.id == board.id, 
                    onCheck: { onCheck(board) },
                    onAddAmount: { amount in onAddAmount(amount, board) },
                    onArchive: { onArchive(board) }
                ) {
                    selection = board
                }
            }
        }
    }
}

private struct Habit1CardRow: View {
    let board: HabitBoard
    let isSelected: Bool
    let onCheck: () -> Void
    let onAddAmount: (Double) -> Void
    let onArchive: () -> Void
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var showAmountPopover = false
    @State private var quickInput = ""

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() && $0.archivedAt == nil }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progressFraction: Double {
        max(0, min(1, todaysTotal / board.effectiveTarget))
    }

    private var isDone: Bool { 
        if board.metric == .binary {
            return todaysTotal >= 1.0
        }
        return todaysTotal >= board.effectiveTarget 
    }
    
    private var color: Color { ColorPalette[board.colorIndex] }
    private var unit: String { board.unitLabel ?? (board.metric == .quantitative ? "units" : "") }

    var body: some View {
        HStack(spacing: 10) {
            // Color Indicator Bar
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4, height: 28)

            // Name & Target Details
            VStack(alignment: .leading, spacing: 2) {
                Text(board.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isDone ? DS.Color.textSecondary : DS.Color.textPrimary)
                    .lineLimit(1)

                if board.metric == .quantitative {
                    Text("\(todaysTotal.formatted(.number.precision(.fractionLength(0...1)))) / \(board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))) \(unit)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isDone ? color : DS.Color.textTertiary)
                } else {
                    Text(isDone ? "Completed today" : "Pending check-in")
                        .font(.system(size: 10))
                        .foregroundStyle(isDone ? color : DS.Color.textTertiary)
                }
            }

            Spacer()

            // Quantitative Quick-Add Plus Button (shows on hover for quantitative habits)
            if board.metric == .quantitative && (isHovered || isSelected) {
                Button {
                    showAmountPopover = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help("Add tracking amount")
                .popover(isPresented: $showAmountPopover) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Log \(board.name)")
                            .font(.system(size: 12, weight: .bold))
                        
                        HStack(spacing: 6) {
                            TextField("Amount (\(unit))", text: $quickInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                                .onSubmit {
                                    let cleaned = quickInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                                    if let val = Double(cleaned), val > 0 {
                                        onAddAmount(val)
                                        quickInput = ""
                                        showAmountPopover = false
                                    }
                                }

                            Button("Add") {
                                let cleaned = quickInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                                if let val = Double(cleaned), val > 0 {
                                    onAddAmount(val)
                                    quickInput = ""
                                    showAmountPopover = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(12)
                }
            }

            // Streak Flame (if active)
            if board.currentStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                    Text("\(board.currentStreak)d")
                        .font(.system(size: 10, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12), in: Capsule())
            }

            // Interactive Check Ring / Progress Ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 22, height: 22)

                Circle()
                    .trim(from: 0, to: CGFloat(progressFraction))
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 22, height: 22)

                if isDone {
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Circle())
            .highPriorityGesture(TapGesture().onEnded {
                onCheck()
            })
            .help(isDone ? "Undo check-in" : (board.metric == .quantitative ? "Complete daily target" : "Mark done"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(
            isSelected ? color.opacity(0.12) : (isHovered ? DS.Color.surfaceRecessed.opacity(0.5) : DS.Color.surface),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? color.opacity(0.6) : DS.Color.border.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture { onSelect() }
        .contextMenu {
            Button(role: .destructive) {
                onArchive()
            } label: {
                Label("Archive Habit", systemImage: "archivebox")
            }
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Design 2: Habit2HorizonStripsView (7-Day Horizon Strips)

private struct Habit2HorizonStripsView: View {

    let boards: [HabitBoard]
    @Binding var selection: HabitBoard?
    let onCheck: (HabitBoard) -> Void
    let onArchive: (HabitBoard) -> Void

    private var weekDays: [Date] {
        let cal = Calendar.current
        var comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        comp.weekday = 2 // Monday start
        guard let monday = cal.date(from: comp) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Strip
            HStack {
                Text("HABIT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(weekDays, id: \.self) { day in
                        let isToday = Calendar.current.isDateInToday(day)
                        Text(formatDayLetter(day))
                            .font(.system(size: 9, weight: isToday ? .bold : .medium))
                            .foregroundStyle(isToday ? Color.accentColor : DS.Color.textTertiary)
                            .frame(width: 14)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(DS.Color.surfaceRecessed)

            Divider()

            LazyVStack(spacing: 0) {
                ForEach(boards, id: \.id) { board in
                    Habit2StripRow(board: board, isSelected: selection?.id == board.id, weekDays: weekDays, onCheck: { onCheck(board) }, onArchive: { onArchive(board) }) {
                        selection = board
                    }
                    if board.id != boards.last?.id {
                        Divider().padding(.leading, 12)
                    }
                }
            }
        }
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    private func formatDayLetter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f.string(from: date)
    }
}

private struct Habit2StripRow: View {
    let board: HabitBoard
    let isSelected: Bool
    let weekDays: [Date]
    let onCheck: () -> Void
    let onArchive: () -> Void
    let onSelect: () -> Void

    @State private var isHovered = false
    private var color: Color { ColorPalette[board.colorIndex] }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(board.name)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)

            Spacer()

            // 7-Day Micro Squares
            HStack(spacing: 6) {
                ForEach(weekDays, id: \.self) { day in
                    let isDone = isDayCompleted(day)
                    let isToday = Calendar.current.isDateInToday(day)

                    ZStack {
                        if isDone {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: 14, height: 14)
                        } else if isToday {
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(color.opacity(0.7), lineWidth: 1)
                                .frame(width: 14, height: 14)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DS.Color.surfaceRecessed)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .highPriorityGesture(TapGesture().onEnded {
                        if isToday { onCheck() }
                    })
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .background(isSelected ? color.opacity(0.12) : (isHovered ? DS.Color.surfaceRecessed.opacity(0.4) : Color.clear))
        .onTapGesture { onSelect() }
        .contextMenu {
            Button(role: .destructive) {
                onArchive()
            } label: {
                Label("Archive Habit", systemImage: "archivebox")
            }
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func isDayCompleted(_ date: Date) -> Bool {
        let cal = Calendar.current
        let target = board.effectiveTarget
        let logs = (board.logs ?? []).filter { $0.archivedAt == nil && cal.isDate($0.timestamp, inSameDayAs: date) }
        return logs.reduce(0.0) { $0 + $1.value } >= target
    }
}

// MARK: - Design 3: Habit3ProgressMatrixView (Executive Minimal with Progress Bars)

private struct Habit3ProgressMatrixView: View {

    let boards: [HabitBoard]
    @Binding var selection: HabitBoard?
    let onCheck: (HabitBoard) -> Void
    let onAddAmount: (Double, HabitBoard) -> Void
    let onArchive: (HabitBoard) -> Void

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(boards, id: \.id) { board in
                Habit3MatrixRow(
                    board: board, 
                    isSelected: selection?.id == board.id, 
                    onCheck: { onCheck(board) },
                    onAddAmount: { amount in onAddAmount(amount, board) },
                    onArchive: { onArchive(board) }
                ) {
                    selection = board
                }
            }
        }
    }
}

private struct Habit3MatrixRow: View {
    let board: HabitBoard
    let isSelected: Bool
    let onCheck: () -> Void
    let onAddAmount: (Double) -> Void
    let onArchive: () -> Void
    let onSelect: () -> Void

    @State private var isHovered = false

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() && $0.archivedAt == nil }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progressFraction: Double {
        max(0, min(1, todaysTotal / board.effectiveTarget))
    }

    private var isDone: Bool { 
        if board.metric == .binary {
            return todaysTotal >= 1.0
        }
        return todaysTotal >= board.effectiveTarget 
    }
    private var color: Color { ColorPalette[board.colorIndex] }
    private var unit: String { board.unitLabel ?? "" }

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                // Color Pill Badge
                Text(board.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                if board.metric == .quantitative {
                    Text("\(todaysTotal.formatted(.number.precision(.fractionLength(0...1)))) / \(board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))) \(unit)")
                        .font(.system(size: 11, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(isDone ? color : DS.Color.textSecondary)
                }

                // Tactile Square Check
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isDone ? color : DS.Color.surfaceRecessed)
                        .frame(width: 18, height: 18)

                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isDone ? color : DS.Color.border, lineWidth: 1)
                        .frame(width: 18, height: 18)

                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .contentShape(Rectangle())
                .highPriorityGesture(TapGesture().onEnded {
                    onCheck()
                })
                .help(isDone ? "Undo check-in" : "Mark done")
            }

            // Slim Gradient Progress Bar
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DS.Color.surfaceRecessed)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, proxy.size.width * CGFloat(progressFraction)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .contentShape(Rectangle())
        .background(
            isSelected ? color.opacity(0.12) : (isHovered ? DS.Color.surfaceRecessed.opacity(0.5) : DS.Color.surface),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? color.opacity(0.6) : DS.Color.border.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture { onSelect() }
        .contextMenu {
            Button(role: .destructive) {
                onArchive()
            } label: {
                Label("Archive Habit", systemImage: "archivebox")
            }
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
