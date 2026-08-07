//
//  HealthKitManager.swift
//  LOCA
//
//  C3.1 — Passive HealthKit ingestion
//  Collects sleep, HRV, heart rate, steps, workouts, and mindful minutes
//  as SignalEvents. Authorization is requested once, through the
//  HealthKitPermissionView framing flow, not eagerly from init().
//
//  HealthKit's privacy model: read authorization is never exposed to apps.
//  Denied types simply return no samples. Each collector therefore runs
//  unconditionally and returns [] when the user hasn't granted access —
//  graceful degradation without an isAuthorized guard.
//

import Foundation
import HealthKit

// MARK: - HKWorkoutActivityType name helper

private extension HKWorkoutActivityType {
    var commonName: String {
        switch self {
        case .running:                       return "Running"
        case .cycling:                       return "Cycling"
        case .walking:                       return "Walking"
        case .swimming:                      return "Swimming"
        case .yoga:                          return "Yoga"
        case .functionalStrengthTraining:    return "Strength"
        case .traditionalStrengthTraining:   return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .hiking:                        return "Hiking"
        case .dance:                         return "Dance"
        case .pilates:                       return "Pilates"
        default:                             return "Workout"
        }
    }
}

// MARK: - HealthKitManager

@MainActor
class HealthKitManager: NSObject {
    private let healthStore = HKHealthStore()

    // All types LOCA reads. Kept in sync with NSHealthShareUsageDescription
    // in Info.plist and SignalCollectionCoordinator.requestHealthKitPermission().
    static let readTypes: Set<HKObjectType> = Set([
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
        HKObjectType.categoryType(forIdentifier: .mindfulSession),
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
        HKObjectType.quantityType(forIdentifier: .heartRate),
        HKObjectType.quantityType(forIdentifier: .stepCount),
        HKObjectType.workoutType(),
    ].compactMap { $0 })

    // MARK: - Sleep Collection

    func collectSleep() async -> [SignalEvent] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo, end: Date(), options: .strictStartDate
        )

        // HealthKit callbacks run on a private background queue, not the MainActor.
        // @Sendable handlers extract only Sendable primitives; @Model construction
        // happens on the MainActor after the await.
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
                let extracted = samples.map { s in
                    (endDate: s.endDate,
                     hoursSleep: s.endDate.timeIntervalSince(s.startDate) / 3600)
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

    func collectHeartRateVariability() async -> [SignalEvent] {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return [] }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo, end: Date(), options: .strictStartDate
        )

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
                let extracted = samples.map { s in
                    (endDate: s.endDate,
                     hrv: s.quantity.doubleValue(for: HKUnit(from: "ms")))
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

    // MARK: - Heart Rate Collection

    /// Collects hourly-averaged heart rate. Normalize: bpm / 100 → [0, 1].
    /// Inference models receive the raw normalized value; they assign meaning
    /// (e.g. elevated HR correlating with stress) via their own weighting.
    func collectHeartRate() async -> [SignalEvent] {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return [] }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let now = Date()

        var intervalComponents = DateComponents()
        intervalComponents.hour = 1

        let buckets: [(startDate: Date, avgBPM: Double)] = await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: hrType,
                quantitySamplePredicate: HKQuery.predicateForSamples(
                    withStart: thirtyDaysAgo, end: now, options: .strictStartDate
                ),
                options: .discreteAverage,
                anchorDate: thirtyDaysAgo,
                intervalComponents: intervalComponents
            )

            query.initialResultsHandler = { @Sendable _, results, error in
                guard let results, error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                var extracted: [(startDate: Date, avgBPM: Double)] = []
                results.enumerateStatistics(from: thirtyDaysAgo, to: now) { statistics, _ in
                    if let qty = statistics.averageQuantity() {
                        let bpm = qty.doubleValue(for: HKUnit(from: "count/min"))
                        extracted.append((startDate: statistics.startDate, avgBPM: bpm))
                    }
                }
                continuation.resume(returning: extracted)
            }
            self.healthStore.execute(query)
        }

        return buckets.map { bucket in
            SignalEvent(
                timestamp: bucket.startDate,
                source: .heartRate,
                value: min(1.0, bucket.avgBPM / 100.0),
                uncertainty: 0.15,
                metadata: ["bpm": String(format: "%.0f", bucket.avgBPM)]
            )
        }
    }

    // MARK: - Step Count Collection

    func collectSteps() async -> [SignalEvent] {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return [] }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!

        var intervalComponents = DateComponents()
        intervalComponents.hour = 1

        let buckets: [(startDate: Date, stepCount: Double)] = await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: HKQuery.predicateForSamples(
                    withStart: thirtyDaysAgo, end: now, options: .strictStartDate
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
                source: .steps,
                value: min(1.0, bucket.stepCount / 1000),
                uncertainty: 0.1,
                metadata: ["steps": String(Int(bucket.stepCount))]
            )
        }
    }

    // MARK: - Workout Collection

    /// Collects workouts and maps each to a SignalEvent. Normalize: 60 min → 1.0.
    func collectWorkouts() async -> [SignalEvent] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo, end: Date(), options: .strictStartDate
        )

        let samples: [(endDate: Date, durationMinutes: Double, activityName: String)] =
            await withCheckedContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: HKObjectType.workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
                ) { @Sendable _, samples, error in
                    guard let workouts = samples as? [HKWorkout], error == nil else {
                        continuation.resume(returning: [])
                        return
                    }
                    let extracted = workouts.map { w in
                        (endDate: w.endDate,
                         durationMinutes: w.duration / 60.0,
                         activityName: w.workoutActivityType.commonName)
                    }
                    continuation.resume(returning: extracted)
                }
                self.healthStore.execute(query)
            }

        return samples.map { entry in
            SignalEvent(
                timestamp: entry.endDate,
                source: .workout,
                value: min(1.0, entry.durationMinutes / 60.0),
                uncertainty: 0.1,
                metadata: [
                    "activity": entry.activityName,
                    "duration_min": String(format: "%.0f", entry.durationMinutes),
                ]
            )
        }
    }

    // MARK: - Mindful Minutes Collection

    /// Collects mindfulness sessions. Normalize: 20 min → 1.0.
    func collectMindfulMinutes() async -> [SignalEvent] {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return [] }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo, end: Date(), options: .strictStartDate
        )

        let samples: [(endDate: Date, durationMinutes: Double)] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { @Sendable _, samples, error in
                guard let sessions = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let extracted = sessions.map { s in
                    (endDate: s.endDate,
                     durationMinutes: s.endDate.timeIntervalSince(s.startDate) / 60.0)
                }
                continuation.resume(returning: extracted)
            }
            self.healthStore.execute(query)
        }

        return samples.map { entry in
            SignalEvent(
                timestamp: entry.endDate,
                source: .mindfulSession,
                value: min(1.0, entry.durationMinutes / 20.0),
                uncertainty: 0.1,
                metadata: ["duration_min": String(format: "%.1f", entry.durationMinutes)]
            )
        }
    }
}
