//
//  HealthKitManager.swift
//  LOCA
//
//  HealthKit integration for sleep, HRV, steps
//

import Foundation
import HealthKit

@MainActor
class HealthKitManager: NSObject {
    private let healthStore = HKHealthStore()
    private var isAuthorized = false

    override init() {
        super.init()
        requestAuthorization()
    }

    // MARK: - Authorization

    private func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
            }
        }
    }

    // MARK: - Sleep Collection

    func collectSleep() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                var signals: [SignalEvent] = []
                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    let hoursSleep = duration / 3600
                    let sleepScore = min(1.0, hoursSleep / 8.0)

                    let signal = SignalEvent(
                        timestamp: sample.endDate,
                        source: .sleep,
                        value: sleepScore,
                        uncertainty: 0.1,
                        metadata: ["duration": "\(Int(hoursSleep))h"]
                    )
                    signals.append(signal)
                }
                continuation.resume(returning: signals)
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Heart Rate Variability Collection

    func collectHeartRateVariability() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                var signals: [SignalEvent] = []
                for sample in samples {
                    let hrv = sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                    let normalized = min(1.0, hrv / 150)

                    let signal = SignalEvent(
                        timestamp: sample.endDate,
                        source: .heartRateVariability,
                        value: normalized,
                        uncertainty: 0.15,
                        metadata: ["hrv_ms": String(format: "%.1f", hrv)]
                    )
                    signals.append(signal)
                }
                continuation.resume(returning: signals)
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Step Count Collection

    func collectSteps() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!

        var intervalComponents = DateComponents()
        intervalComponents.hour = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: HKQuery.predicateForSamples(
                    withStart: thirtyDaysAgo,
                    end: now,
                    options: .strictStartDate
                ),
                options: .cumulativeSum,
                anchorDate: thirtyDaysAgo,
                intervalComponents: intervalComponents
            )

            query.initialResultsHandler = { _, results, error in
                guard let results, error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                var signals: [SignalEvent] = []
                results.enumerateStatistics(from: thirtyDaysAgo, to: now) { statistics, _ in
                    let stepCount = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    let normalized = min(1.0, stepCount / 1000)

                    let signal = SignalEvent(
                        timestamp: statistics.startDate,
                        source: .motionActivity,
                        value: normalized,
                        uncertainty: 0.1,
                        metadata: ["steps": String(Int(stepCount))]
                    )
                    signals.append(signal)
                }
                continuation.resume(returning: signals)
            }

            self.healthStore.execute(query)
        }
    }
}
