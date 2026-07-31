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

    /// Guards against overlapping collection passes. `collectAllSignals()` can be
    /// triggered by both the hourly background loop and an explicit startCollection();
    /// without this, two passes could fetch-then-insert concurrently and race on save.
    private var collectionInFlight = false

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

    /// Version 2.0 · P0 — On-demand pipeline refresh after a user action (e.g. a
    /// check-in), so a freshly-logged habit produces `InferredState` immediately
    /// instead of waiting for the next hourly cycle.
    ///
    /// `startCollection()` becomes a no-op once the background loop is running (its
    /// `isCollecting` guard never resets), so this deliberately bypasses it and runs
    /// a collection pass directly. `collectAllSignals()` has its own reentrancy
    /// guard, so overlapping with the background loop is safe.
    func refreshNow() {
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

        // Reentrancy guard: never run two overlapping passes (@MainActor makes this
        // check-and-set atomic). Prevents concurrent fetch/insert/save races.
        guard !collectionInFlight else { return }
        collectionInFlight = true
        defer { collectionInFlight = false }

        do {
            let now = Date()

            var allSignals: [SignalEvent] = []
            let consent = SignalSourceConsent.shared

            // Each source is gated on the consent ledger (C3.4): revoking a source
            // stops its ingestion on the very next cycle. OS-permission denial is
            // still handled independently inside each collector (returns []).

            // HealthKit (non-throwing; graceful degradation when not authorized)
            if consent.isEnabled(.sleep)                { allSignals += await healthKitManager.collectSleep() }
            if consent.isEnabled(.heartRateVariability) { allSignals += await healthKitManager.collectHeartRateVariability() }
            if consent.isEnabled(.heartRate)            { allSignals += await healthKitManager.collectHeartRate() }
            if consent.isEnabled(.steps)                { allSignals += await healthKitManager.collectSteps() }
            if consent.isEnabled(.workout)              { allSignals += await healthKitManager.collectWorkouts() }
            if consent.isEnabled(.mindfulSession)       { allSignals += await healthKitManager.collectMindfulMinutes() }

            // Context (non-throwing; graceful degradation when not authorized)
            if consent.isEnabled(.calendar)       { allSignals += await calendarManager.collectCalendarEvents() }
            if consent.isEnabled(.location)       { allSignals += await locationManager.collectLocationHistory() }
            if consent.isEnabled(.motionActivity) { allSignals += await motionActivityManager.collectMotion() }
            if consent.isEnabled(.daylight) {
                allSignals += daylightManager.collectDaylight(
                    coordinate: locationManager.lastLocation?.coordinate
                )
            }

            // Device activity (may throw)
            allSignals += (try? await deviceActivityManager.collectScreenTime()) ?? []

            // Habit bridge — authoritative user-logged facts (C3.3)
            allSignals += habitBridgeManager.collectHabitLogs(modelContext: modelContext)

            // Dedup against what is already stored. Collectors re-read the same
            // historical window every cycle; without this the store accumulates a
            // fresh copy of every sample on each run (unbounded growth, inflated
            // sample counts). The habit bridge already dedups by log_entry_id;
            // this is the guard for every sensor source.
            let newSignals = deduplicate(allSignals, modelContext: modelContext)

            // Update provenance ledger before persisting (C3.4). Counts only new
            // observations, not re-reads of the same samples.
            sourceProvenanceManager.updateProvenance(for: newSignals, modelContext: modelContext)

            for signal in newSignals {
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

    // MARK: - Deduplication

    /// Returns only the signals not already present in the store, keyed by
    /// source + timestamp + value. Also dedups within the incoming batch.
    ///
    /// A single sensor sample re-read on a later cycle yields an identical
    /// (source, timestamp, value) triple, so it maps to the same key and is
    /// dropped. Two genuinely distinct samples never share all three.
    private func deduplicate(_ signals: [SignalEvent], modelContext: ModelContext) -> [SignalEvent] {
        guard let earliest = signals.map(\.timestamp).min() else { return [] }

        let descriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { $0.timestamp >= earliest }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        func key(_ s: SignalEvent) -> String {
            "\(s.source.rawValue)|\(s.timestamp.timeIntervalSince1970)|\(s.value)"
        }

        var seen = Set(existing.map(key))
        var result: [SignalEvent] = []
        for signal in signals where seen.insert(key(signal)).inserted {
            result.append(signal)
        }
        return result
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
        _ = groupSignalsByHour(signals)
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

// MARK: - LifeModelNudge (Version 2.0 · P0)

/// Central hook fired after a habit check-in so the Life model reflects the new
/// fact right away rather than on the next hourly cycle: it refreshes the passive
/// inference pipeline (producing fresh `InferredState` from the just-bridged log)
/// and re-derives traits. All work is best-effort and non-blocking — failures
/// never surface to the check-in flow.
enum LifeModelNudge {
    /// Callable from any context (e.g. a SwiftUI view action). The actual work runs
    /// on the main actor, matching where the singletons and the model context live.
    static func afterCheckIn(modelContext: ModelContext) {
        Task { @MainActor in
            SignalManager.shared.refreshNow()
            try? TraitInferenceEngine.shared.updateTraits(modelContext: modelContext)
        }
    }
}
