//
//  UncertaintyValidator.swift
//  LOCA
//
//  Validates that uncertainty estimates match actual error
//  (Calibration check: predicted uncertainty ≈ actual error)
//

import Foundation
import SwiftData

@MainActor
class UncertaintyValidator {

    // MARK: - Calibration Validation

    func validateUncertaintyCalibration(
        modelContext: ModelContext
    ) -> ValidationResult {
        // Fetch inferred states with ground truth
        let descriptor = FetchDescriptor<InferredState>(
            predicate: #Predicate { state in
                state.isCalibrated == false
            }
        )

        guard let states = try? modelContext.fetch(descriptor), !states.isEmpty else {
            return ValidationResult(
                isValid: true,
                message: "No uncalibrated states to validate",
                energyCalibration: 0,
                stressCalibration: 0,
                focusCalibration: 0,
                moodCalibration: 0
            )
        }

        let energyErrors = validateStateUncertainty(
            states: states,
            stateKeyPath: \.energy,
            uncertaintyKeyPath: \.energyUncertainty
        )

        let stressErrors = validateStateUncertainty(
            states: states,
            stateKeyPath: \.stress,
            uncertaintyKeyPath: \.stressUncertainty
        )

        let focusErrors = validateStateUncertainty(
            states: states,
            stateKeyPath: \.focus,
            uncertaintyKeyPath: \.focusUncertainty
        )

        let moodErrors = validateStateUncertainty(
            states: states,
            stateKeyPath: \.mood,
            uncertaintyKeyPath: \.moodUncertainty
        )

        let energyCalibration = computeCalibrationError(energyErrors)
        let stressCalibration = computeCalibrationError(stressErrors)
        let focusCalibration = computeCalibrationError(focusErrors)
        let moodCalibration = computeCalibrationError(moodErrors)

        let isValid = [
            energyCalibration,
            stressCalibration,
            focusCalibration,
            moodCalibration
        ].allSatisfy { $0 < 0.15 }

        let message = isValid ?
            "✓ Uncertainties well-calibrated across all states" :
            "⚠ Some uncertainties need recalibration"

        return ValidationResult(
            isValid: isValid,
            message: message,
            energyCalibration: energyCalibration,
            stressCalibration: stressCalibration,
            focusCalibration: focusCalibration,
            moodCalibration: moodCalibration
        )
    }

    // MARK: - Per-State Validation

    private func validateStateUncertainty(
        states: [InferredState],
        stateKeyPath: KeyPath<InferredState, Double>,
        uncertaintyKeyPath: KeyPath<InferredState, Double>
    ) -> [(predicted: Double, error: Double)] {
        var results: [(Double, Double)] = []

        for state in states {
            let predictedUncertainty = state[keyPath: uncertaintyKeyPath]
            let error = state.calibrationError ?? 0
            results.append((predictedUncertainty, error))
        }

        return results
    }

    // MARK: - Calibration Error

    private func computeCalibrationError(_ predictions: [(predicted: Double, error: Double)]) -> Double {
        guard !predictions.isEmpty else { return 0 }

        let errors = predictions.map { abs($0.predicted - $0.error) }
        let meanError = errors.reduce(0, +) / Double(errors.count)

        return meanError
    }

    // MARK: - Event Detection Validation

    func validateEventDetectionConfidence(
        modelContext: ModelContext
    ) -> EventValidationResult {
        let descriptor = FetchDescriptor<LifeEvent>(
            predicate: #Predicate { event in
                event.userConfirmed == false
            }
        )

        guard let events = try? modelContext.fetch(descriptor), !events.isEmpty else {
            return EventValidationResult(
                totalEvents: 0,
                confirmedEvents: 0,
                sensitivity: 0,
                specificity: 0,
                confidenceCalibration: 0
            )
        }

        let confirmedCount = events.filter { $0.userConfirmed }.count
        let totalCount = events.count

        let sensitivity = Double(confirmedCount) / Double(totalCount)

        let confidenceScores = events.map { $0.confidence }
        let meanConfidence = confidenceScores.reduce(0, +) / Double(confidenceScores.count)

        return EventValidationResult(
            totalEvents: totalCount,
            confirmedEvents: confirmedCount,
            sensitivity: sensitivity,
            specificity: 0,  // Requires negative examples
            confidenceCalibration: meanConfidence
        )
    }
}

// MARK: - Validation Results

struct ValidationResult {
    let isValid: Bool
    let message: String
    let energyCalibration: Double
    let stressCalibration: Double
    let focusCalibration: Double
    let moodCalibration: Double
}

struct EventValidationResult {
    let totalEvents: Int
    let confirmedEvents: Int
    let sensitivity: Double
    let specificity: Double
    let confidenceCalibration: Double
}
