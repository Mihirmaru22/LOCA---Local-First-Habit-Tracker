//
//  HabitListView.swift
//  LOCA
//
//  Phase 14.4 — Habit List: the list container with layout switching.
//
//  Reads @AppStorage("habitListLayout") and renders one of three layouts:
//  - list: Zones by state (To Do, In Progress, Needs Attention, Done)
//  - grid: 2-column grid of compact cards
//  - timeline: Chronological timeline with expanded stats
//
//  State computation remains centralized outside ViewBuilder.
//

import SwiftUI
import SwiftData
import Foundation

#if canImport(UIKit)
import UIKit
#endif

extension Notification.Name {
    static let habitArchived = Notification.Name("habitArchived")
}

// MARK: - HabitListView

struct HabitListView: View {

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var boards: [HabitBoard]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingCreateSheet = false
    @State private var showCheckInError   = false
    @State private var showUndoToast = false
    @State private var lastDeletedHabit: HabitBoard? = nil
    @State private var showRecommendations = true
    @State private var recommendations: [HabitRecommendation] = []
    @State private var selectedRecommationTemplate: HabitTemplate?
    @AppStorage("habitListLayout") private var layout: String = "list"
    @State private var syncStatus: SyncStatusCoordinator.SyncStatus = .idle

    /// Future: a HabitSortStrategy seam will allow pluggable sort modes.
    /// Today: manual (stable, user-defined) order. No reordering by state.
    private var displayBoards: [HabitBoard] {
        boards.filter { $0.archivedAt == nil }
    }

    var body: some View {
        ScrollView {
            if displayBoards.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: DS.Space.lg) {
                    Group {
                        switch layout {
                        case "grid":
                            HabitGridLayoutView(
                                boardsWithState: boardsWithState,
                                onCheckBinary: checkInBinary
                            )
                        case "timeline":
                            HabitTimelineLayoutView(
                                boardsWithState: boardsWithState,
                                onCheckBinary: checkInBinary
                            )
                        default: // "list"
                            HabitListLayoutView(
                                boardsWithState: boardsWithState,
                                onCheckBinary: checkInBinary
                            )
                        }
                    }
                    .transition(.opacity)
                    .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: layout)

                    // Show recommendations if few habits exist (Phase 3.4)
                    if showRecommendations && !recommendations.isEmpty && displayBoards.count < 3 {
                        HabitRecommendationCard(
                            recommendations: recommendations,
                            onSelect: { template in
                                selectedRecommationTemplate = template
                                showingCreateSheet = true
                            },
                            onDismiss: { showRecommendations = false }
                        )
                        .padding(DS.Space.lg)
                    }
                }
            }
        }
        .navigationTitle("Today")
        .largeNavigationTitleDisplay()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: DS.Space.md) {
                    SyncStatusIndicatorView(syncStatus: syncStatus)
                    SettingsMenuView()
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            SimpleHabitCreationView()
        }
        .alert("Couldn't Save Check-in", isPresented: $showCheckInError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The check-in couldn't be saved. Please try again.")
        }
        .overlay(alignment: .bottom) {
            if showUndoToast, let habit = lastDeletedHabit {
                undoToast(habit: habit)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(DS.Space.lg)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .habitArchived)) { notif in
            if let habit = notif.object as? HabitBoard {
                lastDeletedHabit = habit
                withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                    showUndoToast = true
                }
            }
        }
        .task {
            // Listen for sync status changes (Phase 3.5). Iterating the actor's
            // AsyncStream in this MainActor .task lets us assign @State directly:
            // SyncStatus is Sendable, so nothing MainActor-isolated crosses into
            // the actor (Swift 6 complete concurrency).
            for await status in await SyncStatusCoordinator.shared.statusUpdates() {
                withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                    syncStatus = status
                }
            }
        }
        .task(id: boards.count) {
            // Generate recommendations based on existing habits (Phase 3.4)
            let allLogs = boards.flatMap { board in
                (board.logs ?? []).map { log in
                    LogSnapshot(from: log)
                }
            }
            recommendations = HabitRecommender.generateRecommendations(
                existingBoards: displayBoards,
                logs: allLogs,
                maxRecommendations: 3
            )
        }
    }

    private func undoToast(habit: HabitBoard) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Habit archived")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textPrimary)
            }

            Spacer()

            Button("Undo") { undoDelete(habit: habit) }
                .fontWeight(.semibold)
                .foregroundStyle(ColorPalette[habit.colorIndex])
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if showUndoToast { // Only auto-dismiss if user didn't undo
                    withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                        showUndoToast = false
                    }
                }
            }
        }
    }

    private func undoDelete(habit: HabitBoard) {
        habit.archivedAt = nil
        do {
            try modelContext.save()
            withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                showUndoToast = false
                lastDeletedHabit = nil
            }
        } catch {
            // Error handling - silent fail for now
        }
    }

    // MARK: - State computation (outside ViewBuilder)

    private var boardsWithState: [(board: HabitBoard, state: HabitState)] {
        displayBoards.map { board in
            let todaysTotal = (board.logs ?? [])
                .filter { $0.timestamp.isToday() }
                .reduce(0.0) { $0 + $1.value }
            let state = HabitState.compute(for: board, todaysTotal: todaysTotal)
            return (board, state)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DS.Space.lg) {
            Spacer()

            VStack(spacing: DS.Space.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                VStack(spacing: DS.Space.sm) {
                    Text("All Set")
                        .font(DS.Text.heading)

                    Text("No habits yet. Create one to get started.")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button(action: { showingCreateSheet = true }) {
                Text("Create Habit")
                    .font(DS.Text.body)
                    .frame(maxWidth: .infinity)
                    .padding(DS.Space.lg)
                    .background(ColorPalette[0])
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Space.xxl)
    }

    // MARK: - Actions

    private func checkInBinary(board: HabitBoard) {
        do {
            try CheckInWriter.toggleBinary(board: board, context: modelContext)
            triggerCheckInHaptic()
        } catch {
            showCheckInError = true
        }
    }

    private func triggerCheckInHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}

// MARK: - Preview

@MainActor
private func makeHabitListPreviewContainer() -> ModelContainer {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    // try! is acceptable in a #Preview fixture (Engineering Principles §Previews).
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    // In progress: quantitative, partway to goal.
    let running = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
    running.currentStreak = 5
    running.longestStreak = 12
    context.insert(running)
    context.insert(LogEntry(value: 3.2, boardID: running.id, board: running))

    // Needs action: binary, not yet logged today.
    let meditate = HabitBoard(name: "Meditate", colorIndex: 5)
    meditate.currentStreak = 3
    meditate.longestStreak = 3
    context.insert(meditate)

    // Behind: streak broken, has history, nothing today.
    let read = HabitBoard(name: "Read", colorIndex: 2)
    read.currentStreak = 0
    read.longestStreak = 8
    context.insert(read)
    if let yesterday = Calendar.current.date(byAdding: .day, value: -2, to: .now) {
        context.insert(LogEntry(timestamp: yesterday, value: 1, boardID: read.id, board: read))
    }

    // Done: binary, completed today.
    let stretch = HabitBoard(name: "Stretch", colorIndex: 3)
    stretch.currentStreak = 10
    stretch.longestStreak = 10
    context.insert(stretch)
    context.insert(LogEntry(value: 1, boardID: stretch.id, board: stretch))

    try? context.save()
    return container
}

#Preview {
    NavigationStack {
        HabitListView()
    }
    .modelContainer(makeHabitListPreviewContainer())
}
