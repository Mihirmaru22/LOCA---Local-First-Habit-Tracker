import Foundation
import MapKit

// MARK: - GeoJSONBoundaryLoader

/// Loads high-precision Indian state & UT boundaries from the bundled GeoJSON file
/// (geoBoundaries ADM1 simplified dataset — ~5000 pts/state, 95–98% accurate).
///
/// Usage:
///   let polygons: [[[CLLocationCoordinate2D]]] = GeoJSONBoundaryLoader.shared.polygons(for: "GJ")
///   // Returns array of polygon rings (MultiPolygon → multiple polygons, Polygon → single)

final class GeoJSONBoundaryLoader {

    static let shared = GeoJSONBoundaryLoader()

    // Each stateCode → array of polygons, where each polygon is an array of coordinate rings
    private var cache: [String: [[[CLLocationCoordinate2D]]]] = [:]
    private var loaded = false
    private let lock = NSLock()

    private init() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.loadGeoJSON()
        }
    }

    private func ensureLoaded() {
        lock.lock()
        defer { lock.unlock() }
        if !loaded {
            loadGeoJSONInternal()
        }
    }

    // MARK: - Public API

    /// Returns all polygon coordinate rings for the given state code.
    func polygons(for stateCode: String) -> [[[CLLocationCoordinate2D]]] {
        ensureLoaded()
        lock.lock()
        defer { lock.unlock() }
        return cache[stateCode.uppercased()] ?? []
    }

    /// Returns flattened outer rings only (no holes), suitable for MapPolygon fill rendering.
    func outerRings(for stateCode: String) -> [[CLLocationCoordinate2D]] {
        return polygons(for: stateCode).compactMap { $0.first }
    }

    /// Returns true if boundaries are available for the given state code.
    func hasBoundary(for stateCode: String) -> Bool {
        ensureLoaded()
        lock.lock()
        defer { lock.unlock() }
        return !(cache[stateCode.uppercased()]?.isEmpty ?? true)
    }

    // MARK: - GeoJSON Name → StateCode Mapping

    /// Maps GeoJSON shapeName values to our internal state codes.
    /// The GeoJSON uses Unicode names with diacritics (e.g., "Mahārāshtra", "Rājasthān").
    private static let nameToCode: [String: String] = [
        // States (28)
        "Andhra Pradesh":           "AP",
        "Arunāchal Pradesh":        "AR",
        "Arunachal Pradesh":        "AR",
        "Assam":                    "AS",
        "Bihār":                    "BR",
        "Bihar":                    "BR",
        "Chhattīsgarh":            "CG",
        "Chhattisgarh":             "CG",
        "Goa":                      "GA",
        "Gujarāt":                  "GJ",
        "Gujarat":                  "GJ",
        "Haryāna":                  "HR",
        "Haryana":                  "HR",
        "Himāchal Pradesh":         "HP",
        "Himachal Pradesh":         "HP",
        "Jhārkhand":               "JH",
        "Jharkhand":                "JH",
        "Karnātaka":               "KA",
        "Karnataka":                "KA",
        "Kerala":                   "KL",
        "Madhya Pradesh":           "MP",
        "Mahārāshtra":             "MH",
        "Maharashtra":              "MH",
        "Manipur":                  "MN",
        "Meghālaya":               "ML",
        "Meghalaya":                "ML",
        "Mizoram":                  "MZ",
        "Nāgāland":               "NL",
        "Nagaland":                 "NL",
        "Odisha":                   "OD",
        "Punjab":                   "PB",
        "Rājasthān":              "RJ",
        "Rajasthan":                "RJ",
        "Sikkim":                   "SK",
        "Tamil Nādu":              "TN",
        "Tamil Nadu":               "TN",
        "Telangāna":              "TS",
        "Telangana":                "TS",
        "Tripura":                  "TR",
        "Uttar Pradesh":            "UP",
        "Uttarākhand":             "UK",
        "Uttarakhand":              "UK",
        "West Bengal":              "WB",

        // Union Territories (8)
        "Andaman and Nicobar Islands":                      "AN",
        "Andaman & Nicobar Islands":                        "AN",
        "Chandīgarh":                                      "CH",
        "Chandigarh":                                       "CH",
        "Dādra and Nagar Haveli and Damān and Diu":       "DN",
        "Dadra and Nagar Haveli and Daman and Diu":         "DN",
        "Delhi":                                            "DL",
        "Jammu and Kashmīr":                               "JK",
        "Jammu and Kashmir":                                "JK",
        "Jammu & Kashmir":                                  "JK",
        "Ladākh":                                          "LA",
        "Ladakh":                                           "LA",
        "Lakshadweep":                                      "LD",
        "Puducherry":                                       "PY",
        "Pondicherry":                                      "PY",
    ]

    // MARK: - Loading

    private func loadGeoJSON() {
        lock.lock()
        defer { lock.unlock() }
        loadGeoJSONInternal()
    }

    private func loadGeoJSONInternal() {
        guard !loaded else { return }
        loaded = true

        guard let url = Bundle.main.url(forResource: "india_states", withExtension: "geojson") else {
            print("⚠️ GeoJSONBoundaryLoader: india_states.geojson not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = MKGeoJSONDecoder()
            let geoObjects = try decoder.decode(data)

            for object in geoObjects {
                guard let feature = object as? MKGeoJSONFeature else { continue }

                // Extract shapeName from properties
                guard let propsData = feature.properties,
                      let props = try? JSONSerialization.jsonObject(with: propsData) as? [String: Any],
                      let shapeName = props["shapeName"] as? String else {
                    continue
                }

                // Map to state code
                guard let stateCode = Self.nameToCode[shapeName] ?? Self.fuzzyMatch(shapeName) else {
                    print("⚠️ GeoJSONBoundaryLoader: No mapping for '\(shapeName)'")
                    continue
                }

                // Extract polygons from geometry
                var statePolygons: [[[CLLocationCoordinate2D]]] = cache[stateCode] ?? []

                for geometry in feature.geometry {
                    if let polygon = geometry as? MKPolygon {
                        statePolygons.append(extractRings(from: polygon))
                    } else if let multiPolygon = geometry as? MKMultiPolygon {
                        for poly in multiPolygon.polygons {
                            statePolygons.append(extractRings(from: poly))
                        }
                    }
                }

                cache[stateCode] = statePolygons
            }

            print("✅ GeoJSONBoundaryLoader: Loaded boundaries for \(cache.count) states/UTs")

        } catch {
            print("❌ GeoJSONBoundaryLoader: Failed to decode GeoJSON — \(error)")
        }
    }

    /// Extracts coordinate rings from an MKPolygon (outer ring + interior rings/holes).
    private func extractRings(from polygon: MKPolygon) -> [[CLLocationCoordinate2D]] {
        var rings: [[CLLocationCoordinate2D]] = []

        // Outer ring
        let outerCount = polygon.pointCount
        var outerPoints = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: outerCount)
        polygon.getCoordinates(&outerPoints, range: NSRange(location: 0, length: outerCount))
        rings.append(outerPoints)

        // Interior rings (holes)
        if let interiors = polygon.interiorPolygons {
            for hole in interiors {
                let holeCount = hole.pointCount
                var holePoints = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: holeCount)
                hole.getCoordinates(&holePoints, range: NSRange(location: 0, length: holeCount))
                rings.append(holePoints)
            }
        }

        return rings
    }

    /// Fuzzy matching: strip diacritics and compare lowercased.
    private static func fuzzyMatch(_ name: String) -> String? {
        let normalized = name.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        for (key, code) in nameToCode {
            let normalizedKey = key.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            if normalizedKey == normalized {
                return code
            }
        }
        return nil
    }
}
