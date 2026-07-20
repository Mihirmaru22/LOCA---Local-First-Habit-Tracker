//
//  HabitListLayoutView.swift
//  LOCA
//
//  Phase 15.1 — List layout, adaptive to window width.
//
//  On narrow screens (iPhone): full-width cards with generous padding.
//  On wide screens (iPad / Mac): content capped at 700pt and centered.
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
        GeometryReader { geo in
            let isWide = geo.size.width >= 600
            let maxContentWidth: CGFloat = isWide ? 700 : geo.size.width
            let hPad: CGFloat = isWide ? 0 : DS.Space.lg

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {
                    zoneView(title: "To Do", boards: needsActionBoards, showCheckIn: true)
                    zoneView(title: "In Progress", boards: inProgressBoards, showCheckIn: false)
                    zoneView(title: "Needs Attention", boards: behindBoards, showCheckIn: true)
                    zoneView(title: "Done Today", boards: doneBoards, showCheckIn: false)
                    Spacer(minLength: DS.Space.xxxl)
                }
                .frame(maxWidth: maxContentWidth)
                .padding(.horizontal, hPad)
                .padding(.vertical, DS.Space.xl)
                .frame(maxWidth: .infinity)   // center in wide window
            }
        }
    }

    @ViewBuilder
    private func zoneView(
        title: String,
        boards: [(board: HabitBoard, state: HabitState)],
        showCheckIn: Bool
    ) -> some View {
        if !boards.isEmpty {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                SectionHeader(title)
                VStack(spacing: DS.Space.md) {
                    ForEach(boards, id: \.board.id) { item in
                        NavigationLink(destination: HabitDetailView(board: item.board)) {
                            HabitListRow(
                                board: item.board,
                                state: item.state,
                                onCheckBinary: showCheckIn ? { onCheckBinary(item.board) } : {}
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
