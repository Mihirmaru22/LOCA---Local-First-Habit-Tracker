//
//  HabitCheckInsView.swift
//  LOCA
//
//  Phase 12.3 — Check-ins surface for habit details.
//
//  Shows today's progress and provides quick-logging interface for both
//  binary and quantitative habits. Binary habits show a toggle; quantitative
//  habits show an input field.
//

import SwiftUI
import SwiftData

struct HabitCheckInsView: View {

    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext

    @State private var inputValue: String = ""
    @State private var isSubmitting = false
    @State private var showingAddCheckIn = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var parsedValue: Double? {
        Double(inputValue.trimmingCharacters(in: .whitespaces))
    }

    private var isBinary: Bool {
        board.metric == .binary
    }

    private var isQuantitative: Bool {
        board.metric == .quantitative
    }

    /// Today's total
    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    /// Has today been marked complete (binary) or target reached (quantitative)?
    private var isCompleted: Bool {
        if isBinary {
            return todaysTotal > 0
        } else {
            let target = board.effectiveTarget
            return todaysTotal >= target
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {

                // MARK: - Today's Status
                LOCACard {
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        HStack {
                            Text("TODAY")
                                .font(DS.Text.footnote)
                                .foregroundStyle(DS.Color.textSecondary)
                                .tracking(0.5)
                            Spacer()
                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(ColorPalette[board.colorIndex])
                            }
                        }

                        if isQuantitative {
                            HStack(spacing: DS.Space.md) {
                                ValueText(
                                    todaysTotal.formatted(.number.precision(.fractionLength(0...1))),
                                    font: DS.Text.value
                                )
                                .foregroundStyle(DS.Color.textPrimary)

                                if let target = board.targetValue, target > 0 {
                                    Text("/ \(target.formatted(.number.precision(.fractionLength(0...1))))")
                                        .font(DS.Text.body)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }

                                if let unit = board.unitLabel, !unit.isEmpty {
                                    Text(unit)
                                        .font(DS.Text.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }

                                Spacer()
                            }
                        } else {
                            Text(isCompleted ? "Completed" : "Not completed")
                                .font(DS.Text.body)
                                .foregroundStyle(isCompleted ? ColorPalette[board.colorIndex] : DS.Color.textSecondary)
                        }
                    }
                }

                // MARK: - Quick Input
                if isQuantitative {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Log Amount")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)

                        HStack(spacing: DS.Space.md) {
                            TextField("0", text: $inputValue)
                                .font(DS.Text.body)
                                .decimalKeyboard()
                                .textFieldStyle(.roundedBorder)

                            if let unit = board.unitLabel, !unit.isEmpty {
                                Text(unit)
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .frame(minWidth: 50)
                            }

                            Button(action: { submitQuantitative() }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(ColorPalette[board.colorIndex])
                            }
                            .disabled((Double(inputValue) ?? 0) <= 0 || isSubmitting)
                        }
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                } else {
                    Button(action: { toggleBinary() }) {
                        HStack {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(isCompleted ? "Completed" : "Mark as Done")
                                .font(DS.Text.body)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DS.Space.md)
                        .background(isCompleted ? ColorPalette[board.colorIndex] : DS.Color.surface)
                        .foregroundStyle(isCompleted ? .white : DS.Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                }

                // Clearance for the floating SurfaceSelector pill.
                Spacer(minLength: DS.Space.xxxl + DS.Space.xl)
            }
            .padding(DS.Space.lg)
        }
        .sheet(isPresented: $showingAddCheckIn) {
            AddCheckInSheetView(board: board)
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingAddCheckIn = true }) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(ColorPalette[board.colorIndex])
                    .clipShape(Circle())
            }
            .padding(DS.Space.lg)
        }
    }

    // MARK: - Actions

    private func submitQuantitative() {
        guard let value = Double(inputValue), value > 0 else { return }

        isSubmitting = true
        let logEntry = LogEntry(value: value, boardID: board.id, board: board)
        modelContext.insert(logEntry)
        board.updateStreak(using: .current)

        do {
            try modelContext.save()
            triggerConfirmationHaptic()
            WidgetRefreshCoordinator.shared.scheduleReload()
            withAnimation(DS.Motion.confirm(reduceMotion: reduceMotion)) {
                inputValue = ""
                isSubmitting = false
            }
        } catch {
            modelContext.rollback()
            isSubmitting = false
        }
    }

    private func toggleBinary() {
        if isCompleted {
            // Remove today's entries
            for entry in (board.logs ?? []).filter({ $0.timestamp.isToday() }) {
                modelContext.delete(entry)
            }
        } else {
            let logEntry = LogEntry(value: 1, boardID: board.id, board: board)
            modelContext.insert(logEntry)
            board.updateStreak(using: .current)
        }

        do {
            try modelContext.save()
            triggerConfirmationHaptic()
            WidgetRefreshCoordinator.shared.scheduleReload()
        } catch {
            modelContext.rollback()
        }
    }

    // MARK: - Haptics

    /// Gated on UIKit availability — the macOS target has no
    /// UIImpactFeedbackGenerator (Engineering Rules §Platform shims).
    private func triggerConfirmationHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let habit = HabitBoard(name: "Morning Run", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
        container.mainContext.insert(habit)
        try? container.mainContext.save()
        return (container, habit)
    }

    let (container, habit) = makeContainer()
    return HabitCheckInsView(board: habit)
        .modelContainer(container)
}
