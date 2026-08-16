import Foundation
import CoreLocation

// MARK: - GPXTrackPoint

struct GPXTrackPoint: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let timestamp: Date?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
        case elevation = "ele"
        case timestamp = "time"
    }

    init(latitude: Double, longitude: Double, elevation: Double? = nil, timestamp: Date? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.timestamp = timestamp
    }
}

// MARK: - GPXParseResult

struct GPXParseResult: Sendable {
    let trackName: String?
    let trackPoints: [GPXTrackPoint]
    let totalDistanceKm: Double
    let elevationGainMeters: Double
    let maxAltitudeMeters: Double
    let minAltitudeMeters: Double
    let startCoordinate: CLLocationCoordinate2D?
    let summitCoordinate: CLLocationCoordinate2D?
    let rawGPXData: Data
    let jsonTrackPointsString: String

    var coordinates: [CLLocationCoordinate2D] {
        trackPoints.map(\.coordinate)
    }
}

// MARK: - TrekGPXEngine

/// High-performance XML parser and mathematical elevation engine for GPX tracks in Pluto's Trek Atlas.
final class TrekGPXEngine: NSObject, XMLParserDelegate, @unchecked Sendable {

    // MARK: - Static Parser API

    static func parse(url: URL) async throws -> GPXParseResult {
        let data = try Data(contentsOf: url)
        return try await parse(data: data)
    }

    static func parse(data: Data) async throws -> GPXParseResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let engine = TrekGPXEngine(data: data)
                do {
                    let result = try engine.executeParse()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Parser State

    private let rawData: Data
    private var parsedPoints: [GPXTrackPoint] = []
    private var trackName: String? = nil

    private var currentElement: String = ""
    private var currentLatitude: Double? = nil
    private var currentLongitude: Double? = nil
    private var currentElevationText: String = ""
    private var currentTimeText: String = ""
    private var currentNameText: String = ""
    private var isInsideTrack: Bool = false

    private static let isoFormatterWithMillis: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private init(data: Data) {
        self.rawData = data
        super.init()
    }

    private func executeParse() throws -> GPXParseResult {
        let parser = XMLParser(data: rawData)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false

        guard parser.parse() else {
            throw parser.parserError ?? NSError(domain: "TrekGPXEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse GPX XML"])
        }

        guard !parsedPoints.isEmpty else {
            throw NSError(domain: "TrekGPXEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "GPX file contains no valid track points (<trkpt>)"])
        }

        // Compute Geodesics & Vertical Telemetry
        var totalDistanceKm = 0.0
        var totalGainMeters = 0.0
        var maxAlt = -Double.greatestFiniteMagnitude
        var minAlt = Double.greatestFiniteMagnitude
        var highestPointCoord = parsedPoints[0].coordinate

        for i in 0..<parsedPoints.count {
            let pt = parsedPoints[i]

            // Track Max & Min Altitude
            if let ele = pt.elevation {
                if ele > maxAlt {
                    maxAlt = ele
                    highestPointCoord = pt.coordinate
                }
                if ele < minAlt {
                    minAlt = ele
                }
            }

            // Distance & Positive Ascent Gain calculation between sequential points
            if i > 0 {
                let prev = parsedPoints[i - 1]
                let dist = haversineDistanceKm(
                    lat1: prev.latitude,
                    lon1: prev.longitude,
                    lat2: pt.latitude,
                    lon2: pt.longitude
                )
                totalDistanceKm += dist

                if let prevEle = prev.elevation, let curEle = pt.elevation {
                    let delta = curEle - prevEle
                    if delta > 1.5 { // Noise threshold to discard minor GPS altitude fluctuations
                        totalGainMeters += delta
                    }
                }
            }
        }

        if maxAlt == -Double.greatestFiniteMagnitude { maxAlt = 0 }
        if minAlt == Double.greatestFiniteMagnitude { minAlt = 0 }

        // Encode to JSON String for SwiftData persistence
        let jsonString: String
        if let encoded = try? JSONEncoder().encode(parsedPoints),
           let str = String(data: encoded, encoding: .utf8) {
            jsonString = str
        } else {
            jsonString = "[]"
        }

        return GPXParseResult(
            trackName: trackName?.trimmingCharacters(in: .whitespacesAndNewlines),
            trackPoints: parsedPoints,
            totalDistanceKm: totalDistanceKm,
            elevationGainMeters: totalGainMeters,
            maxAltitudeMeters: maxAlt,
            minAltitudeMeters: minAlt,
            startCoordinate: parsedPoints.first?.coordinate,
            summitCoordinate: highestPointCoord,
            rawGPXData: rawData,
            jsonTrackPointsString: jsonString
        )
    }

    // MARK: - XMLParserDelegate

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()

        if currentElement == "trk" {
            isInsideTrack = true
        } else if currentElement == "trkpt" || currentElement == "wpt" {
            currentElevationText = ""
            currentTimeText = ""
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                currentLatitude = lat
                currentLongitude = lon
            }
        } else if currentElement == "name" && isInsideTrack && trackName == nil {
            currentNameText = ""
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "ele" {
            currentElevationText += string
        } else if currentElement == "time" {
            currentTimeText += string
        } else if currentElement == "name" && isInsideTrack && trackName == nil {
            currentNameText += string
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let tag = elementName.lowercased()

        if tag == "trkpt" || tag == "wpt" {
            if let lat = currentLatitude, let lon = currentLongitude {
                let ele = Double(currentElevationText.trimmingCharacters(in: .whitespacesAndNewlines))
                let date = parseDate(from: currentTimeText.trimmingCharacters(in: .whitespacesAndNewlines))
                let pt = GPXTrackPoint(latitude: lat, longitude: lon, elevation: ele, timestamp: date)
                parsedPoints.append(pt)
            }
            currentLatitude = nil
            currentLongitude = nil
            currentElevationText = ""
            currentTimeText = ""
        } else if tag == "name" && isInsideTrack && trackName == nil {
            trackName = currentNameText
        } else if tag == "trk" {
            isInsideTrack = false
        }
    }

    private func parseDate(from text: String) -> Date? {
        guard !text.isEmpty else { return nil }
        return Self.isoFormatterWithMillis.date(from: text) ?? Self.isoFormatterBasic.date(from: text)
    }

    // MARK: - Mathematical Geodesics

    private func haversineDistanceKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6371.0 // Mean Earth radius in km
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }
}
