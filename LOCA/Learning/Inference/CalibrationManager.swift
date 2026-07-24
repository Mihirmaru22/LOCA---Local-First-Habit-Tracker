//
//  CalibrationManager.swift
//  LOCA
//
//  Calibration manager
//  Personalizes inference models based on user feedback (logged values)
//

import Foundation
import SwiftData

@MainActor
class CalibrationManager {
    private let energyModel = EnergyInferenceModel()
    private let stressModel = StressInferenceModel()
    private let focusModel = FocusInferenceModel()
    private let moodModel = MoodInferenceModel()

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Weekly Calibration Loop

    func calibrateModels(modelContext: ModelContext) async {
        guard let ctx = modelContext as? ModelContext? ?? self.modelContext else { return }

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        // Fetch logged user check-ins with ground truth
        let descriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { event in
                event.source == .explicitLog &&
                event.timestamp >= sevenDaysAgo && event.timestamp <= now
            }
        )

        guard let logs = try? ctx.fetch(descriptor), !logs.isEmpty else { return }

        // Fetch inferred states for same period
        let statesDescriptor = FetchDescriptor<InferredState>(
            predicate: #Predicate { state in
                state.timestamp >= sevenDaysAgo && state.timestamp <= now
            }
        )

        guard let states = try? ctx.fetch(statesDescriptor), !states.isEmpty else { return }

        // Compute errors per state
        calibrateEnergy(logs: logs, states: states)
        calibrateStress(logs: logs, states: states)
        calibrateFocus(logs: logs, states: states)
        calibrateMood(logs: logs, states: states)
    }

    // MARK: - Energy Calibration

    private func calibrateEnergy(logs: [SignalEvent], states: [InferredState]) {
        var errors: [Double] = []
        var predictions: [Double] = []

        for log in logs where log.metadata["energy"] != nil {
            guard let logged = Double(log.metadata["energy"] ?? "") else { continue }

            if let state = states.first(where: { $0.hourStart == log.timestamp }) {
                let error = abs(state.energy - logged)
                errors.append(error)
                predictions.append(state.energy)

                if error > 0.5 {
                    print("Energy calibration: predicted \(state.energy), logged \(logged), error \(error)")
                }
            }
        }

        guard !errors.isEmpty else { return }

        let meanError = errors.reduce(0, +) / Double(errors.count)
        let meanPrediction = predictions.reduce(0, +) / Double(predictions.count)

        if meanError > 0.3 {
            // Model is systematically wrong; adjust weights
            let meanLogged = logs.compactMap { Double($0.metadata["energy"] ?? "") }
                .reduce(0, +) / Double(logs.count)

            let bias = meanLogged - meanPrediction

            if bias > 0.1 {
                energyModel.updateWeights(
                    sleepWeight: 0.5,
                    timeOfDayWeight: 0.15,
                    stepsWeight: 0.15,
                    hrvWeight: 0.1,
                    loggedWeight: 0.1
                )
            }
        }
    }

    // MARK: - Stress Calibration

    private func calibrateStress(logs: [SignalEvent], states: [InferredState]) {
        var errors: [Double] = []

        for log in logs where log.metadata["stress"] != nil {
            guard let logged = Double(log.metadata["stress"] ?? "") else { continue }

            if let state = states.first(where: { $0.hourStart == log.timestamp }) {
                let error = abs(state.stress - logged)
                errors.append(error)

                if error > 0.5 {
                    print("Stress calibration: predicted \(state.stress), logged \(logged), error \(error)")
                }
            }
        }

        guard !errors.isEmpty else { return }

        let meanError = errors.reduce(0, +) / Double(errors.count)

        if meanError > 0.3 {
            stressModel.updateWeights(
                hrvWeight: 0.3,
                eventDensityWeight: 0.2,
                locationChangeWeight: 0.15,
                sentimentWeight: 0.15,
                dayOfWeekWeight: 0.1,
                loggedWeight: 0.1
            )
        }
    }

    // MARK: - Focus Calibration

    private func calibrateFocus(logs: [SignalEvent], states: [InferredState]) {
        var errors: [Double] = []

        for log in logs where log.metadata["focus"] != nil {
            guard let logged = Double(log.metadata["focus"] ?? "") else { continue }

            if let state = states.first(where: { $0.hourStart == log.timestamp }) {
                let error = abs(state.focus - logged)
                errors.append(error)

                if error > 0.5 {
                    print("Focus calibration: predicted \(state.focus), logged \(logged), error \(error)")
                }
            }
        }

        guard !errors.isEmpty else { return }

        let meanError = errors.reduce(0, +) / Double(errors.count)

        if meanError > 0.3 {
            focusModel.updateWeights(
                appFocusWeight: 0.35,
                interruptionWeight: 0.25,
                consistencyWeight: 0.15,
                timeOfDayWeight: 0.15,
                energyWeight: 0.05,
                loggedWeight: 0.05
            )
        }
    }

    // MARK: - Mood Calibration

    private func calibrateMood(logs: [SignalEvent], states: [InferredState]) {
        var errors: [Double] = []

        for log in logs where log.metadata["mood"] != nil {
            guard let logged = Double(log.metadata["mood"] ?? "") else { continue }

            if let state = states.first(where: { $0.hourStart == log.timestamp }) {
                let error = abs(state.mood - logged)
                errors.append(error)

                if error > 0.5 {
                    print("Mood calibration: predicted \(state.mood), logged \(logged), error \(error)")
                }
            }
        }

        guard !errors.isEmpty else { return }

        let meanError = errors.reduce(0, +) / Double(errors.count)

        if meanError > 0.4 {
            moodModel.updateWeights(
                moodCheckinWeight: 0.3,
                sentimentWeight: 0.2,
                socialEngagementWeight: 0.2,
                varietyWeight: 0.15,
                sleepQualityWeight: 0.1,
                loggedWeight: 0.05
            )
        }
    }
}
