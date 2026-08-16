import Foundation
import CoreLocation

// MARK: - MountainRangeMassif

public struct MountainRangeMassif: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let stateCode: String
    public let stateName: String
    public let regionCategory: String
    public let highestPeakName: String
    public let highestElevationMeters: Double
    public let centerLatitude: Double
    public let centerLongitude: Double
    public let rawCoordinates: [(Double, Double)]

    public var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    public var coordinates: [CLLocationCoordinate2D] {
        rawCoordinates.map { CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1) }
    }
}

// MARK: - MountainRangeBoundaryData

/// High-precision geographical boundary massifs for India's major mountain ranges,
/// trekking sanctuaries, and geological formations (Sahyadris, Aravallis, Himalayas, Western Ghats).
enum MountainRangeBoundaryData {

    /// Returns all registered mountain range massifs across India.
    static let allRanges: [MountainRangeMassif] = [

        // =====================================================================
        // 🦁 GUJARAT MOUNTAIN RANGES & HILL MASSIFS
        // =====================================================================

        MountainRangeMassif(
            id: "GJ_GIRNAR",
            name: "Girnar Sacred Massif & Mount Dattatreya",
            stateCode: "GJ",
            stateName: "Gujarat",
            regionCategory: "Saurashtra Volcanic Complex",
            highestPeakName: "Mount Girnar (Gorakhnath Peak)",
            highestElevationMeters: 1117,
            centerLatitude: 21.5273,
            centerLongitude: 70.5312,
            rawCoordinates: [
                (21.58, 70.47), (21.57, 70.53), (21.55, 70.58), (21.51, 70.60),
                (21.47, 70.56), (21.46, 70.50), (21.49, 70.45), (21.54, 70.44),
                (21.58, 70.47)
            ]
        ),

        MountainRangeMassif(
            id: "GJ_PAVAGADH",
            name: "Pavagadh & Champaner Hill Fortress",
            stateCode: "GJ",
            stateName: "Gujarat",
            regionCategory: "Panchmahal Volcanic Plug",
            highestPeakName: "Pavagadh Mahakali Peak",
            highestElevationMeters: 824,
            centerLatitude: 22.4633,
            centerLongitude: 73.5333,
            rawCoordinates: [
                (22.49, 73.50), (22.49, 73.56), (22.46, 73.57), (22.43, 73.55),
                (22.42, 73.50), (22.45, 73.48), (22.49, 73.50)
            ]
        ),

        MountainRangeMassif(
            id: "GJ_SAPUTARA",
            name: "Saputara & Dang Sahyadri Ridge",
            stateCode: "GJ",
            stateName: "Gujarat",
            regionCategory: "Northern Sahyadris Spur",
            highestPeakName: "Governor's Hill & Hatgadh Fort",
            highestElevationMeters: 1080,
            centerLatitude: 20.5750,
            centerLongitude: 73.7483,
            rawCoordinates: [
                (20.65, 73.68), (20.66, 73.78), (20.60, 73.83), (20.52, 73.80),
                (20.50, 73.72), (20.55, 73.66), (20.65, 73.68)
            ]
        ),

        MountainRangeMassif(
            id: "GJ_KALO_DUNGAR",
            name: "Kalo Dungar (Black Hill) & Kutch Ridge",
            stateCode: "GJ",
            stateName: "Gujarat",
            regionCategory: "Great Rann of Kutch Uplift",
            highestPeakName: "Kalo Dungar Dattatreya Summit",
            highestElevationMeters: 462,
            centerLatitude: 23.9272,
            centerLongitude: 69.7944,
            rawCoordinates: [
                (23.97, 69.72), (23.98, 69.86), (23.93, 69.90), (23.88, 69.83),
                (23.87, 69.74), (23.92, 69.69), (23.97, 69.72)
            ]
        ),

        MountainRangeMassif(
            id: "GJ_SHETRUNJAY",
            name: "Shetrunjay Sacred Hills & Palitana",
            stateCode: "GJ",
            stateName: "Gujarat",
            regionCategory: "Bhavnagar Saurashtra Hills",
            highestPeakName: "Shetrunjaya Adinath Summit",
            highestElevationMeters: 603,
            centerLatitude: 21.4900,
            centerLongitude: 71.8200,
            rawCoordinates: [
                (21.53, 71.77), (21.54, 71.86), (21.49, 71.88), (21.45, 71.84),
                (21.45, 71.77), (21.49, 71.75), (21.53, 71.77)
            ]
        ),

        // =====================================================================
        // 🏰 MAHARASHTRA SAHYADRI RANGES & FORTRESS MASSIFS
        // =====================================================================

        MountainRangeMassif(
            id: "MH_KALSUBAI_AMK",
            name: "Kalsubai & Harishchandragad Sanctuary",
            stateCode: "MH",
            stateName: "Maharashtra",
            regionCategory: "Western Ghats - Sahyadris",
            highestPeakName: "Kalsubai Peak (Everest of Maharashtra)",
            highestElevationMeters: 1646,
            centerLatitude: 19.6010,
            centerLongitude: 73.7110,
            rawCoordinates: [
                (19.72, 73.55), (19.75, 73.80), (19.65, 73.90), (19.45, 73.85),
                (19.35, 73.75), (19.38, 73.60), (19.55, 73.50), (19.72, 73.55)
            ]
        ),

        MountainRangeMassif(
            id: "MH_PUNE_LONAVALA",
            name: "Lonavala, Rajmachi & Khandala Ghats",
            stateCode: "MH",
            stateName: "Maharashtra",
            regionCategory: "Bhor Ghat Sahyadris",
            highestPeakName: "Rajmachi Shrivardhan Peak",
            highestElevationMeters: 1075,
            centerLatitude: 18.8280,
            centerLongitude: 73.3980,
            rawCoordinates: [
                (18.90, 73.30), (18.92, 73.48), (18.82, 73.52), (18.72, 73.48),
                (18.70, 73.35), (18.78, 73.28), (18.90, 73.30)
            ]
        ),

        MountainRangeMassif(
            id: "MH_TORNA_RAIGAD",
            name: "Torna, Rajgad & Raigad Fortress Range",
            stateCode: "MH",
            stateName: "Maharashtra",
            regionCategory: "Central Sahyadri Ridge",
            highestPeakName: "Torna Fort (Prachandagad)",
            highestElevationMeters: 1403,
            centerLatitude: 18.2760,
            centerLongitude: 73.6230,
            rawCoordinates: [
                (18.35, 73.35), (18.38, 73.72), (18.25, 73.78), (18.15, 73.65),
                (18.18, 73.40), (18.25, 73.30), (18.35, 73.35)
            ]
        ),

        MountainRangeMassif(
            id: "MH_MAHABALESHWAR",
            name: "Mahabaleshwar & Satara Tablelands",
            stateCode: "MH",
            stateName: "Maharashtra",
            regionCategory: "Southern Sahyadri Escarpment",
            highestPeakName: "Arthur's Seat & Wilson Point",
            highestElevationMeters: 1439,
            centerLatitude: 17.9237,
            centerLongitude: 73.6586,
            rawCoordinates: [
                (18.02, 73.55), (18.05, 73.75), (17.92, 73.82), (17.82, 73.75),
                (17.80, 73.58), (17.90, 73.50), (18.02, 73.55)
            ]
        ),

        // =====================================================================
        // 🏜️ RAJASTHAN ARAVALLI RANGE & MEWAR MASSIFS
        // =====================================================================

        MountainRangeMassif(
            id: "RJ_MOUNT_ABU",
            name: "Mount Abu Massif & Guru Shikhar",
            stateCode: "RJ",
            stateName: "Rajasthan",
            regionCategory: "Aravalli Range Apex",
            highestPeakName: "Guru Shikhar Summit",
            highestElevationMeters: 1722,
            centerLatitude: 24.6500,
            centerLongitude: 72.7800,
            rawCoordinates: [
                (24.72, 72.68), (24.75, 72.85), (24.62, 72.90), (24.52, 72.82),
                (24.52, 72.68), (24.62, 72.64), (24.72, 72.68)
            ]
        ),

        MountainRangeMassif(
            id: "RJ_KUMBHALGARH",
            name: "Kumbhalgarh & Mewar Fortress Ridge",
            stateCode: "RJ",
            stateName: "Rajasthan",
            regionCategory: "Southern Aravallis",
            highestPeakName: "Kumbhalgarh Badal Mahal Crest",
            highestElevationMeters: 1100,
            centerLatitude: 25.1500,
            centerLongitude: 73.5800,
            rawCoordinates: [
                (25.25, 73.48), (25.28, 73.68), (25.12, 73.72), (25.02, 73.62),
                (25.05, 73.45), (25.18, 73.42), (25.25, 73.48)
            ]
        ),

        // =====================================================================
        // 🏔️ HIMACHAL PRADESH & HIGH HIMALAYAS
        // =====================================================================

        MountainRangeMassif(
            id: "HP_DHAULADHAR",
            name: "Dhauladhar & Pir Panjal Range",
            stateCode: "HP",
            stateName: "Himachal Pradesh",
            regionCategory: "Middle Himalayas",
            highestPeakName: "Hanuman Tibba & Indrahar",
            highestElevationMeters: 5982,
            centerLatitude: 32.2500,
            centerLongitude: 76.3500,
            rawCoordinates: [
                (32.45, 76.10), (32.50, 76.60), (32.30, 76.75), (32.10, 76.50),
                (32.12, 76.18), (32.28, 76.05), (32.45, 76.10)
            ]
        ),

        MountainRangeMassif(
            id: "HP_SPITI_LAHAUL",
            name: "Spiti & Lahaul Trans-Himalayan Massif",
            stateCode: "HP",
            stateName: "Himachal Pradesh",
            regionCategory: "Trans-Himalayan High Desert",
            highestPeakName: "Mount Kanamo Peak",
            highestElevationMeters: 5974,
            centerLatitude: 32.2276,
            centerLongitude: 78.0340,
            rawCoordinates: [
                (32.60, 77.40), (32.65, 78.40), (32.00, 78.70), (31.70, 78.10),
                (31.80, 77.50), (32.20, 77.20), (32.60, 77.40)
            ]
        ),

        // =====================================================================
        // 🕉️ UTTARAKHAND GARHWAL & KUMAON MASSIFS
        // =====================================================================

        MountainRangeMassif(
            id: "UK_NANDA_DEVI",
            name: "Nanda Devi Biosphere & Garhwal Sanctuary",
            stateCode: "UK",
            stateName: "Uttarakhand",
            regionCategory: "Greater Himalayas",
            highestPeakName: "Nanda Devi Main Summit",
            highestElevationMeters: 7816,
            centerLatitude: 30.3753,
            centerLongitude: 79.9706,
            rawCoordinates: [
                (30.65, 79.50), (30.70, 80.40), (30.20, 80.50), (29.90, 80.10),
                (30.00, 79.40), (30.40, 79.30), (30.65, 79.50)
            ]
        ),

        MountainRangeMassif(
            id: "UK_KEDARKANTHA",
            name: "Tons Valley & Kedarkantha Ridge",
            stateCode: "UK",
            stateName: "Uttarakhand",
            regionCategory: "Garhwal Alpine Range",
            highestPeakName: "Kedarkantha Summit",
            highestElevationMeters: 3810,
            centerLatitude: 31.0230,
            centerLongitude: 78.1720,
            rawCoordinates: [
                (31.15, 78.05), (31.20, 78.30), (30.95, 78.35), (30.85, 78.20),
                (30.90, 78.02), (31.05, 77.98), (31.15, 78.05)
            ]
        ),

        // =====================================================================
        // ❄️ LADAKH & ZANSKAR RANGE
        // =====================================================================

        MountainRangeMassif(
            id: "LA_ZANSKAR_STOK",
            name: "Ladakh Range & Stok Kangri Massif",
            stateCode: "LA",
            stateName: "Ladakh",
            regionCategory: "Trans-Himalayan Glacial Ridge",
            highestPeakName: "Stok Kangri Summit",
            highestElevationMeters: 6153,
            centerLatitude: 33.9850,
            centerLongitude: 77.4430,
            rawCoordinates: [
                (34.25, 77.10), (34.30, 77.80), (33.85, 78.00), (33.65, 77.60),
                (33.70, 77.10), (34.00, 76.90), (34.25, 77.10)
            ]
        ),

        // =====================================================================
        // 🏔️ SIKKIM KANGCHENJUNGA MASSIVE
        // =====================================================================

        MountainRangeMassif(
            id: "SK_KANGCHENJUNGA",
            name: "Kangchenjunga & Goechala Sanctuary",
            stateCode: "SK",
            stateName: "Sikkim",
            regionCategory: "Eastern Himalayas",
            highestPeakName: "Kangchenjunga (3rd Highest on Earth)",
            highestElevationMeters: 8586,
            centerLatitude: 27.7025,
            centerLongitude: 88.1475,
            rawCoordinates: [
                (27.85, 88.00), (27.90, 88.35), (27.55, 88.40), (27.40, 88.20),
                (27.45, 88.00), (27.65, 87.95), (27.85, 88.00)
            ]
        ),

        // =====================================================================
        // 🌴 SOUTH INDIA / WESTERN GHATS MASSIFS
        // =====================================================================

        MountainRangeMassif(
            id: "KL_ANAMUDI",
            name: "Anamudi & Munnar High Ranges",
            stateCode: "KL",
            stateName: "Kerala",
            regionCategory: "Western Ghats - Southern Ridge",
            highestPeakName: "Anamudi Peak (Highest in South India)",
            highestElevationMeters: 2695,
            centerLatitude: 10.1700,
            centerLongitude: 77.0600,
            rawCoordinates: [
                (10.30, 76.95), (10.32, 77.18), (10.10, 77.20), (10.00, 77.10),
                (10.02, 76.92), (10.18, 76.88), (10.30, 76.95)
            ]
        ),

        MountainRangeMassif(
            id: "KA_KUDREMUKH",
            name: "Kudremukh & Chikmagalur Ridge",
            stateCode: "KA",
            stateName: "Karnataka",
            regionCategory: "Western Ghats - Karavali Spur",
            highestPeakName: "Mullayanagiri & Kudremukh Peak",
            highestElevationMeters: 1930,
            centerLatitude: 13.2200,
            centerLongitude: 75.2500,
            rawCoordinates: [
                (13.45, 75.10), (13.50, 75.50), (13.20, 75.60), (13.05, 75.40),
                (13.08, 75.15), (13.25, 75.05), (13.45, 75.10)
            ]
        )
    ]

    /// Returns the massif matching the given state or ID.
    static func massifs(for stateCode: String) -> [MountainRangeMassif] {
        allRanges.filter { $0.stateCode.uppercased() == stateCode.uppercased() }
    }
}
