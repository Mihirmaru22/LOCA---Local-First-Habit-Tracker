//
//  LocationManager.swift
//  LOCA
//
//  C3.2 — Location context ingestion
//  Uses significant-location-change monitoring (battery-efficient) to record
//  place transitions as SignalEvents. Removed eager auth from init;
//  ContextPermissionView handles the permission flow.
//
//  The place classifier is intentionally coarse: it records lat/lng and a
//  place type (home/work/transit/other) derived from time-of-day heuristics.
//  Cluster-based personalization accumulates over time as more locations land.
//

import Foundation
import CoreLocation

@MainActor
class LocationManager: NSObject {
    private let manager = CLLocationManager()
    private lazy var locationDelegate = LocationDelegate(owner: self)

    private(set) var lastLocation: CLLocation?
    private var isMonitoring = false

    override init() {
        super.init()
        manager.delegate = locationDelegate
        manager.distanceFilter = 200  // metres
    }

    // MARK: - Authorization

    /// Requests When-In-Use location authorization. The system dialog appears once;
    /// the result arrives via the delegate's authorization callback, which starts
    /// significant-change monitoring when granted. Called from the ContextPermissionView
    /// flow (C3.2), not from init.
    func requestAuthorization() {
        #if os(iOS)
        manager.requestWhenInUseAuthorization()
        #else
        manager.requestAlwaysAuthorization()
        #endif
    }

    // MARK: - Start Monitoring (called after permission granted)

    func startMonitoringSignificantLocationChanges() {
        guard !isMonitoring else { return }
        isMonitoring = true
        manager.startMonitoringSignificantLocationChanges()
    }

    func updateAuthorization(_ status: CLAuthorizationStatus) {
        #if os(iOS)
        let granted = status == .authorizedAlways || status == .authorizedWhenInUse
        #else
        let granted = status == .authorized || status == .authorizedAlways
        #endif
        if granted { startMonitoringSignificantLocationChanges() }
    }

    func recordLocation(_ location: CLLocation) {
        lastLocation = location
    }

    // MARK: - Collection

    func collectLocationHistory() async -> [SignalEvent] {
        let authStatus = manager.authorizationStatus
        #if os(iOS)
        let authorized = authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse
        #else
        let authorized = authStatus == .authorized || authStatus == .authorizedAlways
        #endif
        guard authorized else { return [] }
        guard let location = lastLocation else { return [] }

        let placeType = classifyPlaceType(location)
        let mobilityValue = mobilityScore(for: placeType)

        return [SignalEvent(
            timestamp: location.timestamp,
            source: .location,
            value: mobilityValue,
            uncertainty: 0.25,
            metadata: [
                "place_type": placeType,
                "lat": String(format: "%.4f", location.coordinate.latitude),
                "lng": String(format: "%.4f", location.coordinate.longitude),
                "accuracy_m": String(format: "%.0f", location.horizontalAccuracy),
            ]
        )]
    }

    // MARK: - Place Classification

    // Time-of-day heuristic until cluster-based personalization accumulates.
    private func classifyPlaceType(_ location: CLLocation) -> String {
        let hour = Calendar.current.component(.hour, from: location.timestamp)
        let speed = location.speed  // m/s; negative = invalid

        if speed > 8 { return "transit" }          // ~30 km/h or faster
        if (0...7).contains(hour) { return "home" }
        if (9...17).contains(hour) { return "work" }
        return "other"
    }

    private func mobilityScore(for placeType: String) -> Double {
        switch placeType {
        case "transit": return 0.8
        case "work":    return 0.5
        case "home":    return 0.2
        default:        return 0.4
        }
    }
}

// MARK: - Delegate (nonisolated, Sendable)

private final class LocationDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private weak var owner: LocationManager?

    init(owner: LocationManager) { self.owner = owner }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak owner] in owner?.updateAuthorization(status) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak owner] in owner?.recordLocation(location) }
    }
}
