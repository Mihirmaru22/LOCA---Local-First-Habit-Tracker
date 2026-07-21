//
//  HabitGridLayoutView.swift
//  LOCA
//
//  Phase 14.4 — Grid layout with interactive check button and wave animation.
//
//  2-column grid. Each card: emoji + name (top), 14-day heatmap (middle),
//  check button with streak (bottom). Tap button triggers wave animation on heatmap.
//

import SwiftUI
import SwiftData

struct HabitGridLayoutView: View {
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: DS.Space.md),
        GridItem(.flexible(), spacing: DS.Space.md)
    ]

    private var sortedBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.sorted { a, b in
            let stateOrder: [HabitState] = [.needsAction, .behind, .inProgress, .done]
            let aIndex = stateOrder.firstIndex(of: a.state) ?? 4
            let bIndex = stateOrder.firstIndex(of: b.state) ?? 4
            return aIndex < bIndex
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Space.md) {
            ForEach(sortedBoards, id: \.board.id) { item in
                NavigationLink(destination: HabitDetailView(board: item.board)) {
                    HabitGridCardWithHeatmap(
                        board: item.board,
                        state: item.state,
                        onCheckBinary: { onCheckBinary(item.board) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.lg)
    }
}

// MARK: - Grid Card with Interactive Heatmap

struct HabitGridCardWithHeatmap: View {
    let board: HabitBoard
    let state: HabitState
    let onCheckBinary: () -> Void

    @State private var waveIndices: Set<Int> = []

    private var currentStreakValue: Int {
        board.currentStreak
    }

    private var cardBackgroundColor: Color {
        ColorPalette[board.colorIndex].opacity(0.12)
    }

    private var buttonBackgroundColor: Color {
        ColorPalette[board.colorIndex].opacity(0.2)
    }

    private var heatmapDays: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        let dayCount = 14
        return (0..<dayCount)
            .compactMap { offset in
                Calendar.current.date(byAdding: .day, value: -(dayCount - 1 - offset), to: today)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            // Header: emoji + name
            HStack(spacing: DS.Space.sm) {
                Text(board.emoji ?? "✓")
                    .font(.system(size: 24))
                
                Text(board.name)
                    .font(DS.Text.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
            }

            // Interactive heatmap grid (2 rows × 7 days)
            VStack(spacing: 2) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            if index < heatmapDays.count {
                                let date = heatmapDays[index]
                                MiniHeatmapCellWithWave(
                                    board: board,
                                    date: date,
                                    isAnimating: waveIndices.contains(index)
                                )
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DS.Space.sm)

            Spacer(minLength: 0)

            // Check button with streak count
            Button(action: { triggerWaveAnimation() }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("×")
                        .font(.system(size: 14, weight: .semibold))
                    
                    ValueText(
                        String(currentStreakValue),
                        font: DS.Text.valueCompact
                    )
                    
                    Spacer()
                }
                .foregroundStyle(ColorPalette[board.colorIndex])
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.md)
                .padding(.horizontal, DS.Space.md)
                .background(buttonBackgroundColor, in: RoundedRectangle(cornerRadius: 12))
            }
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    onCheckBinary()
                }
            )
        }
        .padding(DS.Space.md)
        .background(cardBackgroundColor, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(ColorPalette[board.colorIndex].opacity(0.25), lineWidth: 0.5)
        )
    }

    private func triggerWaveAnimation() {
        for index in 0..<14 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                withAnimation(.easeOut(duration: 0.4)) {
                    waveIndices.insert(index)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08 + 0.4) {
                withAnimation {
                    waveIndices.remove(index)
                }
            }
        }
    }
}

// MARK: - Mini Heatmap Cell with Wave Animation

struct MiniHeatmapCellWithWave: View {
    let board: HabitBoard
    let date: Date
    let isAnimating: Bool

    private var dayLogs: [LogEntry] {
        (board.logs ?? [])
            .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }

    private var totalValue: Double {
        dayLogs.reduce(0.0) { $0 + $1.value }
    }

    private var cellOpacity: Double {
        guard !dayLogs.isEmpty else { return 0 }
        let ratio = totalValue / board.effectiveTarget
        return min(1.0, max(0.3, ratio))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    dayLogs.isEmpty
                        ? DS.Color.surface
                        : ColorPalette[board.colorIndex].opacity(cellOpacity)
                )
            
            // Wave overlay
            if isAnimating {
                RoundedRectangle(cornerRadius: 2)
                    .fill(ColorPalette[board.colorIndex])
                    .opacity(0.6)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
}
