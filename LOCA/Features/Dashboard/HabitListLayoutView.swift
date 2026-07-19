//
//  HabitListLayoutView.swift
//  LOCA
//
//  Phase 14.4 — List layout for habit display.
//
//  Vertical stack organized by semantic state (Needs Action, In Progress,
//  Behind, Done). Same as original HabitListView behavior.
//

import SwiftUI
import SwiftData

struct HabitListLayoutView: View {
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

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

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // NEEDS ACTION ZONE
            if !needsActionBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("To Do")

                    VStack(spacing: DS.Space.md) {
                        ForEach(needsActionBoards, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                HabitListRow(
                                    board: item.board,
                                    state: item.state,
                                    onCheckBinary: { onCheckBinary(item.board) }
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
                                    onCheckBinary: {}
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // BEHIND ZONE
            if !behindBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Needs Attention")

                    VStack(spacing: DS.Space.md) {
                        ForEach(behindBoards, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                HabitListRow(
                                    board: item.board,
                                    state: item.state,
                                    onCheckBinary: { onCheckBinary(item.board) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // DONE ZONE
            if !doneBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Done Today")

                    VStack(spacing: DS.Space.md) {
                        ForEach(doneBoards, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                HabitListRow(
                                    board: item.board,
                                    state: item.state,
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
}
