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

// MARK: - Inference Provenance (C1.2)

/// What produced an inferred value: which sources contributed, how many samples,
/// and over what time window. Carried on every .measured result so callers can
/// answer "where did this come from?" without a second query.
struct InferenceProvenance: Codable {
    let sources: [String]       // SignalSource.rawValue for each contributing source
    let sampleCount: Int        // total samples across all contributing sources
    let windowStart: Date
    let windowEnd: Date

    var contributingSourceSet: Set<SignalSource> {
        Set(sources.compactMap { SignalSource(rawValue: $0) })
    }

    static let zero = InferenceProvenance(
        sources: [],
        sampleCount: 0,
        windowStart: .distantPast,
        windowEnd: .distantPast
    )

    func jsonEncoded() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decode(from json: String) -> InferenceProvenance? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(InferenceProvenance.self, from: data)
    }
}

// MARK: - Inference Result

/// C1.1: Absence-carrying result type.
/// `.absent` = no evidence arrived (structurally distinct from measured-neutral).
/// `.measured` = at least one real signal or user log contributed, with provenance.
enum InferenceResult {
    case absent(uncertainty: Double)
    case measured(value: Double, uncertainty: Double, provenance: InferenceProvenance)

    /// 0.0 when absent; the inferred value otherwise.
    var value: Double {
        switch self {
        case .absent: return 0.0
        case .measured(let v, _, _): return v
        }
    }

    /// Full uncertainty for absent states (1.0); inferred uncertainty otherwise.
    var uncertainty: Double {
        switch self {
        case .absent(let u): return u
        case .measured(_, let u, _): return u
        }
    }

    var isAbsent: Bool {
        if case .absent = self { return true }
        return false
    }

    var provenance: InferenceProvenance {
        switch self {
        case .absent: return .zero
        case .measured(_, _, let p): return p
        }
    }

    var provenanceJSON: String? {
        provenance.jsonEncoded()
    }
}
