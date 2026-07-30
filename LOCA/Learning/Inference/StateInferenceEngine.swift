//
//  StateInferenceEngine.swift
//  LOCA
//
//  Phase 3 — State inference engine
//  Infers energy, stress, focus, mood from signals hourly
//

import Foundation
import SwiftData

// The InferredState @Model lives in InferredStateModel.swift so it can be
// registered in RippleSchemaV1 from targets that don't build this engine.

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

            // Idempotent recompute: this method rebuilds the past day's hourly
            // states from scratch every run, so clear any states already stored in
            // the window first. Without this, running on a collection cadence would
            // insert duplicate InferredStates for the same hours indefinitely.
            let staleStatesDescriptor = FetchDescriptor<InferredState>(
                predicate: #Predicate { state in
                    state.timestamp >= yesterday && state.timestamp <= now
                }
            )
            if let staleStates = try? ctx.fetch(staleStatesDescriptor) {
                for state in staleStates {
                    ctx.delete(state)
                }
            }

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
                inferred.energyAbsent = energyResult.isAbsent
                inferred.stressAbsent = stressResult.isAbsent
                inferred.focusAbsent = focusResult.isAbsent
                inferred.moodAbsent = moodResult.isAbsent
                inferred.energyProvenanceJSON = energyResult.provenanceJSON
                inferred.stressProvenanceJSON = stressResult.provenanceJSON
                inferred.focusProvenanceJSON = focusResult.provenanceJSON
                inferred.moodProvenanceJSON = moodResult.provenanceJSON
                inferred.energyUncertaintyTypeRaw = energyResult.provenance.uncertaintyType.rawValue
                inferred.stressUncertaintyTypeRaw = stressResult.provenance.uncertaintyType.rawValue
                inferred.focusUncertaintyTypeRaw = focusResult.provenance.uncertaintyType.rawValue
                inferred.moodUncertaintyTypeRaw = moodResult.provenance.uncertaintyType.rawValue

                ctx.insert(inferred)
                recordConflictsIfNeeded(state: inferred, signals: hourSignals, modelContext: ctx)
            }

            try ctx.save()

            // Calibrate if user has provided ground truth
            await calibrationManager.calibrateModels(modelContext: ctx)

            // Mark consumed calibrations as processed
            try calibrationManager.markCalibrationAsProcessed(modelContext: ctx)

            lastInferenceTime = Date()
            inferenceError = nil

        } catch {
            inferenceError = error.localizedDescription
        }
    }

    // MARK: - C2.2 Conflict Detection

    /// Records a SensorConflict when a user self-report disagrees with the sensor-derived
    /// value by ≥ threshold. The sensor value is never changed — conflicts are evidence.
    private func recordConflictsIfNeeded(
        state: InferredState,
        signals: [SignalEvent],
        modelContext: ModelContext
    ) {
        let threshold = 0.20
        let explicitLogs = signals.filter { $0.source == .explicitLog }
        guard !explicitLogs.isEmpty else { return }

        let pairs: [(dimension: String, sensorValue: Double, isAbsent: Bool)] = [
            ("energy", state.energy, state.energyAbsent),
            ("stress", state.stress, state.stressAbsent),
            ("focus",  state.focus,  state.focusAbsent),
            ("mood",   state.mood,   state.moodAbsent),
        ]

        for (dimension, sensorValue, isAbsent) in pairs {
            guard !isAbsent else { continue }
            for log in explicitLogs {
                guard let rawValue = log.metadata[dimension],
                      let userValue = Double(rawValue) else { continue }
                let magnitude = abs(sensorValue - userValue)
                guard magnitude >= threshold else { continue }
                let conflict = SensorConflict(
                    timestamp: state.timestamp,
                    dimension: dimension,
                    sensorValue: sensorValue,
                    userValue: userValue
                )
                modelContext.insert(conflict)
                break
            }
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

// InferenceProvenance and InferenceResult are defined in InferenceTypes.swift
// so they are available to both the main app and LOCAWidgetExtension targets.
