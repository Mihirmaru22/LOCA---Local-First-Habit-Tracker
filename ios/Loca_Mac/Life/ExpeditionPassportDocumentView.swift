import SwiftUI
import AppKit
import CoreLocation

// MARK: - ExpeditionPassportDocumentView

/// Diplomatic-grade, high-prestige Archival Alpine Expedition Passport & Summit Dossier.
/// Designed according to sovereign state registry and diplomatic treaty standards (Swiss Alpine Club,
/// Himalayan Database, and Ministry of Geological Survey expedition credentials).
/// Features a luminous warm ivory/linen parchment foundation, intaglio security borders,
/// authentic vermilion state registry seals, cartographic topographic isohypse maps, and ICAO MRZ.
struct ExpeditionPassportDocumentView: View {

    let trek: TrekRecord

    private var isConquered: Bool {
        trek.status == .conquered
    }

    private var permitNumber: String {
        let code = abs(trek.id.hashValue) % 1_000_000
        return String(format: "EXP-%06d", code)
    }

    private var recordYear: String {
        let date = trek.dateConquered ?? trek.createdAt
        return date.formatted(.dateTime.year())
    }

    private var formattedRecordDate: String {
        let date = trek.dateConquered ?? trek.createdAt
        return date.formatted(.dateTime.day(.twoDigits).month(.wide).year())
    }

    private var verificationHash: String {
        let raw = "\(trek.name)-\(trek.elevationMeters)-\(permitNumber)-\(recordYear)"
        let hash = abs(raw.hashValue)
        return String(format: "IMF-%04X-%04X-%04X", (hash >> 16) & 0xFFFF, (hash >> 8) & 0xFFFF, hash & 0xFFFF)
    }

    private var mrzCodeLine1: String {
        let cleanName = trek.name.uppercased().replacingOccurrences(of: " ", with: "<")
        let paddedName = cleanName.padding(toLength: 30, withPad: "<", startingAt: 0)
        return "P<INDMARU<<MIHIR<<<<<<<<<\(paddedName.prefix(14))"
    }

    private var mrzCodeLine2: String {
        let elevCode = String(format: "%04d", Int(trek.elevationMeters) % 10000)
        let cleanTrek = trek.name.uppercased().replacingOccurrences(of: " ", with: "").prefix(12)
        return "\(permitNumber.replacingOccurrences(of: "-", with: ""))\(elevCode)IND2608167M<<<<<\(cleanTrek)<<06"
    }

    // High-Prestige Diplomatic Parchment Palette
    private let parchmentLight   = Color(red: 0.98, green: 0.97, blue: 0.95) // Warm Archival Ivory Linen
    private let parchmentDark    = Color(red: 0.94, green: 0.92, blue: 0.88) // Aged Vellum Base
    private let parchmentCard    = Color(red: 0.96, green: 0.95, blue: 0.92) // Recessed Card Parchment
    private let inkPrimary       = Color(red: 0.10, green: 0.12, blue: 0.16) // Deep Archival Carbon Ink
    private let inkSecondary     = Color(red: 0.28, green: 0.32, blue: 0.40) // Muted Slate Ink
    private let inkTertiary      = Color(red: 0.50, green: 0.54, blue: 0.62) // Technical Annotation Text
    private let diplomaticGold   = Color(red: 0.68, green: 0.54, blue: 0.32) // Intaglio Gold / Bronze
    private let diplomaticNavy   = Color(red: 0.12, green: 0.18, blue: 0.28) // Oxford Diplomatic Navy
    private let borderEngraved   = Color(red: 0.68, green: 0.54, blue: 0.32).opacity(0.35) // Engraved Hairline
    private let sealCrimson      = Color(red: 0.62, green: 0.14, blue: 0.14) // Authentic Inked State Wax Red
    private let statusGreen      = Color(red: 0.11, green: 0.42, blue: 0.24) // Diplomatic Forest Emerald

    // Waypoint Data Model
    private struct RouteStage: Identifiable {
        let id = UUID()
        let code: String
        let name: String
        let altitudeMeters: Int
        let distKm: Double
        let terrain: String
    }

    private var routeWaypoints: [RouteStage] {
        let elev = Int(trek.elevationMeters)
        let nameLower = trek.name.lowercased()

        if nameLower.contains("everest") {
            return [
                RouteStage(code: "BC", name: "Everest Base Camp", altitudeMeters: 5364, distKm: 0.0, terrain: "Khumbu Moraine"),
                RouteStage(code: "C1", name: "Khumbu Icefall", altitudeMeters: 6065, distKm: 3.4, terrain: "Glacial Seracs"),
                RouteStage(code: "C2", name: "Western Cwm", altitudeMeters: 6400, distKm: 6.8, terrain: "Glacial Valley"),
                RouteStage(code: "C3", name: "Lhotse Face", altitudeMeters: 7200, distKm: 10.2, terrain: "Blue Ice Wall"),
                RouteStage(code: "C4", name: "South Col", altitudeMeters: 7920, distKm: 12.5, terrain: "Death Zone Entry"),
                RouteStage(code: "▲", name: "Everest Summit", altitudeMeters: 8848, distKm: 14.8, terrain: "Hillary Step / Ridge")
            ]
        } else if nameLower.contains("kanchenjunga") {
            return [
                RouteStage(code: "BC", name: "Pangpema Base", altitudeMeters: 5140, distKm: 0.0, terrain: "Alpine Moraine"),
                RouteStage(code: "C1", name: "Lower Glacier", altitudeMeters: 6200, distKm: 4.0, terrain: "Ice Labyrinth"),
                RouteStage(code: "C2", name: "The Great Shelf", altitudeMeters: 7000, distKm: 7.5, terrain: "Upper Plateau"),
                RouteStage(code: "C3", name: "Upper Basin", altitudeMeters: 7600, distKm: 10.8, terrain: "Snow Couloir"),
                RouteStage(code: "C4", name: "West Col", altitudeMeters: 8200, distKm: 13.2, terrain: "Death Zone Ridge"),
                RouteStage(code: "▲", name: "Summit Apex", altitudeMeters: 8586, distKm: 15.0, terrain: "Summit Snowfield")
            ]
        } else if nameLower.contains("nanda devi") {
            return [
                RouteStage(code: "BC", name: "Lata Kharak", altitudeMeters: 3850, distKm: 0.0, terrain: "Birch Ridge"),
                RouteStage(code: "C1", name: "Dharansi Pass", altitudeMeters: 4250, distKm: 4.2, terrain: "Granite Col"),
                RouteStage(code: "C2", name: "Dibrugheta", altitudeMeters: 3500, distKm: 7.8, terrain: "Rishi Gorge"),
                RouteStage(code: "C3", name: "Deodi Base", altitudeMeters: 4800, distKm: 11.0, terrain: "Sanctuary Wall"),
                RouteStage(code: "C4", name: "Outer Ridge", altitudeMeters: 6200, distKm: 13.5, terrain: "South Buttress"),
                RouteStage(code: "▲", name: "Nanda Devi", altitudeMeters: 7816, distKm: 16.0, terrain: "Summit Cornice")
            ]
        } else if nameLower.contains("annapurna") {
            return [
                RouteStage(code: "BC", name: "Annapurna BC", altitudeMeters: 4130, distKm: 0.0, terrain: "Glacial Basin"),
                RouteStage(code: "C1", name: "North Moraine", altitudeMeters: 5100, distKm: 3.4, terrain: "Icefall Shelf"),
                RouteStage(code: "C2", name: "Sickle Glacier", altitudeMeters: 5700, distKm: 6.8, terrain: "Serac Wall"),
                RouteStage(code: "C3", name: "Ice Barrier", altitudeMeters: 6500, distKm: 9.6, terrain: "Steep Snowfield"),
                RouteStage(code: "C4", name: "Upper Couloir", altitudeMeters: 7400, distKm: 12.1, terrain: "High Avalanche Col"),
                RouteStage(code: "▲", name: "Annapurna I", altitudeMeters: 8091, distKm: 14.5, terrain: "Summit Ridge")
            ]
        } else {
            let baseElev = Int(Double(elev) * 0.55)
            let c1Elev = Int(Double(elev) * 0.68)
            let c2Elev = Int(Double(elev) * 0.78)
            let c3Elev = Int(Double(elev) * 0.88)
            let c4Elev = Int(Double(elev) * 0.94)

            return [
                RouteStage(code: "BC", name: "Trailhead Base", altitudeMeters: baseElev, distKm: 0.0, terrain: "Valley Moraine"),
                RouteStage(code: "C1", name: "Camp I (Glacier)", altitudeMeters: c1Elev, distKm: 3.8, terrain: "Lower Glacier"),
                RouteStage(code: "C2", name: "Camp II (Plateau)", altitudeMeters: c2Elev, distKm: 7.2, terrain: "Snow Shelf"),
                RouteStage(code: "C3", name: "Camp III (Col)", altitudeMeters: c3Elev, distKm: 10.5, terrain: "Ice Wall"),
                RouteStage(code: "C4", name: "High Camp", altitudeMeters: c4Elev, distKm: 13.0, terrain: "High Ridge"),
                RouteStage(code: "▲", name: "\(trek.name) Summit", altitudeMeters: elev, distKm: 15.2, terrain: "Summit Crest")
            ]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 11) {

                // 1. Diplomatic Header & Sovereign Authority Insignia
                officialHeaderSection

                Divider().overlay(borderEngraved)

                // 2. Bearer & Summit Geodetic Dossier
                climberDossierSection

                // 3. Technical Topographical Telemetry Grid
                telemetryGridSection

                // 4. Cartographic Topographical Map & State Seal
                topographicMapAndSealSection

                // 5. Waypoints & Route Trajectory Breakdown
                waypointTrajectorySection

                // 6. Official Expedition Field Notes & Ledger
                fieldNotesSection

                Spacer(minLength: 2)

                Divider().overlay(borderEngraved)

                // 7. Attestation & Digital Verification Signatures
                attestationSection

                // 8. Standard Diplomatic Machine Readable Zone (MRZ)
                machineReadableZoneSection
            }
            .padding(24)
        }
        .frame(width: 600, height: 840)
        .background(
            ZStack {
                // High-End Archival Linen Parchment Gradient
                LinearGradient(
                    colors: [parchmentLight, parchmentDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Intaglio Security Guilloché Watermark Pattern
                Canvas { context, size in
                    var path = Path()
                    let step: CGFloat = 18
                    for y in stride(from: CGFloat(0), to: size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addCurve(
                            to: CGPoint(x: size.width, y: y + 6),
                            control1: CGPoint(x: size.width * 0.35, y: y - 10),
                            control2: CGPoint(x: size.width * 0.65, y: y + 14)
                        )
                    }
                    context.stroke(path, with: .color(diplomaticGold.opacity(0.06)), lineWidth: 0.75)
                }

                // Subtle Center Diplomatic Watermark Insignia
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 230))
                    .foregroundStyle(diplomaticGold.opacity(0.035))
            }
        )
        .overlay(
            // Diplomatic Intaglio Dual Security Border
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(diplomaticNavy, lineWidth: 1.4)
                    .padding(6)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(borderEngraved, lineWidth: 0.8)
                    .padding(10)

                // Precision Corner Registration Reticles
                cornerReticle(alignment: .topLeading)
                cornerReticle(alignment: .topTrailing)
                cornerReticle(alignment: .bottomLeading)
                cornerReticle(alignment: .bottomTrailing)
            }
        )
    }

    private func cornerReticle(alignment: Alignment) -> some View {
        VStack {
            if alignment == .bottomLeading || alignment == .bottomTrailing { Spacer() }
            HStack {
                if alignment == .topTrailing || alignment == .bottomTrailing { Spacer() }
                Rectangle()
                    .fill(diplomaticGold.opacity(0.6))
                    .frame(width: 10, height: 1.5)
                if alignment == .topLeading || alignment == .bottomLeading { Spacer() }
            }
            if alignment == .topLeading || alignment == .topTrailing { Spacer() }
        }
        .padding(14)
    }

    // MARK: - 1. Official Header Section
    private var officialHeaderSection: some View {
        HStack(alignment: .center) {
            // Diplomatic Emblem & High Authority Title
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(diplomaticGold, lineWidth: 1.2)
                        .frame(width: 36, height: 36)

                    Circle()
                        .fill(diplomaticNavy.opacity(0.06))
                        .frame(width: 32, height: 32)

                    Image(systemName: "laurel.leading")
                        .font(.system(size: 16))
                        .foregroundStyle(diplomaticGold)
                        .offset(x: -6)

                    Image(systemName: "laurel.trailing")
                        .font(.system(size: 16))
                        .foregroundStyle(diplomaticGold)
                        .offset(x: 6)

                    Image(systemName: "compass.drawing")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(diplomaticNavy)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("REPUBLIC OF INDIA · HIMALAYAN EXPEDITION REGISTRY")
                        .font(.system(size: 10, weight: .black, design: .serif))
                        .foregroundStyle(diplomaticNavy)
                        .tracking(1.4)

                    Text("OFFICIAL DIPLOMATIC SUMMIT DOSSIER · ACTE OFFICIEL D'EXPÉDITION")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(diplomaticGold)
                        .tracking(0.8)
                }
            }

            Spacer()

            // State Tracking & Series
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("SERIES:")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(inkTertiary)
                    Text("2026/IND-WGS84")
                        .font(.system(size: 7, weight: .black, design: .monospaced))
                        .foregroundStyle(diplomaticGold)
                }

                Text("PERMIT NO: \(permitNumber)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(diplomaticNavy)
            }
        }
    }

    // MARK: - 2. Climber & Ascent Geodetic Dossier
    private var climberDossierSection: some View {
        HStack(alignment: .top, spacing: 14) {
            // Photo Mount
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 96, height: 102)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(diplomaticNavy.opacity(0.3), lineWidth: 1)
                        )

                    if let firstPhoto = trek.photoFileNames.first,
                       let img = TrekMediaManager.shared.loadPhoto(fileName: firstPhoto) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 98)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "person.crop.artframe")
                                .font(.system(size: 30))
                                .foregroundStyle(diplomaticNavy.opacity(0.4))
                            Text("PASSPORT PHOTO")
                                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(inkTertiary)
                        }
                    }
                }

                Text("BIOMETRIC IDENTIFICATION")
                    .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }

            // Official Data Fields
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 16) {
                    officialDataField(label: "SURNAME / NOM", value: "MARU")
                    officialDataField(label: "GIVEN NAMES / PRÉNOMS", value: "MIHIR")
                }

                HStack(spacing: 16) {
                    officialDataField(label: "NATIONALITY / NATIONALITÉ", value: "REPUBLIC OF INDIA (IND)")
                    officialDataField(
                        label: "RATIFICATION STATUS",
                        value: isConquered ? "RATIFIED SUMMIT ASCENT" : "REGISTERED EXPEDITION",
                        highlight: isConquered
                    )
                }

                officialDataField(label: "TARGET SUMMIT & MASSIF", value: "\(trek.name.uppercased()) · \(trek.region.uppercased())")

                HStack(spacing: 16) {
                    officialDataField(label: "GEODETIC POSITION", value: "\(trek.coordinatesString) (WGS84)")
                    officialDataField(label: "DATE OF REGISTRATION", value: formattedRecordDate)
                }
            }
        }
        .padding(9)
        .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderEngraved, lineWidth: 0.8))
    }

    private func officialDataField(label: String, value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                .foregroundStyle(diplomaticGold)
                .tracking(0.5)

            if highlight {
                Text(value)
                    .font(.system(size: 9.5, weight: .black, design: .serif))
                    .foregroundStyle(statusGreen)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(statusGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 2))
            } else {
                Text(value)
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundStyle(inkPrimary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 3. Topographical Telemetry Grid
    private var telemetryGridSection: some View {
        HStack(spacing: 8) {
            telemetryBox(
                title: "PEAK ALTITUDE",
                primary: "\(Int(trek.elevationMeters).formatted()) m",
                secondary: "\(Int(trek.elevationFeet).formatted()) ft ASL"
            )

            telemetryBox(
                title: "VERTICAL ASCENT",
                primary: trek.elevationGainMeters != nil ? "+\(Int(trek.elevationGainMeters!).formatted()) m" : "—",
                secondary: "Cumulative Gain"
            )

            telemetryBox(
                title: "TRAIL CORRIDOR",
                primary: trek.trailDistanceKm != nil ? String(format: "%.1f km", trek.trailDistanceKm!) : "—",
                secondary: "Basecamp ➔ Peak"
            )

            telemetryBox(
                title: "ALPINE RATING",
                primary: trek.difficulty.title.uppercased(),
                secondary: "UIAA Standard"
            )
        }
    }

    private func telemetryBox(title: String, primary: String, secondary: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                .foregroundStyle(diplomaticNavy.opacity(0.8))
                .tracking(0.6)

            Text(primary)
                .font(.system(size: 12.5, weight: .black, design: .monospaced))
                .foregroundStyle(inkPrimary)

            Text(secondary)
                .font(.system(size: 6.5, weight: .semibold))
                .foregroundStyle(inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(borderEngraved, lineWidth: 0.7))
    }

    // MARK: - 4. Cartographic Topographic Map & State Seal Section
    private var topographicMapAndSealSection: some View {
        HStack(spacing: 12) {
            // Left: Imperial Inked State Wax Registry Seal
            ZStack {
                Circle()
                    .strokeBorder(isConquered ? sealCrimson : diplomaticNavy, lineWidth: 1.6)
                    .frame(width: 84, height: 84)

                Circle()
                    .strokeBorder(isConquered ? sealCrimson.opacity(0.6) : diplomaticNavy.opacity(0.5), lineWidth: 0.8)
                    .frame(width: 74, height: 74)

                VStack(spacing: 1) {
                    Text("★ STATE SURVEY ★")
                        .font(.system(size: 5, weight: .black, design: .monospaced))
                        .foregroundStyle(isConquered ? sealCrimson : diplomaticNavy)
                        .tracking(0.6)

                    Image(systemName: isConquered ? "seal.fill" : "mountain.2.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(isConquered ? sealCrimson : diplomaticNavy)

                    Text(isConquered ? "SUMMIT RATIFIED" : "PERMIT GRANTED")
                        .font(.system(size: 6.5, weight: .black, design: .serif))
                        .foregroundStyle(isConquered ? sealCrimson : diplomaticNavy)
                        .tracking(0.4)

                    Text("EXP #\(String(permitNumber.suffix(6)))")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isConquered ? sealCrimson : diplomaticNavy)

                    Text(recordYear)
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isConquered ? sealCrimson.opacity(0.8) : diplomaticNavy.opacity(0.8))
                }
            }

            // Right: Rich Cartographic Topographical Map (On Clean Cream Vellum)
            VStack(alignment: .leading, spacing: 3) {
                // Header with Coordinates & Datum
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(diplomaticNavy)

                        Text("CARTOGRAPHIC SURVEY & ASCENT TOPOGRAPHY")
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(diplomaticNavy)
                    }

                    Spacer()

                    Text("UTM 45N · WGS84 DATUM")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(inkTertiary)
                }

                // Map Canvas with Topographic Contour Isohypses & Marked Route
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.75))
                        .frame(height: 72)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(borderEngraved, lineWidth: 0.8))

                    // Coordinate Grid Lines & Topographic Isohypses
                    Canvas { context, size in
                        let w = size.width
                        let h = size.height

                        // Grid lines
                        var grid = Path()
                        grid.move(to: CGPoint(x: w * 0.25, y: 0))
                        grid.addLine(to: CGPoint(x: w * 0.25, y: h))
                        grid.move(to: CGPoint(x: w * 0.5, y: 0))
                        grid.addLine(to: CGPoint(x: w * 0.5, y: h))
                        grid.move(to: CGPoint(x: w * 0.75, y: 0))
                        grid.addLine(to: CGPoint(x: w * 0.75, y: h))

                        grid.move(to: CGPoint(x: 0, y: h * 0.33))
                        grid.addLine(to: CGPoint(x: w, y: h * 0.33))
                        grid.move(to: CGPoint(x: 0, y: h * 0.66))
                        grid.addLine(to: CGPoint(x: w, y: h * 0.66))

                        context.stroke(grid, with: .color(diplomaticNavy.opacity(0.08)), lineWidth: 0.5)

                        // Topographical Elevation Contour Isohypses (5 nested concentric rings)
                        let center = CGPoint(x: w * 0.82, y: h * 0.28)
                        let rings: [(rx: CGFloat, ry: CGFloat)] = [
                            (120, 48),
                            (95, 38),
                            (70, 28),
                            (45, 18),
                            (22, 10)
                        ]

                        for (i, ring) in rings.enumerated() {
                            var contour = Path()
                            contour.addEllipse(in: CGRect(
                                x: center.x - ring.rx,
                                y: center.y - ring.ry,
                                width: ring.rx * 2,
                                height: ring.ry * 2
                            ))
                            let alpha = 0.15 + Double(i) * 0.08
                            context.stroke(contour, with: .color(Color(red: 0.45, green: 0.52, blue: 0.62).opacity(alpha)), lineWidth: 0.75)
                        }

                        // Topo Ridge Lines (Subtle dashed ridges)
                        var ridge1 = Path()
                        ridge1.move(to: center)
                        ridge1.addLine(to: CGPoint(x: w * 0.98, y: h * 0.8))
                        context.stroke(ridge1, with: .color(diplomaticNavy.opacity(0.18)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))

                        var ridge2 = Path()
                        ridge2.move(to: center)
                        ridge2.addLine(to: CGPoint(x: w * 0.6, y: h * 0.05))
                        context.stroke(ridge2, with: .color(diplomaticNavy.opacity(0.18)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))

                        // Technical Ascent Route Line (from Basecamp to Summit)
                        var route = Path()
                        route.move(to: CGPoint(x: w * 0.08, y: h * 0.82))
                        route.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.68), control1: CGPoint(x: w * 0.15, y: h * 0.80), control2: CGPoint(x: w * 0.22, y: h * 0.72))
                        route.addCurve(to: CGPoint(x: w * 0.48, y: h * 0.52), control1: CGPoint(x: w * 0.35, y: h * 0.62), control2: CGPoint(x: w * 0.42, y: h * 0.56))
                        route.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.38), control1: CGPoint(x: w * 0.54, y: h * 0.48), control2: CGPoint(x: w * 0.60, y: h * 0.42))
                        route.addCurve(to: center, control1: CGPoint(x: w * 0.72, y: h * 0.32), control2: CGPoint(x: w * 0.78, y: h * 0.28))

                        context.stroke(route, with: .color(diplomaticNavy), style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    }
                    .frame(height: 72)

                    // Waypoint Pins & Geographical Labels Overlaid on Map
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height

                        // North Compass Arrow
                        HStack(spacing: 2) {
                            Image(systemName: "location.north.line.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(diplomaticNavy)
                            Text("N")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundStyle(diplomaticNavy)
                        }
                        .position(x: 16, y: 12)

                        // Contour Altitude Labels
                        Text("5,000m")
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(inkTertiary)
                            .position(x: w * 0.48, y: h * 0.88)

                        Text("7,500m (Death Zone)")
                            .font(.system(size: 5.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(sealCrimson)
                            .position(x: w * 0.68, y: h * 0.16)

                        // Waypoint Pin 1: Base Camp
                        mapWaypointPin(label: "BC (5.3k)", isApex: false)
                            .position(x: w * 0.08, y: h * 0.82)

                        // Waypoint Pin 2: Camp II
                        mapWaypointPin(label: "C2 (6.4k)", isApex: false)
                            .position(x: w * 0.48, y: h * 0.52)

                        // Waypoint Pin 3: South Col
                        mapWaypointPin(label: "C4 (7.9k)", isApex: false)
                            .position(x: w * 0.65, y: h * 0.38)

                        // Waypoint Apex: Summit Peak
                        mapWaypointPin(label: "▲ SUMMIT (\(Int(trek.elevationMeters))m)", isApex: true)
                            .position(x: w * 0.82, y: h * 0.28)
                    }
                    .frame(height: 72)
                }
            }
            .padding(6)
            .background(Color.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderEngraved, lineWidth: 0.6))
        }
    }

    private func mapWaypointPin(label: String, isApex: Bool) -> some View {
        VStack(spacing: 1) {
            if isApex {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(diplomaticGold)
                Text(label)
                    .font(.system(size: 6, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(diplomaticNavy, in: RoundedRectangle(cornerRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(diplomaticGold, lineWidth: 0.6))
            } else {
                Circle()
                    .fill(diplomaticNavy)
                    .frame(width: 4, height: 4)
                Text(label)
                    .font(.system(size: 5, weight: .bold, design: .monospaced))
                    .foregroundStyle(diplomaticNavy)
                    .padding(.horizontal, 2)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(diplomaticNavy.opacity(0.4), lineWidth: 0.4))
            }
        }
    }

    // MARK: - 5. Waypoints & Route Trajectory Breakdown
    private var waypointTrajectorySection: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("ASCENT WAYPOINTS & CORRIDOR PROFILE")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(diplomaticNavy)
                    .tracking(0.5)

                Spacer()

                Text("6-STAGE EXPEDITION PROFILE")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }

            // 6-Waypoint Step Grid
            HStack(spacing: 4) {
                ForEach(routeWaypoints) { stage in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Text(stage.code)
                                .font(.system(size: 6.5, weight: .black, design: .monospaced))
                                .foregroundStyle(stage.code == "▲" ? statusGreen : diplomaticNavy)
                            Spacer()
                            Text("\(stage.altitudeMeters)m")
                                .font(.system(size: 6.5, weight: .black, design: .monospaced))
                                .foregroundStyle(inkPrimary)
                        }

                        Text(stage.name)
                            .font(.system(size: 6.5, weight: .bold))
                            .foregroundStyle(inkPrimary)
                            .lineLimit(1)

                        HStack {
                            Text("\(String(format: "%.1f", stage.distKm)) km")
                                .font(.system(size: 5.5, weight: .semibold, design: .monospaced))
                                .foregroundStyle(inkTertiary)
                            Spacer()
                            Text(stage.terrain)
                                .font(.system(size: 5, weight: .semibold))
                                .foregroundStyle(diplomaticGold)
                                .lineLimit(1)
                        }
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(borderEngraved, lineWidth: 0.6))
                }
            }
        }
    }

    // MARK: - 6. Official Expedition Field Notes
    private var fieldNotesSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("FIELD LOGBOOK OBSERVATIONS & GEOLOGICAL NARRATIVE")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(diplomaticNavy)
                    .tracking(0.5)
            }

            Text(trek.personalNotes.isEmpty ? "High-altitude summit waypoint logged under verified atmospheric conditions. Preserved in the Sovereign Alpine Register." : trek.personalNotes)
                .font(.system(size: 8.5, weight: .regular, design: .serif))
                .foregroundStyle(inkPrimary)
                .lineSpacing(1.5)
                .lineLimit(2)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(borderEngraved, lineWidth: 0.6))
        }
    }

    // MARK: - 7. Attestation & Digital Verification
    private var attestationSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("REGISTRY ATTESTATION & FINGERPRINT")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(diplomaticNavy)
                    .tracking(0.5)

                Text("HASH: \(verificationHash)")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(inkTertiary)

                Text("OFFICIALLY RATIFIED BY PLUTO EXPEDITION LEDGER")
                    .font(.system(size: 5.5, weight: .semibold))
                    .foregroundStyle(inkTertiary.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("Mihir Maru")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(diplomaticNavy)

                Text("EXPEDITION LEADER & CHIEF SURVEYOR")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundStyle(diplomaticGold)
                    .tracking(0.6)
            }
        }
    }

    // MARK: - 8. Diplomatic Machine Readable Zone (MRZ Standard ICAO 9303)
    private var machineReadableZoneSection: some View {
        VStack(alignment: .leading, spacing: 1.5) {
            Text(mrzCodeLine1)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(inkPrimary)
                .tracking(1.8)

            Text(mrzCodeLine2)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(inkPrimary)
                .tracking(1.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(diplomaticNavy.opacity(0.2), lineWidth: 0.6))
    }
}
