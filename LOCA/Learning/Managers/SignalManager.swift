//
//  SignalManager.swift
//  LOCA
//
//  Signal ingestion coordinator
//  Manages all signal sources and aggregation
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
    let locationManager = LocationManager()       // internal; DaylightManager reads lastLocation
    private let deviceActivityManager = DeviceActivityManager()
    private let motionActivityManager = MotionActivityManager()
    private let daylightManager = DaylightManager()
    private let habitBridgeManager = HabitBridgeManager()
    private let sourceProvenanceManager = SourceProvenanceManager.shared

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

            var allSignals: [SignalEvent] = []

            // HealthKit (non-throwing; graceful degradation when not authorized)
            allSignals += await healthKitManager.collectSleep()
            allSignals += await healthKitManager.collectHeartRateVariability()
            allSignals += await healthKitManager.collectHeartRate()
            allSignals += await healthKitManager.collectSteps()
            allSignals += await healthKitManager.collectWorkouts()
            allSignals += await healthKitManager.collectMindfulMinutes()

            // Context (non-throwing; graceful degradation when not authorized)
            allSignals += await calendarManager.collectCalendarEvents()
            allSignals += await locationManager.collectLocationHistory()
            allSignals += await motionActivityManager.collectMotion()
            allSignals += daylightManager.collectDaylight(
                coordinate: locationManager.lastLocation?.coordinate
            )

            // Device activity (may throw)
            allSignals += (try? await deviceActivityManager.collectScreenTime()) ?? []

            // Habit bridge — authoritative user-logged facts (C3.3)
            allSignals += habitBridgeManager.collectHabitLogs(modelContext: modelContext)

            // Update provenance ledger before persisting (C3.4)
            sourceProvenanceManager.updateProvenance(for: allSignals, modelContext: modelContext)

            for signal in allSignals {
                modelContext.insert(signal)
            }
            try modelContext.save()

            await aggregateSignals(modelContext: modelContext)
            await runLifeModelPipeline(modelContext: modelContext)

            lastUpdateTime = now
            collectionError = nil

        } catch {
            collectionError = error.localizedDescription
        }
    }

    // MARK: - Life Model Pipeline

    private func runLifeModelPipeline(modelContext: ModelContext) async {
        let stateEngine = StateInferenceEngine.shared
        stateEngine.setModelContext(modelContext)
        await stateEngine.inferStatesForPastDay(modelContext: modelContext)

        let eventEngine = EventDetectionEngine.shared
        eventEngine.setModelContext(modelContext)
        await eventEngine.detectEventsForPastMonth(modelContext: modelContext)

        try? ChapterBuilder.shared.buildChapters(modelContext: modelContext)
        try? TraitInferenceEngine.shared.updateTraits(modelContext: modelContext)
        try? await PeopleExtractor.shared.extractPeople(modelContext: modelContext)
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
        let _ = groupSignalsByHour(signals)
    }

    private func groupSignalsByHour(_ signals: [SignalEvent]) -> [Date: [SignalEvent]] {
        let calendar = Calendar.current
        var grouped: [Date: [SignalEvent]] = [:]

        for signal in signals {
            let hourStart = calendar.dateComponents([.year, .month, .day, .hour], from: signal.timestamp)
            let hourStartDate = calendar.date(from: hourStart)!
            grouped[hourStartDate, default: []].append(signal)
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
            let propagatedUncertainty = sqrt(
                uncertainties.map { pow($0, 2) }.reduce(0, +)
            ) / Double(uncertainties.count)

            aggregates[source] = AggregatedValue(
                mean: mean,
                max: values.max() ?? 0,
                min: values.min() ?? 0,
                stddev: sqrt(variance),
                uncertainty: propagatedUncertainty,
                sampleCount: sourceSignals.count
            )
        }

        return aggregates
    }
}
