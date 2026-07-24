//
//  StateInferenceEngine.swift
//  LOCA
//
//  Phase 3 — State inference engine
//  Infers energy, stress, focus, mood from signals hourly
//

import Foundation
import SwiftData

// MARK: - Inferred State (Output)

@Model
final class InferredState {
    var id: UUID = UUID()
    var timestamp: Date
    var hourStart: Date

    var energy: Double  // 0–1
    var energyUncertainty: Double

    var stress: Double  // 0–1
    var stressUncertainty: Double

    var focus: Double  // 0–1
    var focusUncertainty: Double

    var mood: Double  // 0–1
    var moodUncertainty: Double

    var isCalibrated: Bool = false
    var calibrationError: Double?

    init(
        timestamp: Date,
        energy: Double,
        energyUncertainty: Double,
        stress: Double,
        stressUncertainty: Double,
        focus: Double,
        focusUncertainty: Double,
        mood: Double,
        moodUncertainty: Double
    ) {
        self.timestamp = timestamp
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: timestamp)
        self.hourStart = Calendar.current.date(from: comps) ?? timestamp
        self.energy = Self.clamp(energy)
        self.energyUncertainty = Self.clamp(energyUncertainty)
        self.stress = Self.clamp(stress)
        self.stressUncertainty = Self.clamp(stressUncertainty)
        self.focus = Self.clamp(focus)
        self.focusUncertainty = Self.clamp(focusUncertainty)
        self.mood = Self.clamp(mood)
        self.moodUncertainty = Self.clamp(moodUncertainty)
    }

    private static func clamp(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}

// MARK: - State Inference Engine

@MainActor
class StateInferenceEngine: NSObject, ObservableObject {
    static let shared = StateInferenceEngine()

    @Published var lastInferenceTime: Date?
    @Published var inferenceError: String?

    private let energyModel = EnergyInferenceModel()
    private let stressModel = StressInferenceModel()
    private let focusModel = FocusInferenceModel()
    private let moodModel = MoodInferenceModel()
    private let calibrationManager = CalibrationManager()

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        calibrationManager.setModelContext(context)
    }

    // MARK: - Main Inference Loop

    func inferStatesForPastDay(modelContext: ModelContext) async {
        let ctx = self.modelContext ?? modelContext

        do {
            let calendar = Calendar.current
            let now = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!

            // Fetch all signals from yesterday
            let descriptor = FetchDescriptor<SignalEvent>(
                predicate: #Predicate { event in
                    event.timestamp >= yesterday && event.timestamp <= now
                }
            )

            guard let signals = try? ctx.fetch(descriptor) else { return }

            // Group signals by hour
            let hourlySignals = groupSignalsByHour(signals)

            // Infer states for each hour
            for (hourStart, hourSignals) in hourlySignals.sorted(by: { $0.key < $1.key }) {
                let aggregates = aggregateSignals(hourSignals)

                let energyResult = energyModel.infer(
                    signals: hourSignals,
                    aggregates: aggregates,
                    timestamp: hourStart
                )

                let stressResult = stressModel.infer(
                    signals: hourSignals,
                    aggregates: aggregates,
                    timestamp: hourStart
                )

                let focusResult = focusModel.infer(
                    signals: hourSignals,
                    aggregates: aggregates,
                    timestamp: hourStart
                )

                let moodResult = moodModel.infer(
                    signals: hourSignals,
                    aggregates: aggregates,
                    timestamp: hourStart
                )

                let inferred = InferredState(
                    timestamp: hourStart,
                    energy: energyResult.value,
                    energyUncertainty: energyResult.uncertainty,
                    stress: stressResult.value,
                    stressUncertainty: stressResult.uncertainty,
                    focus: focusResult.value,
                    focusUncertainty: focusResult.uncertainty,
                    mood: moodResult.value,
                    moodUncertainty: moodResult.uncertainty
                )

                ctx.insert(inferred)
            }

            try ctx.save()

            // Calibrate if user has provided ground truth
            await calibrationManager.calibrateModels(modelContext: ctx)

            lastInferenceTime = Date()
            inferenceError = nil

        } catch {
            inferenceError = error.localizedDescription
        }
    }

    // MARK: - Signal Aggregation

    private func groupSignalsByHour(_ signals: [SignalEvent]) -> [Date: [SignalEvent]] {
        let calendar = Calendar.current
        var grouped: [Date: [SignalEvent]] = [:]

        for signal in signals {
            let hourStart = calendar.dateComponents([.year, .month, .day, .hour], from: signal.timestamp)
            let hourStartDate = calendar.date(from: hourStart)!

            if grouped[hourStartDate] == nil {
                grouped[hourStartDate] = []
            }
            grouped[hourStartDate]?.append(signal)
        }

        return grouped
    }

    private func aggregateSignals(_ signals: [SignalEvent]) -> [SignalSource: AggregatedValue] {
        var aggregates: [SignalSource: AggregatedValue] = [:]

        let sourceGroups = Dictionary(grouping: signals) { $0.source }

        for (source, sourceSignals) in sourceGroups {
            let values = sourceSignals.map { $0.value }
            let uncertainties = sourceSignals.map { $0.uncertainty }

            let mean = values.reduce(0, +) / Double(values.count)
            let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
            let stddev = sqrt(variance)

            let propagatedUncertainty = sqrt(
                uncertainties.map { pow($0, 2) }.reduce(0, +)
            ) / Double(uncertainties.count)

            aggregates[source] = AggregatedValue(
                mean: mean,
                max: values.max() ?? 0,
                min: values.min() ?? 0,
                stddev: stddev,
                uncertainty: propagatedUncertainty,
                sampleCount: sourceSignals.count
            )
        }

        return aggregates
    }
}

// MARK: - Inference Result

struct InferenceResult {
    let value: Double  // 0–1
    let uncertainty: Double  // 0–1
}
