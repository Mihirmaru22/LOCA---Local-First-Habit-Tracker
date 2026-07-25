//
//  SignalCollectionCoordinator.swift
//  LOCA
//
//  Phase 4 — Signal collection lifecycle coordinator
//  Manages permissions, initialization, and collection loop
//

import Foundation
import SwiftData
import HealthKit
import EventKit
import os.log

@MainActor
class SignalCollectionCoordinator: NSObject, ObservableObject {
    static let shared = SignalCollectionCoordinator()

    @Published var isInitialized = false
    @Published var isCollecting = false
    @Published var permissionStatus: PermissionStatus = .notRequested
    @Published var lastCollectionTime: Date?
    @Published var collectionError: String?

    private var signalManager: SignalManager?
    private let logger = Logger(subsystem: "com.loca.signals", category: "collection")

    private var modelContext: ModelContext?

    enum PermissionStatus: String {
        case notRequested = "Not Requested"
        case requesting = "Requesting..."
        case granted = "Granted"
        case denied = "Denied"
    }

    // MARK: - Initialization

    func initialize(modelContext: ModelContext) async {
        guard !isInitialized else { return }

        self.modelContext = modelContext

        let manager = SignalManager.shared
        manager.setModelContext(modelContext)
        self.signalManager = manager

        isInitialized = true
        logger.debug("SignalCollectionCoordinator initialized")
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        permissionStatus = .requesting

        async let healthKitGranted = requestHealthKitPermission()
        async let calendarGranted = requestCalendarPermission()
        async let locationGranted = requestLocationPermission()

        let results = await (healthKitGranted, calendarGranted, locationGranted)

        if results.0 || results.1 || results.2 {
            permissionStatus = .granted
            logger.info("Signal collection permissions granted")
            return true
        } else {
            permissionStatus = .denied
            logger.warning("Signal collection permissions denied")
            return false
        }
    }

    private func requestHealthKitPermission() async -> Bool {
        let typesToRead: Set<HKObjectType> = Set(
            [
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
                HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
                HKObjectType.quantityType(forIdentifier: .stepCount),
            ].compactMap { $0 }
        )

        guard !typesToRead.isEmpty else { return false }

        return await withCheckedContinuation { continuation in
            HKHealthStore().requestAuthorization(toShare: nil, read: typesToRead) { granted, error in
                if let error = error {
                    self.logger.error("HealthKit permission error: \(error.localizedDescription)")
                }
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestCalendarPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            EKEventStore().requestFullAccessToEvents { granted, error in
                if let error = error {
                    self.logger.error("Calendar permission error: \(error.localizedDescription)")
                }
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestLocationPermission() async -> Bool {
        // Location permission flow handled by LocationManager
        // Return true optimistically; CLLocationManager requests on its own
        return true
    }

    // MARK: - Collection Loop

    func start() async {
        guard isInitialized, let manager = signalManager else {
            logger.warning("SignalCollectionCoordinator not initialized; skipping start")
            return
        }

        guard !isCollecting else { return }
        isCollecting = true

        logger.info("Starting signal collection")

        // Request permissions on first start
        let permissionsGranted = await requestPermissions()
        if !permissionsGranted {
            logger.warning("Permissions not fully granted; continuing with available signals")
        }

        // Start collection
        manager.startCollection()

        // Monitoring loop: check status every hour.
        // Checks Task.isCancelled at the top of every iteration (Engineering Principles §3.3).
        // When the parent .task is cancelled, Task.sleep throws CancellationError; the catch
        // block logs nothing (isCancelled == true) and the loop exits on the next condition check.
        while isCollecting && !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 3600 * 1_000_000_000)  // 1 hour
                lastCollectionTime = manager.lastUpdateTime
                if let error = manager.collectionError {
                    self.collectionError = error
                    logger.error("Collection error: \(error)")
                }
            } catch {
                if !Task.isCancelled {
                    logger.error("Collection monitoring error: \(error.localizedDescription)")
                }
                break
            }
        }

        logger.info("Signal collection stopped")
    }

    func stop() {
        guard isCollecting else { return }
        isCollecting = false
        signalManager?.stopCollection()
        logger.info("Signal collection coordinator stopped")
    }

    // No `deinit { stop() }` here: the singleton lives for the app process's
    // entire lifetime, so its deinit never actually runs. Wiring one would
    // require an unsafe cross-actor hop from the nonisolated deinit into
    // @MainActor's `stop()` for no observable benefit.
}
