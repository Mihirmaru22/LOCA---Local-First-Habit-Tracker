//
//  CheckInButton.swift
//  LOCA
//
//  Phase 6.1 — Binary Check-In Path
//  Phase 6.2 — Quantitative Check-In Path (extended)
//

import SwiftUI
import SwiftData
import os

// MARK: - CheckInButton

/// The primary check-in interaction surface for a `HabitBoard`.
///
/// Self-contained: owns its own `@Query` on today's `LogEntry` records for
/// the given board, filtered by both `boardID` (ADR-003) and a date-range
/// bound covering today's calendar window (Engineering Principles §5.2).
/// This makes `CheckInButton` reusable across `HabitDetailView`,
/// `WidgetKit` interactive buttons (Phase 9), and any future context
/// without requiring the parent to compute or pass log state downward.
///
/// ## Binary Path (Phase 6.1)
/// A single tap inserts `LogEntry(value: 1.0)`, calls
/// `board.updateStreak(using:)`, saves, triggers a `.rigid` haptic, and
/// schedules a debounced widget reload via `WidgetRefreshCoordinator`.
/// Once today's total reaches `effectiveTarget`, the button transitions to
/// a "Done Today" completed state and is disabled.
///
/// ## Quantitative Path (Phase 6.2)
/// A tap presents `CheckInSheet` as a `.sheet`. The sheet handles value
/// entry, optional note, validation, persistence, haptic, and widget reload.
/// The button label reflects today's running total vs target:
/// - No entries: "Check In"
/// - Partial progress: "2.3 / 5.0 mi"
/// - Goal met: "3.5 mi · Goal Met" (button remains active — multiple entries
///   per day are allowed for quantitative habits)
///
/// ## Animation
/// Uses `Animation.rippleConfirm` (Engineering Principles §7.1) via the
/// `CheckInButtonStyle` custom `ButtonStyle`. Respects
/// `@Environment(\.accessibilityReduceMotion)`.
///
/// ## Haptics
/// Binary: `UIImpactFeedbackGenerator(style: .rigid)` fired after a successful
/// `modelContext.save()`. Quantitative: fired inside `CheckInSheet` after save.
/// Both gated on `#if canImport(UIKit)` for macOS compatibility.
struct CheckInButton: View {

    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext

    // Binary error state — quantitative errors are handled inside CheckInSheet.
    @State private var showSaveError = false

    // Quantitative sheet presentation state.
    @State private var showingSheet = false

    /// ADR-003 compliant, date-bounded query on today's log entries.
    /// Shared by both binary and quantitative paths for `todaysTotal`
    /// and `isCompletedToday` computation.
    @Query private var todaysLogs: [LogEntry]

    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "CheckIn")

    // MARK: - Initialiser

    init(board: HabitBoard) {
        self.board = board

        let boardID = board.id
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        // Defensive fallback: 86,400 seconds is a safe approximation of
        // "tomorrow" if calendar arithmetic fails.
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)
            ?? Date(timeIntervalSinceNow: 86_400)

        // Engineering Principles §5.2: @Query on LogEntry must include a
        // date-range bound. Unbounded fetches are banned.
        _todaysLogs = Query(
            filter: #Predicate<LogEntry> {
                $0.boardID == boardID
                    && $0.timestamp >= todayStart
                    && $0.timestamp < tomorrowStart
            },
            sort: [SortDescriptor(\.timestamp, order: .reverse)]
        )
    }

    // MARK: - Derived State

    private var todaysTotal: Double {
        todaysLogs.reduce(0.0) { $0 + $1.value }
    }

    /// True when today's cumulative total meets or exceeds the board's
    /// effective target.
    /// - Binary: disables the button once met.
    /// - Quantitative: changes button label only; button stays active.
    private var isCompletedToday: Bool {
        todaysTotal >= board.effectiveTarget
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch board.metric {
            case .binary:
                binaryButton
            case .quantitative:
                quantitativeButton
            }
        }
        .alert("Couldn't Save Check-In", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your check-in couldn't be saved. Please try again.")
        }
    }

    // MARK: - Binary Button (Phase 6.1)

    @ViewBuilder
    private var binaryButton: some View {
        Button {
            logBinaryEntry()
        } label: {
            Label(
                isCompletedToday ? "Done Today" : "Check In",
                systemImage: isCompletedToday ? "checkmark.circle.fill" : "checkmark.circle"
            )
        }
        .buttonStyle(CheckInButtonStyle(
            isCompleted: isCompletedToday,
            tint: ColorPalette[board.colorIndex]
        ))
        .disabled(isCompletedToday)
        .accessibilityLabel("Check in \(board.name)")
        .accessibilityHint(
            isCompletedToday
                ? "Already completed today"
                : "Logs today's entry for \(board.name)"
        )
        .accessibilityValue(isCompletedToday ? "Completed" : "Not yet logged")
        .accessibilityAddTraits(isCompletedToday ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Quantitative Button (Phase 6.2)

    // MARK: Always Active
    //
    // Quantitative habits allow multiple entries per day (e.g., 3 mi in the
    // morning, 2 mi in the evening). The button is never disabled — only its
    // label and visual state change when the daily goal is reached.
    // `.disabled()` is intentionally absent here; compare with binaryButton
    // which gates `.disabled(isCompletedToday)`.

    @ViewBuilder
    private var quantitativeButton: some View {
        Button {
            showingSheet = true
        } label: {
            Label(quantitativeLabel, systemImage: quantitativeIcon)
        }
        .buttonStyle(CheckInButtonStyle(
            isCompleted: isCompletedToday,
            tint: ColorPalette[board.colorIndex]
        ))
        .sheet(isPresented: $showingSheet) {
            CheckInSheet(board: board)
        }
        .accessibilityLabel("Check in \(board.name)")
        .accessibilityHint("Opens value entry for \(board.name)")
        .accessibilityValue(quantitativeLabel)
    }

    // MARK: Quantitative Label Computation
    //
    // Three display states:
    //   1. No entries today     → "Check In" (same as binary pre-log CTA)
    //   2. Progress, goal unmet → "2.3 / 5.0 mi"
    //   3. Goal met             → "3.5 mi · Goal Met" (encouraging, not blocking)

    private var quantitativeLabel: String {
        guard !todaysLogs.isEmpty else { return "Check In" }

        let totalStr = todaysTotal.formatted(.number.precision(.fractionLength(0...2)))
        let unit = board.unitLabel.map { " \($0)" } ?? ""

        if isCompletedToday {
            return "\(totalStr)\(unit) · Goal Met"
        }

        let targetStr = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
        return "\(totalStr) / \(targetStr)\(unit)"
    }

    private var quantitativeIcon: String {
        isCompletedToday ? "checkmark.circle.fill" : "plus.circle"
    }

    // MARK: - Binary Check-In Action (Phase 6.1)

    private func logBinaryEntry() {
        let entry = LogEntry(
            value: 1.0,
            boardID: board.id,
            board: board
        )
        modelContext.insert(entry)
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            triggerConfirmationHaptic()
            WidgetRefreshCoordinator.shared.scheduleReload()
            logger.debug("Binary check-in saved for board '\(board.name, privacy: .public)'.")
        } catch {
            logger.error(
                "Binary check-in save failed for board '\(board.name, privacy: .public)': \(error.localizedDescription, privacy: .public)"
            )
            modelContext.rollback()
            showSaveError = true
        }
    }

    // MARK: - Haptics

    private func triggerConfirmationHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}

// MARK: - CheckInButtonStyle

/// Applies the canonical check-in press animation and adapts visual appearance
/// based on completion state.
///
/// - **Normal**: board-color filled pill, white label.
/// - **Completed**: board-color tinted (15% opacity) pill, board-color label.
///
/// For binary habits, `.disabled(true)` is applied externally alongside the
/// completed visual. For quantitative habits, the completed visual appears
/// without disabling — communicating "goal met but still tappable."
private struct CheckInButtonStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isCompleted: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isCompleted ? tint : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isCompleted ? tint.opacity(0.15) : tint,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(
                reduceMotion ? .linear(duration: 0.1) : .rippleConfirm,
                value: configuration.isPressed
            )
    }
}

// MARK: - Preview

@MainActor
private func makeBinaryCheckInContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let board = HabitBoard(name: "Meditate", colorIndex: 5)
    container.mainContext.insert(board)
    try? container.mainContext.save()
    return (container, board)
}

@MainActor
private func makeBinaryCompletedContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let board = HabitBoard(name: "Meditate", colorIndex: 5)
    container.mainContext.insert(board)
    let entry = LogEntry(value: 1.0, boardID: board.id, board: board)
    container.mainContext.insert(entry)
    try? container.mainContext.save()
    return (container, board)
}

@MainActor
private func makeQuantitativeCheckInContainer(todayTotal: Double = 0) -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let board = HabitBoard(
        name: "Running",
        metricType: HabitBoard.MetricType.quantitative.rawValue,
        targetValue: 5.0,
        unitLabel: "mi",
        colorIndex: 0
    )
    container.mainContext.insert(board)
    if todayTotal > 0 {
        let entry = LogEntry(value: todayTotal, boardID: board.id, board: board)
        container.mainContext.insert(entry)
    }
    try? container.mainContext.save()
    return (container, board)
}

#Preview("Binary — Not Yet Logged") {
    let (container, board) = makeBinaryCheckInContainer()
    return CheckInButton(board: board).padding().modelContainer(container)
}

#Preview("Binary — Done Today") {
    let (container, board) = makeBinaryCompletedContainer()
    return CheckInButton(board: board).padding().modelContainer(container)
}

#Preview("Quantitative — No Entries") {
    let (container, board) = makeQuantitativeCheckInContainer()
    return CheckInButton(board: board).padding().modelContainer(container)
}

#Preview("Quantitative — In Progress (2.3 mi)") {
    let (container, board) = makeQuantitativeCheckInContainer(todayTotal: 2.3)
    return CheckInButton(board: board).padding().modelContainer(container)
}

#Preview("Quantitative — Goal Met (6.1 mi)") {
    let (container, board) = makeQuantitativeCheckInContainer(todayTotal: 6.1)
    return CheckInButton(board: board).padding().modelContainer(container)
}
