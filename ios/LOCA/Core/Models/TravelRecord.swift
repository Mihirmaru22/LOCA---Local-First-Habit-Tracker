import SwiftData
import Foundation
import CoreLocation

// MARK: - TravelZone

public enum TravelZone: Int, CaseIterable, Codable, Sendable {
    case western      = 0
    case northern     = 1
    case southern     = 2
    case eastern      = 3
    case northEast    = 4
    case central      = 5
    case unionTerritory = 6
    case subcontinent = 7

    public var title: String {
        switch self {
        case .western:        return "Western India"
        case .northern:       return "Northern India"
        case .southern:       return "Southern India"
        case .eastern:        return "Eastern India"
        case .northEast:      return "North-East India & Sikkim"
        case .central:        return "Central India"
        case .unionTerritory: return "Union Territory"
        case .subcontinent:   return "Subcontinent Neighbor"
        }
    }

    public var icon: String {
        switch self {
        case .western:        return "sun.horizon.fill"
        case .northern:       return "mountain.2.fill"
        case .southern:       return "leaf.fill"
        case .eastern:        return "water.waves"
        case .northEast:      return "cloud.sun.rain.fill"
        case .central:        return "building.columns.fill"
        case .unionTerritory: return "flag.fill"
        case .subcontinent:   return "globe.asia.australia.fill"
        }
    }
}

// MARK: - TravelStatus

public enum TravelStatus: Int, CaseIterable, Codable, Sendable {
    case wishlist   = 0
    case visited    = 1
    case livedHere  = 2

    public var title: String {
        switch self {
        case .wishlist:   return "Wishlist / Planned"
        case .visited:    return "Visited & Explored"
        case .livedHere:  return "Lived Here / Native"
        }
    }

    public var icon: String {
        switch self {
        case .wishlist:   return "mappin.and.ellipse"
        case .visited:    return "checkmark.seal.fill"
        case .livedHere:  return "house.fill"
        }
    }

    public var badgeColorHex: String {
        switch self {
        case .wishlist:   return "#38BDF8" // Sky blue
        case .visited:    return "#34D399" // Emerald green
        case .livedHere:  return "#FBBF24" // Amber gold
        }
    }
}

// MARK: - TravelRecord

/// Represents an Indian State, Union Territory, or Subcontinent destination in Pluto's Travel Odyssey.
@Model
final class TravelRecord {

    // Identity & Core Metadata
    var id:                  UUID   = UUID()
    var name:                String = ""
    var stateCode:           String = ""
    var capital:             String = ""
    var country:             String = "India"
    var zoneRaw:             Int    = TravelZone.western.rawValue
    var createdAt:           Date   = Date()
    var archivedAt:          Date?  = nil

    // Geographic Coordinates
    var latitude:            Double = 0.0
    var longitude:           Double = 0.0

    // Travel Exploration Status
    var statusRaw:           Int    = TravelStatus.visited.rawValue
    var dateVisited:         Date?  = nil
    var timesVisited:        Int    = 1
    var rating:              Int    = 5

    // Cities, Districts & Highlights
    var visitedCities:       [String] = []
    var topAttractions:      [String] = []
    var cuisineHighlights:   String = ""
    var bestSeason:          String = ""
    var officialLanguage:    String = ""

    // Travel Journal & Media
    var personalNotes:       String = ""
    var photoFileNames:      [String] = []

    // Security & Stamp Identifier
    var permitNumber:        String? = nil

    // MARK: - Computed Properties

    var zone: TravelZone {
        get { TravelZone(rawValue: zoneRaw) ?? .western }
        set { zoneRaw = newValue.rawValue }
    }

    var status: TravelStatus {
        get { TravelStatus(rawValue: statusRaw) ?? .visited }
        set { statusRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isVisited: Bool {
        status == .visited || status == .livedHere
    }

    var formattedCoordinates: String {
        let latDir = latitude >= 0 ? "N" : "S"
        let lonDir = longitude >= 0 ? "E" : "W"
        return String(format: "%.4f°%@, %.4f°%@", abs(latitude), latDir, abs(longitude), lonDir)
    }

    // MARK: - Initializer

    init(
        name: String,
        stateCode: String,
        capital: String,
        country: String = "India",
        zone: TravelZone,
        latitude: Double,
        longitude: Double,
        status: TravelStatus = .visited,
        dateVisited: Date? = nil,
        timesVisited: Int = 1,
        rating: Int = 5,
        visitedCities: [String] = [],
        topAttractions: [String] = [],
        cuisineHighlights: String = "",
        bestSeason: String = "",
        officialLanguage: String = "",
        personalNotes: String = "",
        photoFileNames: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.stateCode = stateCode
        self.capital = capital
        self.country = country
        self.zoneRaw = zone.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.statusRaw = status.rawValue
        self.dateVisited = dateVisited
        self.timesVisited = timesVisited
        self.rating = rating
        self.visitedCities = visitedCities
        self.topAttractions = topAttractions
        self.cuisineHighlights = cuisineHighlights
        self.bestSeason = bestSeason
        self.officialLanguage = officialLanguage
        self.personalNotes = personalNotes
        self.photoFileNames = photoFileNames
        self.createdAt = Date()
        self.permitNumber = "IND-EXP-\(stateCode)-\(Int.random(in: 1000...9999))"
    }
}
