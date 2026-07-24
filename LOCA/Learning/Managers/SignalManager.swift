//
//  SignalManager.swift
//  LOCA
//
//  Signal ingestion coordinator
//  Manages all seven signal sources and aggregation
//

import Foundation
import SwiftData

// MARK: - Signal Manager

@MainActor
class SignalManager: NSObject, ObservableObject {
    static let shared = SignalManager()

    @Published var isCollecting = false
    @Published var lastUpdateTime: Date?
    @Published var collectionError: String?

    private let healthKitManager = HealthKitManager()
    private let calendarManager = CalendarManager()
    private let locationManager = LocationManager()
    private let deviceActivityManager = DeviceActivityManager()
    private let motionActivityManager = MotionActivityManager()

    private var backgroundTask: Task<Void, Never>?
    private var modelContext: ModelContext?

    override init() {
        super.init()
        setupBackgroundCollection()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Public API

    func startCollection() {
        guard !isCollecting else { return }
        isCollecting = true
        Task {
            await collectAllSignals()
        }
    }

    func stopCollection() {
        backgroundTask?.cancel()
        isCollecting = false
    }

    // MARK: - Daily Collection Loop

    private func setupBackgroundCollection() {
        backgroundTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 3600 * 1_000_000_000)
                    await collectAllSignals()
                } catch {
                    if !Task.isCancelled {
                        collectionError = "Background collection error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - Collection from All Sources

    private func collectAllSignals() async {
        guard let modelContext = modelContext else { return }

        do {
            let now = Date()

            async let sleepSignals = healthKitManager.collectSleep()
            async let hrvSignals = healthKitManager.collectHeartRateVariability()
            async let stepSignals = healthKitManager.collectSteps()
            async let locationSignals = locationManager.collectLocationHistory()
            async let calendarSignals = calendarManager.collectCalendarEvents()
            async let deviceSignals = deviceActivityManager.collectScreenTime()
            async let motionSignals = motionActivityManager.collectMotion()

            let allSignals = try await [
                sleepSignals,
                hrvSignals,
                stepSignals,
                locationSignals,
                calendarSignals,
                deviceSignals,
                motionSignals
            ].flatMap { $0 }

            for signal in allSignals {
                modelContext.insert(signal)
            }
            try modelContext.save()

            await aggregateSignals(modelContext: modelContext)

            lastUpdateTime = now
            collectionError = nil

        } catch {
            collectionError = error.localizedDescription
        }
    }

    // MARK: - Aggregation

    private func aggregateSignals(modelContext: ModelContext) async {
        let calendar = Calendar.current
        let now = Date()
        let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: now)!

        let descriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { event in
                event.timestamp >= oneDayAgo && event.timestamp <= now
            }
        )

        guard let signals = try? modelContext.fetch(descriptor) else { return }

        let hourlyWindows = groupSignalsByHour(signals)

        for (_, _) in hourlyWindows {
            // Aggregation computed but stored as-needed by inference engine
        }
    }

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

    func computeAggregates(_ signals: [SignalEvent]) -> [SignalSource: AggregatedValue] {
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
