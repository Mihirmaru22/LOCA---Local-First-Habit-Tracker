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

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var boards: [HabitBoard]

    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false

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
                habitsContent
            }
        }
        .navigationTitle("Today")
        .largeNavigationTitleDisplay()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            HabitFormView(mode: .create)
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

    private var needsActionBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .needsAction }
    }

    private var inProgressBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .inProgress }
    }

    private var behindBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .behind }
    }

    private var doneBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .done }
    }

    // MARK: - Content

    private var habitsContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // NEEDS ACTION ZONE (hero)
            if !needsActionBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Today")

                    VStack(spacing: DS.Space.md) {
                        ForEach(needsActionBoards, id: \.board.id) { item in
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
            if !inProgressBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("In Progress")

                    VStack(spacing: DS.Space.md) {
                        ForEach(inProgressBoards, id: \.board.id) { item in
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
            if !behindBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Needs Attention")

                    VStack(spacing: DS.Space.md) {
                        ForEach(behindBoards, id: \.board.id) { item in
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
            if !doneBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Done Today")

                    VStack(spacing: DS.Space.md) {
                        ForEach(doneBoards, id: \.board.id) { item in
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
        modelContext.insert(entry)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
        }
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
