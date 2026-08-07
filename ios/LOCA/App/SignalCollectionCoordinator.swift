//
//  SignalCollectionCoordinator.swift
//  LOCA
//
//  C3.1 — Signal collection lifecycle coordinator
//  Manages permissions, initialization, and collection loop.
//
//  HealthKit permissions are requested only after the HealthKitPermissionView
//  framing has been shown (C3.1). Calendar and Location use standard OS dialogs
//  and are requested from start(). All sources degrade gracefully when denied.
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

    // C3.1: true until the user has seen HealthKitPermissionView.
    @Published var needsHealthKitFraming: Bool
    // C3.2: true until the user has seen ContextPermissionView.
    @Published var needsContextPermissionFraming: Bool

    private static let hkFramingKey      = "com.loca.hkFramingShown"
    private static let ctxFramingKey     = "com.loca.contextFramingShown"

    private var signalManager: SignalManager?
    private let logger = Logger(subsystem: "com.loca.signals", category: "collection")

    private var modelContext: ModelContext?

    enum PermissionStatus: String {
        case notRequested = "Not Requested"
        case requesting = "Requesting..."
        case granted = "Granted"
        case denied = "Denied"
    }

    override init() {
        needsHealthKitFraming          = !UserDefaults.standard.bool(forKey: Self.hkFramingKey)
        needsContextPermissionFraming  = !UserDefaults.standard.bool(forKey: Self.ctxFramingKey)
        super.init()
    }

    // MARK: - HealthKit Framing (C3.1)

    func enableHealthKit() async {
        markHealthKitFramingShown()
        _ = await requestHealthKitPermission()
    }

    func skipHealthKit() {
        markHealthKitFramingShown()
    }

    private func markHealthKitFramingShown() {
        UserDefaults.standard.set(true, forKey: Self.hkFramingKey)
        needsHealthKitFraming = false
    }

    // MARK: - Context Framing (C3.2)

    /// Called by ContextPermissionView's "Enable" button.
    func enableContextSources() async {
        markContextFramingShown()
        async let cal = requestCalendarPermission()
        async let loc = requestLocationPermission()
        _ = await (cal, loc)
    }

    func skipContextSources() {
        markContextFramingShown()
    }

    private func markContextFramingShown() {
        UserDefaults.standard.set(true, forKey: Self.ctxFramingKey)
        needsContextPermissionFraming = false
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

    /// Requests Calendar and Location permissions. HealthKit is handled separately
    /// through the HealthKitPermissionView framing flow (C3.1).
    func requestPermissions() async -> Bool {
        permissionStatus = .requesting

        async let calendarGranted = requestCalendarPermission()
        async let locationGranted = requestLocationPermission()

        let results = await (calendarGranted, locationGranted)

        if results.0 || results.1 {
            permissionStatus = .granted
            logger.info("Non-HealthKit signal permissions granted")
            return true
        } else {
            permissionStatus = .denied
            logger.warning("Non-HealthKit signal permissions denied")
            return false
        }
    }

    /// Requests HealthKit read authorization for all types in HealthKitManager.readTypes.
    /// Called after permission framing via enableHealthKit(), not from start().
    func requestHealthKitPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            HKHealthStore().requestAuthorization(
                toShare: nil,
                read: HealthKitManager.readTypes
            ) { granted, error in
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
        // Triggers the system When-In-Use dialog. The grant/deny result is delivered
        // asynchronously to LocationManager's delegate, which starts significant-change
        // monitoring on grant. We return true to signal the request was initiated.
        SignalManager.shared.locationManager.requestAuthorization()
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

        // All permissions are requested through their respective framing views
        // (C3.1 HealthKitPermissionView, C3.2 ContextPermissionView). Collection
        // starts immediately; every source degrades gracefully when not authorized.
        manager.startCollection()

        while isCollecting && !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 3600 * 1_000_000_000)
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
}
