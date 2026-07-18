//
//  HabitListView.swift
//  LOCA
//
//  Phase 11.1 — Habit List: the list container.
//
//  Groups habits by semantic state (Needs Action, In Progress, Done, Behind).
//  Renders zones with distinct emphasis to communicate priority visually without
//  reordering. Stable position + visual hierarchy = decision speed without
//  sacrificing spatial memory.
//
//  Architecture: the list queries the model, computes state for each habit,
//  and renders zones. Future: a HabitSortStrategy seam will allow "manual" (today)
//  or "needsAttentionFirst" (later) without redesign — the row rendering doesn't
//  change, only the order passed to the zones.
//

import SwiftUI
import SwiftData

// MARK: - HabitListView

struct HabitListView: View {

    @Query(sort: [SortDescriptor(\.createdAt)], animation: .default)
    private var boards: [HabitBoard]

    @State private var showingCreateSheet = false

    /// Future: a HabitSortStrategy seam will allow pluggable sort modes.
    /// Today: manual (stable, user-defined) order. No reordering by state.
    private var displayBoards: [HabitBoard] {
        boards.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if displayBoards.isEmpty {
                    emptyStateView
                } else {
                    habitsContent
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                HabitFormView(mode: .create) { newID in
                    // Auto-select newly created habit
                    // (will wire to detail navigation in next phase)
                }
            }
        }
    }

    // MARK: - Content

    private var habitsContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // Compute states for all boards
            let boardsWithState = displayBoards.map { board -> (board: HabitBoard, state: HabitState) in
                let todaysTotal = (board.logs ?? [])
                    .filter { $0.timestamp.isToday() }
                    .reduce(0.0) { $0 + $1.value }
                let state = HabitState.compute(for: board, todaysTotal: todaysTotal)
                return (board, state)
            }

            // Group by state
            let needsAction = boardsWithState.filter { $0.state == .needsAction }
            let inProgress = boardsWithState.filter { $0.state == .inProgress }
            let behind = boardsWithState.filter { $0.state == .behind }
            let done = boardsWithState.filter { $0.state == .done }

            // NEEDS ACTION ZONE (hero)
            if !needsAction.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Today")

                    VStack(spacing: DS.Space.md) {
                        ForEach(needsAction, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                HabitListRow(
                                    board: item.board,
                                    state: item.state,
                                    onTap: {},  // Navigation via NavigationLink
                                    onCheckBinary: {
                                        checkInBinary(board: item.board)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // IN PROGRESS ZONE
            if !inProgress.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("In Progress")

                    VStack(spacing: DS.Space.md) {
                        ForEach(inProgress, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                HabitListRow(
                                    board: item.board,
                                    state: item.state,
                                    onTap: {},
                                    onCheckBinary: {}
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // BEHIND ZONE (subtle urgency)
            if !behind.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Needs Attention")

                    VStack(spacing: DS.Space.md) {
                        ForEach(behind, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                HabitListRow(
                                    board: item.board,
                                    state: item.state,
                                    onTap: {},
                                    onCheckBinary: {
                                        checkInBinary(board: item.board)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // DONE ZONE (receded)
            if !done.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Done Today")

                    VStack(spacing: DS.Space.md) {
                        ForEach(done, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                HabitListRow(
                                    board: item.board,
                                    state: item.state,
                                    onTap: {},
                                    onCheckBinary: {}
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            Spacer(minLength: DS.Space.xxxl)
        }
        .padding(.vertical, DS.Space.xl)
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
        let entry = LogEntry(value: 1.0, boardID: board.id, board: board)
        do {
            let context = ModelContext(ModelContext.self as! ModelContext.Type)
            context.insert(entry)
            try context.save()
        } catch {
            print("Failed to log check-in: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    let running = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "mi", colorIndex: 0)
    running.currentStreak = 5; running.longestStreak = 12
    container.mainContext.insert(running)
    container.mainContext.insert(LogEntry(value: 3.2, boardID: running.id, board: running))

    let meditate = HabitBoard(name: "Meditate", colorIndex: 5)
    meditate.currentStreak = 3; meditate.longestStreak = 3
    container.mainContext.insert(meditate)

    let read = HabitBoard(name: "Read", colorIndex: 2)
    read.currentStreak = 0; read.longestStreak = 8
    container.mainContext.insert(read)

    let stretch = HabitBoard(name: "Stretch", colorIndex: 3)
    stretch.currentStreak = 10; stretch.longestStreak = 10
    container.mainContext.insert(stretch)
    container.mainContext.insert(LogEntry(value: 1, boardID: stretch.id, board: stretch))

    try? container.mainContext.save()

    return HabitListView()
        .modelContainer(container)
}
