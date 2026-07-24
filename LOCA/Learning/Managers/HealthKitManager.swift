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
        let typesToRead: Set<HKObjectType> = Set(
            [
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
                HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
                HKObjectType.quantityType(forIdentifier: .stepCount),
                HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            ].compactMap { $0 }
        )

        guard !typesToRead.isEmpty else { return }

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
            }
        }
    }

    // MARK: - Sleep Collection

    func collectSleep() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: Date(),
            options: .strictStartDate
        )

        // HealthKit runs its results handler on a private background queue, not the
        // MainActor. The @Sendable handler keeps it off-actor (avoiding a
        // dispatch_assert_queue crash) and extracts only Sendable primitives; the
        // SwiftData @Model objects are built afterward on the MainActor.
        let samples: [(endDate: Date, hoursSleep: Double)] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { @Sendable _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                let extracted = samples.map { sample in
                    (endDate: sample.endDate,
                     hoursSleep: sample.endDate.timeIntervalSince(sample.startDate) / 3600)
                }
                continuation.resume(returning: extracted)
            }

            self.healthStore.execute(query)
        }

        return samples.map { entry in
            SignalEvent(
                timestamp: entry.endDate,
                source: .sleep,
                value: min(1.0, entry.hoursSleep / 8.0),
                uncertainty: 0.1,
                metadata: ["duration": "\(Int(entry.hoursSleep))h"]
            )
        }
    }

    // MARK: - Heart Rate Variability Collection

    func collectHeartRateVariability() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return [] }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: Date(),
            options: .strictStartDate
        )

        // @Sendable handler: runs on HealthKit's background queue, extracts only
        // Sendable primitives; @Model construction happens on the MainActor below.
        let samples: [(endDate: Date, hrv: Double)] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { @Sendable _, samples, error in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                let extracted = samples.map { sample in
                    (endDate: sample.endDate,
                     hrv: sample.quantity.doubleValue(for: HKUnit(from: "ms")))
                }
                continuation.resume(returning: extracted)
            }

            self.healthStore.execute(query)
        }

        return samples.map { entry in
            SignalEvent(
                timestamp: entry.endDate,
                source: .heartRateVariability,
                value: min(1.0, entry.hrv / 150),
                uncertainty: 0.15,
                metadata: ["hrv_ms": String(format: "%.1f", entry.hrv)]
            )
        }
    }

    // MARK: - Step Count Collection

    func collectSteps() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return [] }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!

        var intervalComponents = DateComponents()
        intervalComponents.hour = 1

        // @Sendable handler: HKStatisticsCollectionQuery invokes its results handler
        // on a background queue. Extract Sendable (Date, stepCount) pairs here; build
        // the @Model objects on the MainActor after the await.
        let buckets: [(startDate: Date, stepCount: Double)] = await withCheckedContinuation { continuation in
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

            query.initialResultsHandler = { @Sendable _, results, error in
                guard let results, error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                var extracted: [(startDate: Date, stepCount: Double)] = []
                results.enumerateStatistics(from: thirtyDaysAgo, to: now) { statistics, _ in
                    let stepCount = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    extracted.append((startDate: statistics.startDate, stepCount: stepCount))
                }
                continuation.resume(returning: extracted)
            }

            self.healthStore.execute(query)
        }

        return buckets.map { bucket in
            SignalEvent(
                timestamp: bucket.startDate,
                source: .motionActivity,
                value: min(1.0, bucket.stepCount / 1000),
                uncertainty: 0.1,
                metadata: ["steps": String(Int(bucket.stepCount))]
            )
        }
    }
}
