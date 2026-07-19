//
//  HabitGridLayoutView.swift
//  LOCA
//
//  Phase 15 — Grid layout: 2-column habit cards with 8-week mini heatmap.
//

import SwiftUI
import SwiftData

struct HabitGridLayoutView: View {
    @Query var boards: [HabitBoard]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 18) {
                            ForEach(boards.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { board in
                                NavigationLink(destination: HabitDetailView(board: board)) {
                                    GridHabitCard(board: board)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                }

                // Top bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.18), in: Circle())
                    }

                    Spacer()

                    Text("Boards")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    NavigationLink(destination: HabitFormView(mode: .create)) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.18), in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
    }
}

// MARK: - Grid Habit Card

struct GridHabitCard: View {
    let board: HabitBoard
    private let cellSize: CGFloat = 13
    private let cellGap: CGFloat = 4
    private let cols = 8
    private let rows = 7

    private var todayLogged: Bool {
        guard let logs = board.logs else { return false }
        return logs.contains { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var todayValue: Double {
        guard let logs = board.logs else { return 0 }
        return logs
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 8) {
                if let emoji = board.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 17))
                }
                Text(board.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(15)

            // Mini heatmap (8 weeks × 7 days)
            VStack(alignment: .leading, spacing: cellGap) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    HStack(spacing: cellGap) {
                        ForEach(0..<8, id: \.self) { weekIndex in
                            GridHeatCell(
                                board: board,
                                dayIndex: dayIndex,
                                weekIndex: weekIndex,
                                cellSize: cellSize,
                                totalWeeks: 8
                            )
                        }
                    }
                }
            }
            .padding(12)

            Spacer(minLength: 0)

            // Check button
            Button(action: {}) {
                if todayLogged {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        if board.metric == .quantitative {
                            Text(String(format: "%.1f", todayValue))
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ColorPalette[board.colorIndex])
                    .cornerRadius(18)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ColorPalette[board.colorIndex].opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(white: 0.15))
                        .cornerRadius(18)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 18)
            .padding(.bottom, 13)
        }
        .frame(height: 248)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ColorPalette[board.colorIndex].opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ColorPalette[board.colorIndex].opacity(0.18), lineWidth: 0.5)
        )
    }
}

// MARK: - Grid Heatmap Cell

struct GridHeatCell: View {
    let board: HabitBoard
    let dayIndex: Int
    let weekIndex: Int
    let cellSize: CGFloat
    let totalWeeks: Int

    private var cellDate: Date? {
        let today = Calendar.current.startOfDay(for: .now)
        let weeksBack = totalWeeks - 1 - weekIndex
        let daysBack = weeksBack * 7 + dayIndex
        return Calendar.current.date(byAdding: .day, value: -daysBack, to: today)
    }

    private var isToday: Bool {
        guard let date = cellDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private var totalValue: Double {
        guard let date = cellDate else { return 0 }
        let dayStart = Calendar.current.startOfDay(for: date)
        guard let dayEnd = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) else {
            return 0
        }
        return (board.logs ?? [])
            .filter { $0.timestamp >= dayStart && $0.timestamp <= dayEnd }
            .reduce(0.0) { $0 + $1.value }
    }

    private var fillOpacity: Double {
        guard totalValue > 0 else { return 0 }
        let ratio = totalValue / board.effectiveTarget
        if ratio >= 1.0 { return 1.0 }
        if ratio >= 0.5 { return 0.55 }
        return 0.30
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.27, style: .continuous)
                .fill(
                    totalValue > 0
                        ? ColorPalette[board.colorIndex].opacity(fillOpacity)
                        : ColorPalette[board.colorIndex].opacity(0.15)
                )

            // Today ring
            if isToday {
                RoundedRectangle(cornerRadius: cellSize * 0.27, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.2)
            }
        }
        .frame(width: cellSize, height: cellSize)
    }
}

#Preview {
    HabitGridLayoutView()
}
