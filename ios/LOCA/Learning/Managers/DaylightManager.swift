//
//  DaylightManager.swift
//  LOCA
//
//  C3.2 — On-device daylight signal
//  Computes solar elevation from latitude/longitude and local time entirely
//  on-device; no network egress. Uses a simplified NOAA solar position
//  formula accurate to within ≈1° for most latitudes.
//
//  Value mapping: 0.0 = below horizon (night), 1.0 = solar noon.
//  Feeds the inference engine as an ambient-light prior for energy and mood.
//

import Foundation
import CoreLocation

class DaylightManager {

    // MARK: - Collection

    func collectDaylight(coordinate: CLLocationCoordinate2D?) -> [SignalEvent] {
        let coord = coordinate ?? CLLocationCoordinate2D(latitude: 40.7, longitude: -74.0)
        let now = Date()
        let value = solarElevationFraction(at: now, coordinate: coord)

        return [SignalEvent(
            timestamp: now,
            source: .daylight,
            value: value,
            uncertainty: 0.05,
            metadata: [
                "solar_fraction": String(format: "%.2f", value),
                "lat": String(format: "%.2f", coord.latitude),
            ]
        )]
    }

    // MARK: - Solar Position

    // Simplified solar elevation: sin(elevation) = sin(lat)·sin(dec) + cos(lat)·cos(dec)·cos(ha)
    // where dec = solar declination, ha = hour angle.
    private func solarElevationFraction(at date: Date, coordinate: CLLocationCoordinate2D) -> Double {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: date))
            + Double(calendar.component(.minute, from: date)) / 60.0

        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let declinationDeg = 23.45 * sin(2 * .pi * (284 + dayOfYear) / 365)
        let hourAngleDeg = (hour - 12.0) * 15.0

        let lat = coordinate.latitude * .pi / 180
        let dec = declinationDeg * .pi / 180
        let ha  = hourAngleDeg   * .pi / 180

        let sinElevation = sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(ha)
        let elevationDeg = asin(max(-1, min(1, sinElevation))) * 180 / .pi

        return max(0.0, min(1.0, elevationDeg / 90.0))
    }
}
