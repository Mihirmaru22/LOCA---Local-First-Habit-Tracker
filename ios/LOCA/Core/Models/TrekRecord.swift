import SwiftData
import Foundation
import CoreLocation

// MARK: - TrekStatus

public enum TrekStatus: Int, CaseIterable, Codable, Sendable {
    case wishlist   = 0
    case conquered  = 1
    case inProgress = 2

    public var title: String {
        switch self {
        case .wishlist:   return "Wishlist / Planned"
        case .conquered:  return "Conquered"
        case .inProgress: return "In Progress"
        }
    }

    public var icon: String {
        switch self {
        case .wishlist:   return "mappin.and.ellipse"
        case .conquered:  return "trophy.fill"
        case .inProgress: return "figure.hiking"
        }
    }
}

// MARK: - TrekDifficulty

public enum TrekDifficulty: Int, CaseIterable, Codable, Sendable {
    case moderate     = 0
    case strenuous    = 1
    case alpineExpert = 2
    case extreme      = 3

    public var title: String {
        switch self {
        case .moderate:     return "Moderate"
        case .strenuous:    return "Strenuous"
        case .alpineExpert: return "Alpine Expert"
        case .extreme:      return "Extreme"
        }
    }

    public var badgeColorHex: String {
        switch self {
        case .moderate:     return "#34D399" // Emerald
        case .strenuous:    return "#FBBF24" // Amber
        case .alpineExpert: return "#F87171" // Coral Red
        case .extreme:      return "#C084FC" // Violet
        }
    }
}

// MARK: - TrekRecord

/// A mountain peak, hiking trail, or expedition waypoint tracked in Pluto's Life → Trek & Mountain Atlas.
///
/// Fully future-proofed with hooks for Fog-of-War polygon cutouts, GPX trail geometry,
/// HealthKit workout synchronization, and summit weather narratives.
@Model
final class TrekRecord {

    // Identity & Metadata
    var id:                  UUID   = UUID()
    var name:                String = ""
    var region:              String = ""
    var country:             String = ""
    var createdAt:           Date   = Date()
    var archivedAt:          Date?  = nil

    // Geographical & Elevation Telemetry
    var latitude:            Double = 0.0
    var longitude:           Double = 0.0
    var elevationMeters:     Double = 0.0
    var trailDistanceKm:     Double? = nil
    var elevationGainMeters: Double? = nil

    // Progression Status
    var statusRaw:           Int    = TrekStatus.conquered.rawValue
    var difficultyRaw:       Int    = TrekDifficulty.moderate.rawValue
    var dateConquered:       Date?  = nil
    var rating:              Int    = 5

    // Journal Reflections & Media
    var personalNotes:          String = ""
    var photoFileNames:         [String] = []
    var linkedJournalNoteIDs:   [UUID] = []

    // MARK: - Future-Proofing Hooks (Phases 2, 3 & 4)
    var gpxData:               Data?   = nil
    var gpxTrackPointsJSON:    String? = nil
    var revealRadiusMeters:    Double? = 5000.0
    var healthKitWorkoutUUID:  String? = nil
    var avgHeartRate:          Double? = nil
    var activeCalories:        Double? = nil
    var summitWeatherSummary:  String? = nil

    // MARK: - Computed Properties

    var isArchived: Bool { archivedAt != nil }

    var status: TrekStatus {
        get { TrekStatus(rawValue: statusRaw) ?? .conquered }
        set { statusRaw = newValue.rawValue }
    }

    var difficulty: TrekDifficulty {
        get { TrekDifficulty(rawValue: difficultyRaw) ?? .moderate }
        set { difficultyRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var elevationFeet: Double {
        elevationMeters * 3.28084
    }

    var formattedElevation: String {
        let m = Int(elevationMeters)
        let ft = Int(elevationFeet)
        return "\(m.formatted()) m · \(ft.formatted()) ft"
    }

    var formattedDistance: String? {
        guard let km = trailDistanceKm else { return nil }
        return String(format: "%.1f km", km)
    }

    var formattedGain: String? {
        guard let gain = elevationGainMeters else { return nil }
        return String(format: "+%.0f m", gain)
    }

    var coordinatesString: String {
        let latDir = latitude >= 0 ? "N" : "S"
        let lonDir = longitude >= 0 ? "E" : "W"
        return String(format: "%.4f° %@, %.4f° %@", abs(latitude), latDir, abs(longitude), lonDir)
    }

    // MARK: - Photo & Media Mutations (4.1)

    func attachPhoto(fileName: String) {
        guard !photoFileNames.contains(fileName) else { return }
        photoFileNames.append(fileName)
    }

    func attachPhotos(fileNames: [String]) {
        for name in fileNames where !photoFileNames.contains(name) {
            photoFileNames.append(name)
        }
    }

    func removePhoto(fileName: String) {
        photoFileNames.removeAll { $0 == fileName }
        TrekMediaManager.shared.deletePhoto(fileName: fileName)
    }

    func removePhoto(at index: Int) {
        guard index >= 0 && index < photoFileNames.count else { return }
        let fileName = photoFileNames.remove(at: index)
        TrekMediaManager.shared.deletePhoto(fileName: fileName)
    }

    // MARK: - Apple Journal Cross-Link Mutations (4.1)

    func linkJournalNote(id: UUID) {
        guard !linkedJournalNoteIDs.contains(id) else { return }
        linkedJournalNoteIDs.append(id)
    }

    func unlinkJournalNote(id: UUID) {
        linkedJournalNoteIDs.removeAll { $0 == id }
    }

    func isJournalNoteLinked(id: UUID) -> Bool {
        linkedJournalNoteIDs.contains(id)
    }

    // MARK: - GPX Trail Mutations & Accessors (4.2)

    var hasGPXTrack: Bool {
        gpxData != nil || (gpxTrackPointsJSON != nil && gpxTrackPointsJSON != "[]")
    }

    var decodedTrackPoints: [GPXTrackPoint] {
        guard let json = gpxTrackPointsJSON, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([GPXTrackPoint].self, from: data)) ?? []
    }

    var trailCoordinates: [CLLocationCoordinate2D] {
        decodedTrackPoints.map(\.coordinate)
    }

    func attachGPXTrack(result: GPXParseResult) {
        self.gpxData = result.rawGPXData
        self.gpxTrackPointsJSON = result.jsonTrackPointsString
        self.trailDistanceKm = result.totalDistanceKm
        self.elevationGainMeters = result.elevationGainMeters

        if self.elevationMeters <= 0 && result.maxAltitudeMeters > 0 {
            self.elevationMeters = result.maxAltitudeMeters
        }
        if (self.latitude == 0 && self.longitude == 0), let summit = result.summitCoordinate {
            self.latitude = summit.latitude
            self.longitude = summit.longitude
        }
    }

    func removeGPXTrack() {
        self.gpxData = nil
        self.gpxTrackPointsJSON = nil
    }

    // MARK: - Initializer

    init(
        name: String,
        region: String,
        country: String,
        latitude: Double,
        longitude: Double,
        elevationMeters: Double,
        trailDistanceKm: Double? = nil,
        elevationGainMeters: Double? = nil,
        status: TrekStatus = .conquered,
        difficulty: TrekDifficulty = .moderate,
        dateConquered: Date? = Date(),
        rating: Int = 5,
        personalNotes: String = "",
        photoFileNames: [String] = [],
        linkedJournalNoteIDs: [UUID] = []
    ) {
        self.name = name
        self.region = region
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.trailDistanceKm = trailDistanceKm
        self.elevationGainMeters = elevationGainMeters
        self.statusRaw = status.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.dateConquered = (status == .conquered) ? (dateConquered ?? Date()) : nil
        self.rating = rating
        self.personalNotes = personalNotes
        self.photoFileNames = photoFileNames
        self.linkedJournalNoteIDs = linkedJournalNoteIDs
        self.createdAt = Date()
    }
}
