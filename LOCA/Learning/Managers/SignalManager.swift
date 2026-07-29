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

            var allSignals: [SignalEvent] = []
            // HealthKit sources (non-throwing; graceful degradation when not authorized)
            allSignals += await healthKitManager.collectSleep()
            allSignals += await healthKitManager.collectHeartRateVariability()
            allSignals += await healthKitManager.collectHeartRate()
            allSignals += await healthKitManager.collectSteps()
            allSignals += await healthKitManager.collectWorkouts()
            allSignals += await healthKitManager.collectMindfulMinutes()
            // Other sources (may throw; degrade gracefully via try?)
            allSignals += (try? await locationManager.collectLocationHistory()) ?? []
            allSignals += (try? await calendarManager.collectCalendarEvents()) ?? []
            allSignals += (try? await deviceActivityManager.collectScreenTime()) ?? []
            allSignals += (try? await motionActivityManager.collectMotion()) ?? []

            for signal in allSignals {
                modelContext.insert(signal)
            }
            try modelContext.save()

            await aggregateSignals(modelContext: modelContext)

            // Derive higher-level structure from the raw signals just collected.
            // This is the seam `aggregateSignals` always pointed at: signals →
            // states → events → chapters/traits/people. Each stage is idempotent,
            // so it is safe to run on every collection cycle.
            await runLifeModelPipeline(modelContext: modelContext)

            lastUpdateTime = now
            collectionError = nil

        } catch {
            collectionError = error.localizedDescription
        }
    }

    // MARK: - Life Model Pipeline

    /// Runs the inference and structure pipeline over the signals in `modelContext`,
    /// in dependency order. Every stage guards against empty inputs and is
    /// idempotent, so a fresh device (no permissions, no signals) produces nothing
    /// and repeated runs converge rather than accumulate.
    ///
    /// The engines are `@MainActor` by design (they hold the `ModelContext`
    /// directly), so the pipeline runs on the main actor. Each stage's work is
    /// bounded — a day of signals for inference, a month of states for detection.
    private func runLifeModelPipeline(modelContext: ModelContext) async {
        // 1. Raw signals → hourly States (energy, stress, focus, mood).
        let stateEngine = StateInferenceEngine.shared
        stateEngine.setModelContext(modelContext)
        await stateEngine.inferStatesForPastDay(modelContext: modelContext)

        // 2. States → Life Events (coordinated, sustained regime shifts).
        let eventEngine = EventDetectionEngine.shared
        eventEngine.setModelContext(modelContext)
        await eventEngine.detectEventsForPastMonth(modelContext: modelContext)

        // 3. Life Events → Chapters (named intervals with regime-scoped baselines).
        try? ChapterBuilder.shared.buildChapters(modelContext: modelContext)

        // 4. States → Traits (slow-moving dispositions).
        try? TraitInferenceEngine.shared.updateTraits(modelContext: modelContext)

        // 5. Calendar / logged notes → People (relationships accruing over time).
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
