//
//  HealthKitManager+Body.swift
//  LOCA
//
//  V2.5B.5 — Optional HealthKit body-data sync for UserProfileView.
//  Isolated from the existing HealthKitManager signal pipeline — does not
//  touch HealthKitManager.readTypes or SignalCollectionCoordinator.
//  Requests its own authorization for body types only, so the feature
//  degrades silently if HealthKit is unavailable or access is denied.
//
//  HealthKit is iOS-only; the macOS build uses a no-op stub.
//

import Foundation

// MARK: - BodyDataFetcher

@MainActor
struct BodyDataFetcher {

    struct BodySnapshot {
        let weightKg: Double?
        let heightCm: Double?
    }

    static func fetchLatest() async -> BodySnapshot {
        #if os(iOS)
        return await _fetchLatestHealthKit()
        #else
        return BodySnapshot(weightKg: nil, heightCm: nil)
        #endif
    }
}

// MARK: - iOS implementation

#if os(iOS)
import HealthKit

@MainActor
private extension BodyDataFetcher {

    static func _fetchLatestHealthKit() async -> BodySnapshot {
        guard HKHealthStore.isHealthDataAvailable() else {
            return BodySnapshot(weightKg: nil, heightCm: nil)
        }

        guard let massType   = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            return BodySnapshot(weightKg: nil, heightCm: nil)
        }

        let store = HKHealthStore()

        // Request read-only authorization for body types.
        // HealthKit's privacy model: denied types return empty samples, not errors.
        let authorized: Bool = await withCheckedContinuation { cont in
            store.requestAuthorization(toShare: [], read: [massType, heightType]) { success, _ in
                cont.resume(returning: success)
            }
        }
        guard authorized else { return BodySnapshot(weightKg: nil, heightCm: nil) }

        async let weightKg = latestQuantity(store: store, type: massType) { sample in
            sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
        }

        async let heightCm = latestQuantity(store: store, type: heightType) { sample in
            sample.quantity.doubleValue(for: .meter()) * 100.0
        }

        return await BodySnapshot(weightKg: weightKg, heightCm: heightCm)
    }

    static func latestQuantity(
        store: HKHealthStore,
        type: HKQuantityType,
        extract: @Sendable @escaping (HKQuantitySample) -> Double
    ) async -> Double? {
        await withCheckedContinuation { cont in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { @Sendable _, samples, _ in
                let value = (samples as? [HKQuantitySample])?.first.map(extract)
                cont.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
#endif
