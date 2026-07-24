//
//  LocationManager.swift
//  LOCA
//
//  Location tracking and place inference
//

import Foundation
import CoreLocation

@MainActor
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var isAuthorized = false
    private var knownPlaces: [KnownPlace] = []

    override init() {
        super.init()
        manager.delegate = self
        requestAuthorization()
        loadKnownPlaces()
    }

    private func requestAuthorization() {
        manager.requestAlwaysAndWhenInUseAuthorization()
    }

    private func loadKnownPlaces() {
        knownPlaces = [
            KnownPlace(name: "Home", latitude: 0, longitude: 0, radius: 100),
            KnownPlace(name: "Work", latitude: 0, longitude: 0, radius: 100),
        ]
    }

    // MARK: - Location Collection

    func collectLocationHistory() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        var signals: [SignalEvent] = []

        return signals
    }

    // MARK: - Location Manager Delegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
    }
}

struct KnownPlace {
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
}
