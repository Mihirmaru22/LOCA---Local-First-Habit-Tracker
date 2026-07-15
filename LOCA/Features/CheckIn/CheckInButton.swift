//
//  CheckInButton.swift
//  LOCA
//
//  Phase 6.1 — Binary Check-In Path
//
//  Phase 6.2 extends this file with the quantitative check-in path (value
//  entry sheet). The `case .quantitative: EmptyView()` branch below is an
//  explicit Phase 6.1 scope gate, not a placeholder.
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
/// A tap opens `CheckInSheet` for value and optional note entry. Implemented
/// in Phase 6.2 — currently returns `EmptyView` (scope gate, not a stub).
///
/// ## Animation
/// Uses `Animation.rippleConfirm` (Engineering Principles §7.1) via the
/// `CheckInButtonStyle` custom `ButtonStyle`. Respects
/// `@Environment(\.accessibilityReduceMotion)`.
///
/// ## Haptics
/// `UIImpactFeedbackGenerator(style: .rigid)` fired after a successful
/// `modelContext.save()` — at the moment of log confirmation, not at
/// animation completion (Engineering Principles §7.2).
/// Gated on `#if canImport(UIKit)` for macOS compatibility.
struct CheckInButton: View {

    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @State private var showSaveError = false

    /// ADR-003 compliant, date-bounded query on today's log entries.
    /// Populated at init time with Calendar.current day boundaries.
    @Query private var todaysLogs: [LogEntry]

    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "CheckIn")

    // MARK: - Initialiser

    init(board: HabitBoard) {
        self.board = board

        let boardID = board.id
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        // Defensive fallback: 86,400 seconds is a safe approximation of
        // "tomorrow" if calendar arithmetic fails — which is not expected
        // under any supported timezone but prevents a crash if it occurs.
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
    /// effective target. Drives the button's completed/disabled state.
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
                // Phase 6.2: quantitative check-in via CheckInSheet.
                // EmptyView produces zero height in the .safeAreaInset
                // container — no visual bar rendered for quantitative boards
                // until Phase 6.2.
                EmptyView()
            }
        }
        .alert("Couldn't Save Check-In", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your check-in couldn't be saved. Please try again.")
        }
    }

    // MARK: - Binary Button

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
        // Engineering Principles §6.1: label + hint + value required.
        .accessibilityLabel("Check in \(board.name)")
        .accessibilityHint(
            isCompletedToday
                ? "Already completed today"
                : "Logs today's entry for \(board.name)"
        )
        .accessibilityValue(isCompletedToday ? "Completed" : "Not yet logged")
        .accessibilityAddTraits(isCompletedToday ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Check-In Action (Binary)

    // MARK: Check-In Sequence
    //
    // Order is deliberate:
    //   1. insert(entry)        — relationship established in-memory
    //   2. updateStreak(using:) — reads self.logs (includes new entry via in-memory
    //                             relationship update) and mutates cached streak
    //   3. save()               — persists both the new entry and streak mutation
    //   4. haptic               — fires at the moment of confirmed persistence,
    //                             not at animation completion (EP §7.2)
    //   5. scheduleReload()     — debounced widget invalidation
    //
    // On save failure: `modelContext.rollback()` discards both the inserted
    // entry and the streak mutation atomically. This is safe here because
    // check-in is the only mutation in flight from this button — no other
    // pending changes exist on this context at this call site.

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
            // Roll back both the inserted entry and the streak mutation.
            // `rollback()` is safe here: check-in is the only mutation in
            // flight at this call site.
            modelContext.rollback()
            showSaveError = true
        }
    }

    // MARK: - Haptics

    // MARK: UIKit Import Boundary (Engineering Principles §1.1)
    //
    // UIKit is imported only at API-level call sites. `UIImpactFeedbackGenerator`
    // is one of two permitted UIKit entry points (the other being
    // `UIApplication.shared.open`). All UIKit usage is gated on
    // `#if canImport(UIKit)` for macOS compatibility.

    private func triggerConfirmationHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}

// MARK: - CheckInButtonStyle

/// A custom `ButtonStyle` that applies the canonical check-in press animation
/// and adapts its visual appearance based on completion state.
///
/// Visual states:
/// - **Normal**: board-color filled pill, white label.
/// - **Completed**: board-color tinted (15% opacity) pill, board-color label.
///   Combined with `.disabled(true)` on the button — the completed visual
///   conveys state without a grey "disabled" appearance.
///
/// Animation: `Animation.rippleConfirm` (response 0.3, dampingFraction 0.5)
/// with scale `0.94` on press, per Engineering Principles §7 and §7.2.
/// Falls back to `.linear(duration: 0.1)` when `accessibilityReduceMotion`
/// is enabled.
private struct CheckInButtonStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isCompleted: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isCompleted ? tint : .white)
            .frame(maxWidth: .infinity)
            // .vertical: 16 pt → total height ~50 pt, well above 44 pt minimum
            // tap target (Engineering Principles §6.1).
            .padding(.vertical, 16)
            .background(
                isCompleted ? tint.opacity(0.15) : tint,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(
                // Engineering Principles §6.3 + §7.1:
                // Reduce Motion → .linear(0.1); otherwise → .rippleConfirm.
                // Scale effect is not removed entirely (it conveys press feedback
                // even for reduce-motion users), only made imperceptibly quick.
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

    // Pre-insert a today entry so the button renders in the completed state
    let entry = LogEntry(value: 1.0, boardID: board.id, board: board)
    container.mainContext.insert(entry)
    try? container.mainContext.save()
    return (container, board)
}

#Preview("Not Yet Logged") {
    let (container, board) = makeBinaryCheckInContainer()
    return CheckInButton(board: board)
        .padding()
        .modelContainer(container)
}

#Preview("Done Today") {
    let (container, board) = makeBinaryCompletedContainer()
    return CheckInButton(board: board)
        .padding()
        .modelContainer(container)
}
