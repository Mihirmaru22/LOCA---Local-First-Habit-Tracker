//
//  HabitListView.swift
//  LOCA
//
//  Phase 14.4 — Habit List: the list container with layout switching.
//

import SwiftUI
import SwiftData

struct HabitListView: View {

    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var boards: [HabitBoard]

    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false
    @AppStorage("habitListLayout") private var layout: String = "list"

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
                    default:
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
            HabitFormView(mode: .create)
        }
    }

    private var boardsWithState: [(board: HabitBoard, state: HabitState)] {
        displayBoards.map { board in
            let todaysTotal = (board.logs ?? [])
                .filter { $0.timestamp.isToday() }
                .reduce(0.0) { $0 + $1.value }
            let state = HabitState.compute(for: board, todaysTotal: todaysTotal)
            return (board, state)
        }
    }

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

    private func checkInBinary(board: HabitBoard) {
        let entry = LogEntry(value: 1.0, boardID: board.id, board: board)
        modelContext.insert(entry)
        board.updateStreak(using: .current)
        do {
            try modelContext.save()
            WidgetRefreshCoordinator.shared.scheduleReload()
        } catch {
            modelContext.rollback()
        }
    }
}

#Preview {
    NavigationStack {
        HabitListView()
    }
}
