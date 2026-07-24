//
//  LocationManager.swift
//  LOCA
//
//  Location tracking and place inference
//

import Foundation
import CoreLocation

@MainActor
class LocationManager: NSObject {
    private let manager = CLLocationManager()
    private var isAuthorized = false
    private var knownPlaces: [KnownPlace] = []

    private lazy var delegate = LocationDelegate(owner: self)

    override init() {
        super.init()
        manager.delegate = delegate
        manager.requestWhenInUseAuthorization()
        loadKnownPlaces()
    }

    func updateAuthorization(_ status: CLAuthorizationStatus) {
        isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
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
        return []
    }
}

// MARK: - Delegate (non-isolated)

private final class LocationDelegate: NSObject, CLLocationManagerDelegate, Sendable {
    private weak var owner: LocationManager?

    init(owner: LocationManager) {
        self.owner = owner
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak owner] in
            owner?.updateAuthorization(status)
        }
    }
}

struct KnownPlace {
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
}
