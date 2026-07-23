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

// MARK: - HabitListView

struct HabitListView: View {

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var boards: [HabitBoard]

    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false
    @State private var showCheckInError   = false
    @AppStorage("habitListLayout") private var layout: String = "list"

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
            }
        }
        .navigationTitle("Today")
        .largeNavigationTitleDisplay()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: DS.Space.md) {
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
        } catch {
            showCheckInError = true
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
