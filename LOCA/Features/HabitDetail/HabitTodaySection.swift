//
//  HabitTodaySection.swift
//  LOCA
//
//  Phase X.4 — Quick-log section in habit detail header
//

import SwiftUI
import SwiftData

// MARK: - HabitTodaySection

struct HabitTodaySection: View {
    let board: HabitBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingCheckIn = false
    @State private var isLoggingQuick = false
    @State private var showSuccessBadge = false

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0, { $0 + $1.value })
    }

    private var todayLogged: Bool {
        (board.logs ?? []).contains { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var todaysEntries: [LogEntry] {
        ((board.logs ?? [])
            .filter { Calendar.current.isDateInToday($0.timestamp) })
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var progressFraction: Double {
        max(0.0, min(1.0, todaysTotal / board.effectiveTarget))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            // ── Header ──────────────────────────────────────────
            Text("Today")
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            // ── Progress & Status ────────────────────────────
            HStack(spacing: DS.Space.lg) {
                // Arc progress (binary or quantitative)
                ZStack {
                    ArcProgressView(
                        fraction: progressFraction,
                        color: ColorPalette[board.colorIndex],
                        size: 56
                    )

                    switch board.metric {
                    case .binary:
                        if todayLogged {
                            Image(systemName: "checkmark")
                                .font(.body.bold())
                                .foregroundStyle(ColorPalette[board.colorIndex])
                        }
                    case .quantitative:
                        Text(String(Int((progressFraction * 100).rounded())) + "%")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(ColorPalette[board.colorIndex])
                    }
                }
                .frame(width: 56, height: 56)

                // Status text + progress details
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    switch board.metric {
                    case .binary:
                        if todayLogged {
                            Text("Done Today")
                                .font(DS.Text.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(DS.Color.textPrimary)
                        } else {
                            Text("Check off daily")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    case .quantitative:
                        Text(String(format: todaysTotal.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", todaysTotal)
                             + " / " + String(format: "%.0f", board.effectiveTarget)
                             + (board.unitLabel.map { " \($0)" } ?? ""))
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                progressFraction >= 1 ? ColorPalette[board.colorIndex] : DS.Color.textSecondary
                            )

                        Text(progressFraction >= 1 ? "Goal met ✓" : "Keep going")
                            .font(DS.Text.caption)
                            .foregroundStyle(
                                progressFraction >= 1 ? ColorPalette[board.colorIndex] : DS.Color.textSecondary
                            )
                    }
                }

                Spacer()

                // Quick log button
                if board.metric == .binary {
                    Button(action: logBinaryQuick) {
                        if showSuccessBadge {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.white)
                                .frame(width: 44, height: 44)
                                .background(ColorPalette[board.colorIndex], in: Circle())
                        } else if isLoggingQuick {
                            ProgressView()
                                .tint(ColorPalette[board.colorIndex])
                                .frame(width: 44, height: 44)
                                .background(DS.Color.surfaceRecessed, in: Circle())
                        } else if todayLogged {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(ColorPalette[board.colorIndex])
                                .frame(width: 44, height: 44)
                                .background(DS.Color.surfaceRecessed, in: Circle())
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(ColorPalette[board.colorIndex])
                                .frame(width: 44, height: 44)
                                .background(DS.Color.surfaceRecessed, in: Circle())
                        }
                    }
                    .disabled(isLoggingQuick)
                } else {
                    Button(action: { showingCheckIn = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                            .frame(width: 44, height: 44)
                            .background(DS.Color.surfaceRecessed, in: Circle())
                    }
                }
            }

            // ── Today's Entries ──────────────────────────────
            if !todaysEntries.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("Entries")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    ForEach(todaysEntries, id: \.id) { entry in
                        HStack(spacing: DS.Space.md) {
                            // Time
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                                .frame(width: 50, alignment: .leading)

                            // Amount (if quantitative)
                            if board.metric == .quantitative {
                                Text(String(format: entry.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", entry.value)
                                     + (board.unitLabel.map { " \($0)" } ?? ""))
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textPrimary)
                                    .fontWeight(.semibold)
                            }

                            // Note indicator
                            if let note = entry.note, !note.isEmpty {
                                Image(systemName: "note.text")
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textTertiary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, DS.Space.md)
                        .padding(.vertical, DS.Space.sm)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .sheet(isPresented: $showingCheckIn) {
            CheckInEditorView(mode: .create, board: board)
                .presentationDetents([.medium, .large])
        }
    }

    private func logBinaryQuick() {
        isLoggingQuick = true
        Haptics.impact(.light)

        do {
            let isNowLogged = try CheckInWriter.toggleBinary(board: board, context: modelContext)
            if isNowLogged {
                Haptics.notify(.success)
                withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                    showSuccessBadge = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                        showSuccessBadge = false
                    }
                    isLoggingQuick = false
                }
            } else {
                withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                    isLoggingQuick = false
                }
            }
        } catch {
            isLoggingQuick = false
            Haptics.notify(.error)
        }
    }
}

// MARK: - Preview

#Preview("HabitTodaySection with Logged Entry") {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let habit = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
    let entry = LogEntry(value: 3.2, boardID: habit.id, board: habit)
    container.mainContext.insert(habit)
    container.mainContext.insert(entry)
    try? container.mainContext.save()
    return HabitTodaySection(board: habit)
        .padding(DS.Space.lg)
        .modelContainer(container)
}
