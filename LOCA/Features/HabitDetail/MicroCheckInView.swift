//
//  MicroCheckInView.swift
//  LOCA
//
//  V2.0C — 2-question contextual state log.
//  Always asks Energy; second question is habit-dimension-aware (stress/mood/focus).
//  Writes two SignalEvent records with source .explicitLog so CalibrationManager
//  (F4) can compare them to the colocated InferredState and tighten weights.
//

import SwiftUI
import SwiftData

struct MicroCheckInView: View {
    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var energyRating: Int? = nil
    @State private var dim2Rating: Int? = nil
    @State private var saved = false

    // MARK: - Derived

    private var accent: Color { ColorPalette[board.colorIndex] }

    private var dim2Key: String {
        let d = board.dimension ?? ""
        switch d {
        case "stress":  return "stress"
        case "mood":    return "mood"
        case "focus":   return "focus"
        default:        return "mood"
        }
    }

    private var dim2Label: String {
        switch dim2Key {
        case "stress":  return "Stress"
        case "focus":   return "Focus"
        default:        return "Mood"
        }
    }

    // Stress scale is inverted for display: 1 = "Calm" (low stress), 5 = "High"
    private var dim2LowLabel: String  { dim2Key == "stress" ? "Calm" : "Low" }
    private var dim2HighLabel: String { dim2Key == "stress" ? "High" : "High" }

    private var canSave: Bool { energyRating != nil && dim2Rating != nil && !saved }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            // Header
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("How are you right now?")
                    .font(DS.Text.heading)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("After logging \(board.name)")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            // Q1: Energy
            questionRow(
                label: "Energy",
                lowLabel: "Low",
                highLabel: "High",
                rating: $energyRating
            )

            // Q2: Dimension-aware
            questionRow(
                label: dim2Label,
                lowLabel: dim2LowLabel,
                highLabel: dim2HighLabel,
                rating: $dim2Rating
            )

            // Confirmation
            if saved {
                HStack(spacing: DS.Space.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Logged \u{2014} this helps LOCA learn.")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            Spacer(minLength: 0)

            // Save button
            Button(action: saveAndDismiss) {
                Text("Log state")
                    .font(DS.Text.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(.white)
                    .background(
                        canSave ? accent : DS.Color.surfaceRecessed,
                        in: RoundedRectangle(cornerRadius: DS.Radius.control)
                    )
            }
            .disabled(!canSave)
            .animation(.easeInOut(duration: 0.15), value: canSave)
        }
        .padding(DS.Space.lg)
        .padding(.top, DS.Space.sm)
    }

    // MARK: - Question Row

    private func questionRow(
        label: String,
        lowLabel: String,
        highLabel: String,
        rating: Binding<Int?>
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(label)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { n in
                    Button {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            rating.wrappedValue = n
                        }
                        Haptics.impact(.light)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(rating.wrappedValue == n ? accent : DS.Color.surfaceRecessed)
                            if let sel = rating.wrappedValue, sel > n {
                                Circle().fill(accent.opacity(0.18))
                            }
                            Text("\(n)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    rating.wrappedValue == n ? Color.white : DS.Color.textTertiary
                                )
                        }
                        .frame(width: 32, height: 32)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text(lowLabel)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
                Spacer()
                Text(highLabel)
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    // MARK: - Save

    private func saveAndDismiss() {
        guard let e = energyRating, let d = dim2Rating, !saved else { return }

        let energyVal = Double(e - 1) / 4.0   // 1→0.0, 3→0.5, 5→1.0
        let dim2Val   = Double(d - 1) / 4.0
        let now = Date()

        let energySignal = SignalEvent(
            timestamp: now,
            source: .explicitLog,
            value: energyVal,
            uncertainty: 0.02,
            metadata: [
                "energy":     String(format: "%.2f", energyVal),
                "source_ui":  "micro_checkin",
                "board_id":   board.id.uuidString
            ]
        )

        let dim2Signal = SignalEvent(
            timestamp: now,
            source: .explicitLog,
            value: dim2Val,
            uncertainty: 0.02,
            metadata: [
                dim2Key:      String(format: "%.2f", dim2Val),
                "source_ui":  "micro_checkin",
                "board_id":   board.id.uuidString
            ]
        )

        modelContext.insert(energySignal)
        modelContext.insert(dim2Signal)
        try? modelContext.save()

        Haptics.notify(.success)
        LifeModelNudge.afterCheckIn(modelContext: modelContext)

        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}
