//
//  FocusInferenceModel.swift
//  LOCA
//
//  Focus inference model
//  Infers cognitive availability from app focus, interruptions, consistency
//

import Foundation

class FocusInferenceModel {
    private var appFocusWeight: Double = 0.3
    private var interruptionWeight: Double = 0.2
    private var consistencyWeight: Double = 0.15
    private var timeOfDayWeight: Double = 0.15
    private var energyWeight: Double = 0.1
    private var loggedFocusWeight: Double = 0.1

    private var focusableTimeWindows: [Int: Double] = [:]

    init() {
        initializeFocusWindows()
    }

    // MARK: - Main Inference

    func infer(
        signals: [SignalEvent],
        aggregates: [SignalSource: AggregatedValue],
        timestamp: Date
    ) -> InferenceResult {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)

        var uncertaintyTerms: [Double] = []
        var focusComponents: [Double] = []
        var hasRealEvidence = false
        var contributingSources: [String] = []
        var totalSampleCount = 0

        // Component 1: App focus score (single-app dominance)
        let deviceSignals = signals.filter { $0.source == .deviceActivity }
        if let appFocusScore = calculateAppFocusScore(signals: signals) {
            focusComponents.append(appFocusScore * appFocusWeight)
            uncertaintyTerms.append(0.15 * appFocusWeight)
            hasRealEvidence = true
            contributingSources.append(SignalSource.deviceActivity.rawValue)
            totalSampleCount += deviceSignals.count
        } else {
            uncertaintyTerms.append(0.15 * appFocusWeight)
        }

        // Component 2: Interruption count (calendar events, context switches)
        let calendarSignals = signals.filter { $0.source == .calendar }
        let interruptionScore = calculateInterruptionScore(signals: signals)
        if interruptionScore > 0 {
            focusComponents.append((1.0 - interruptionScore) * interruptionWeight)
            uncertaintyTerms.append(0.2 * interruptionWeight)
            hasRealEvidence = true
            if !contributingSources.contains(SignalSource.calendar.rawValue) {
                contributingSources.append(SignalSource.calendar.rawValue)
                totalSampleCount += calendarSignals.count
            }
        } else {
            uncertaintyTerms.append(0.2 * interruptionWeight)
        }

        // Component 3: Screen time consistency (same app, no switching)
        if let consistencyScore = calculateConsistencyScore(signals: signals) {
            focusComponents.append(consistencyScore * consistencyWeight)
            uncertaintyTerms.append(0.25 * consistencyWeight)
            hasRealEvidence = true
            if !contributingSources.contains(SignalSource.deviceActivity.rawValue) {
                contributingSources.append(SignalSource.deviceActivity.rawValue)
                totalSampleCount += deviceSignals.count
            }
        } else {
            uncertaintyTerms.append(0.25 * consistencyWeight)
        }

        // Component 4: Explicit logged focus
        let explicitLogs = signals.filter { $0.source == .explicitLog }
        if let loggedSignal = explicitLogs.first {
            focusComponents.append(loggedSignal.value * loggedFocusWeight)
            uncertaintyTerms.append(loggedSignal.uncertainty * loggedFocusWeight)
            hasRealEvidence = true
            contributingSources.append(SignalSource.explicitLog.rawValue)
            totalSampleCount += explicitLogs.count
        } else {
            uncertaintyTerms.append(0.3 * loggedFocusWeight)
        }

        // C1.1: Time-of-day focus windows are a prior. Return absent when no real signals arrived.
        guard hasRealEvidence else {
            return .absent(uncertainty: 1.0)
        }

        // Time-of-day is valid context when real evidence exists.
        let timeScore = focusableTimeWindows[hour] ?? defaultFocusTime(hour: hour)
        focusComponents.append(timeScore * timeOfDayWeight)
        uncertaintyTerms.append(0.1 * timeOfDayWeight)

        let focus = focusComponents.reduce(0, +)
        let baseUncertainty = sqrt(
            uncertaintyTerms.map { pow($0, 2) }.reduce(0, +)
        )

        let windowStart = signals.map(\.timestamp).min() ?? timestamp
        let windowEnd   = signals.map(\.timestamp).max() ?? timestamp
        let provenance  = InferenceProvenance(
            sources: contributingSources,
            sampleCount: totalSampleCount,
            windowStart: windowStart,
            windowEnd: windowEnd
        )

        return .measured(
            value: min(1.0, max(0, focus)),
            uncertainty: min(1.0, baseUncertainty),
            provenance: provenance
        )
    }

    // MARK: - App Focus Score

    // C1.1: Returns nil when no device-activity signals — absence of data is not 0.5 focus.
    private func calculateAppFocusScore(signals: [SignalEvent]) -> Double? {
        let deviceSignals = signals.filter { $0.source == .deviceActivity }
        guard !deviceSignals.isEmpty else { return nil }

        var singleAppDominance = 0.0
        var appSwitches = 0

        for signal in deviceSignals {
            if signal.metadata["dominant_app"] != nil {
                if let screenTime = Double(signal.metadata["dominant_app_time"] ?? "0") {
                    let hourlySeconds = 3600.0
                    singleAppDominance = min(1.0, screenTime / hourlySeconds)
                }
            }
            if let switches = Int(signal.metadata["app_switches"] ?? "0") {
                appSwitches += switches
            }
        }

        let switchPenalty = Double(appSwitches) * 0.1
        let focusScore = singleAppDominance - switchPenalty

        return max(0, min(1.0, focusScore))
    }

    // MARK: - Interruption Score

    private func calculateInterruptionScore(signals: [SignalEvent]) -> Double {
        let calendarSignals = signals.filter { $0.source == .calendar }
        guard !calendarSignals.isEmpty else { return 0.0 }

        var interruptionCount = 0
        for signal in calendarSignals {
            if let count = Int(signal.metadata["event_count"] ?? "0") {
                interruptionCount += count
            }
        }

        let score = Double(interruptionCount) / 5.0  // 5 events/hour = high interruption
        return min(1.0, score)
    }

    // MARK: - Consistency Score

    // C1.1: Returns nil when fewer than 2 device signals — cannot measure switch rate.
    private func calculateConsistencyScore(signals: [SignalEvent]) -> Double? {
        let deviceSignals = signals.filter { $0.source == .deviceActivity }
        guard deviceSignals.count > 1 else { return nil }

        var previousApp: String?
        var switches = 0

        for signal in deviceSignals.sorted(by: { $0.timestamp < $1.timestamp }) {
            if let currentApp = signal.metadata["dominant_app"] {
                if let prev = previousApp, prev != currentApp {
                    switches += 1
                }
                previousApp = currentApp
            }
        }

        let switchRate = Double(switches) / Double(deviceSignals.count)
        return 1.0 - switchRate
    }

    // MARK: - Focus-Optimal Time Windows

    private func initializeFocusWindows() {
        for hour in 0..<24 {
            focusableTimeWindows[hour] = nil
        }
    }

    private func defaultFocusTime(hour: Int) -> Double {
        switch hour {
        case 0...6: return 0.0      // Night: not time for focus
        case 7...8: return 0.3      // Early morning: too early for deep work
        case 9...11: return 0.85    // Mid-morning: peak focus (first peak)
        case 12...13: return 0.4    // Lunch: interruption
        case 14...16: return 0.8    // Afternoon: second peak
        case 17...19: return 0.5    // Late afternoon: declining
        case 20...23: return 0.2    // Evening: low focus
        default: return 0.5
        }
    }

    // MARK: - Personalization

    func updateFocusWindow(hour: Int, observedFocus: Double) {
        focusableTimeWindows[hour] = observedFocus
    }

    func updateWeights(
        appFocusWeight: Double,
        interruptionWeight: Double,
        consistencyWeight: Double,
        timeOfDayWeight: Double,
        energyWeight: Double,
        loggedWeight: Double
    ) {
        let total = appFocusWeight + interruptionWeight + consistencyWeight + timeOfDayWeight + energyWeight + loggedWeight
        self.appFocusWeight = appFocusWeight / total
        self.interruptionWeight = interruptionWeight / total
        self.consistencyWeight = consistencyWeight / total
        self.timeOfDayWeight = timeOfDayWeight / total
        self.energyWeight = energyWeight / total
        self.loggedFocusWeight = loggedWeight / total
    }
}
