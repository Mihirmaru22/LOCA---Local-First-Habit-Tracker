import SwiftUI
import AppKit
import CoreLocation

// MARK: - ExpeditionPassportDocumentView

/// Authentic, prestigious archival-grade Alpine Expedition Passport & Summit Dossier.
/// Designed according to diplomatic mountaineering registry standards (Swiss Alpine Club,
/// Himalayan Database, and Survey of India expedition certification).
/// Features a rich Topographic Elevation Contour Map with genuine geological waypoints,
/// geodetic coordinates, hypsometric cross-sections, and archival attestation.
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

    // Document Palette (Archival Slate, Warm Antique Bronze, Bone White)
    private let bronzeAccent    = Color(red: 0.78, green: 0.66, blue: 0.48) // Metallic Champagne Bronze
    private let bronzeMuted     = Color(red: 0.55, green: 0.47, blue: 0.35)
    private let parchmentBone   = Color(red: 0.92, green: 0.93, blue: 0.95) // Crisp Ivory/Bone
    private let borderSubtle    = Color(red: 0.78, green: 0.66, blue: 0.48).opacity(0.25)
    private let sealCrimson     = Color(red: 0.68, green: 0.20, blue: 0.20) // Archival Stamp Inked Crimson

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
            // Dynamically scale authentic waypoints based on peak elevation
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

                // 1. Diplomatic Header & Alpine Authority Registry
                officialHeaderSection

                Divider().overlay(borderSubtle)

                // 2. Bearer & Summit Geodetic Dossier (Photo + Data Grid)
                climberDossierSection

                // 3. Technical Topographical Telemetry Grid
                telemetryGridSection

                // 4. Rich Topographic Contour Map & Archival Stamp
                topographicMapAndSealSection

                // 5. Waypoints & Route Trajectory Breakdown
                waypointTrajectorySection

                // 6. Official Expedition Field Notes & Ledger
                fieldNotesSection

                Spacer(minLength: 2)

                Divider().overlay(borderSubtle)

                // 7. Attestation & Digital Verification Signatures
                attestationSection

                // 8. ICAO Standard Machine Readable Zone (MRZ)
                machineReadableZoneSection
            }
            .padding(24)
        }
        .frame(width: 600, height: 840)
        .background(
            ZStack {
                // Deep Matte Archival Vellum Background
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.09, blue: 0.13),
                        Color(red: 0.04, green: 0.05, blue: 0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Precision Topographic Contour Lines Watermark
                Canvas { context, size in
                    var path = Path()
                    let step: CGFloat = 20
                    for y in stride(from: CGFloat(0), to: size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addCurve(
                            to: CGPoint(x: size.width, y: y + 6),
                            control1: CGPoint(x: size.width * 0.3, y: y - 10),
                            control2: CGPoint(x: size.width * 0.7, y: y + 16)
                        )
                    }
                    context.stroke(path, with: .color(bronzeAccent.opacity(0.025)), lineWidth: 0.75)
                }

                // Subtle Center Watermark Crest
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 220))
                    .foregroundStyle(bronzeAccent.opacity(0.015))
            }
        )
        .overlay(
            // Archival Dual Hairline Border with Corner Framing Marks
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderSubtle, lineWidth: 1.2)
                    .padding(8)

                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderSubtle.opacity(0.5), lineWidth: 0.6)
                    .padding(13)

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
                    .fill(bronzeAccent.opacity(0.4))
                    .frame(width: 10, height: 1.5)
                if alignment == .topLeading || alignment == .bottomLeading { Spacer() }
            }
            if alignment == .topLeading || alignment == .topTrailing { Spacer() }
        }
        .padding(18)
    }

    // MARK: - 1. Official Header Section
    private var officialHeaderSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(bronzeAccent.opacity(0.5), lineWidth: 1)
                        .frame(width: 34, height: 34)

                    Image(systemName: "compass.drawing")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(bronzeAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("HIMALAYAN & ALPINE EXPEDITION REGISTER")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundStyle(parchmentBone)
                        .tracking(1.4)

                    Text("OFFICIAL HIGH-ALTITUDE SUMMIT DOSSIER · DIPLOMATIC CLIMBING RECORD")
                        .font(.system(size: 6.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(bronzeAccent)
                        .tracking(0.6)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("REGISTRY CODE:")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("IND / WGS84")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(bronzeAccent)
                }

                Text("PERMIT NO: \(permitNumber)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(parchmentBone)
            }
        }
    }

    // MARK: - 2. Climber & Ascent Geodetic Dossier
    private var climberDossierSection: some View {
        HStack(alignment: .top, spacing: 14) {
            // Climber Photo Frame
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 96, height: 102)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(borderSubtle, lineWidth: 1)
                        )

                    if let firstPhoto = trek.photoFileNames.first,
                       let img = TrekMediaManager.shared.loadPhoto(fileName: firstPhoto) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 94, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 28))
                                .foregroundStyle(bronzeAccent.opacity(0.45))
                            Text("SUMMIT PHOTO")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                }

                Text("IDENTIFICATION DOSSIER")
                    .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
            }

            // Data Fields Grid
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 16) {
                    officialDataField(label: "SURNAME / NOM", value: "MARU")
                    officialDataField(label: "GIVEN NAMES / PRÉNOMS", value: "MIHIR")
                }

                HStack(spacing: 16) {
                    officialDataField(label: "NATIONALITY", value: "REPUBLIC OF INDIA")
                    officialDataField(
                        label: "RATIFICATION STATUS",
                        value: isConquered ? "VERIFIED SUMMIT ASCENT" : "RECORDED EXPEDITION ENTRY",
                        highlight: isConquered
                    )
                }

                officialDataField(label: "TARGET SUMMIT & MASSIF", value: "\(trek.name.uppercased()) · \(trek.region.uppercased())")

                HStack(spacing: 16) {
                    officialDataField(label: "GEODETIC COORDINATES", value: "\(trek.coordinatesString) (WGS84)")
                    officialDataField(label: "DATE OF RECORD", value: formattedRecordDate)
                }
            }
        }
        .padding(9)
        .background(Color.white.opacity(0.015), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.04), lineWidth: 0.8))
    }

    private func officialDataField(label: String, value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                .foregroundStyle(bronzeAccent.opacity(0.85))
                .tracking(0.5)

            Text(value)
                .font(.system(size: 10, weight: .bold, design: .serif))
                .foregroundStyle(highlight ? Color(red: 0.40, green: 0.85, blue: 0.55) : parchmentBone)
                .lineLimit(1)
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
                .foregroundStyle(bronzeAccent.opacity(0.8))
                .tracking(0.6)

            Text(primary)
                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                .foregroundStyle(parchmentBone)

            Text(secondary)
                .font(.system(size: 6.5, weight: .medium))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderSubtle.opacity(0.4), lineWidth: 0.6))
    }

    // MARK: - 4. Rich Topographic Contour Map & Archival Stamp Section
    private var topographicMapAndSealSection: some View {
        HStack(spacing: 12) {
            // Left: Double-Ring Engraved Registry Stamp
            ZStack {
                Circle()
                    .strokeBorder(isConquered ? sealCrimson : bronzeMuted, lineWidth: 1.5)
                    .frame(width: 84, height: 84)

                Circle()
                    .strokeBorder(isConquered ? sealCrimson.opacity(0.6) : bronzeMuted.opacity(0.5), lineWidth: 0.8)
                    .frame(width: 74, height: 74)

                VStack(spacing: 1) {
                    Text("HIMALAYAN SURVEY")
                        .font(.system(size: 5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isConquered ? sealCrimson : bronzeMuted)
                        .tracking(0.6)

                    Image(systemName: isConquered ? "seal.fill" : "mountain.2.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(isConquered ? sealCrimson : bronzeMuted)

                    Text(isConquered ? "SUMMIT RATIFIED" : "PERMIT GRANTED")
                        .font(.system(size: 6, weight: .heavy, design: .serif))
                        .foregroundStyle(isConquered ? sealCrimson : bronzeMuted)
                        .tracking(0.4)

                    Text("EXP #\(String(permitNumber.suffix(6)))")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isConquered ? sealCrimson : bronzeMuted)

                    Text(recordYear)
                        .font(.system(size: 5.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isConquered ? sealCrimson.opacity(0.8) : bronzeMuted.opacity(0.8))
                }
            }

            // Right: Rich Geological Survey Topographical Contour Map
            VStack(alignment: .leading, spacing: 3) {
                // Header Bar with Coordinates & Datum
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(bronzeAccent)

                        Text("TOPOGRAPHICAL SURVEY & ASCENT CORRIDOR")
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(bronzeAccent)
                    }

                    Spacer()

                    Text("UTM 45N · WGS84")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                // Topo Vector Map Canvas with Contour Isohypses & Marked Ascent Route
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 72)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderSubtle.opacity(0.4), lineWidth: 0.6))

                    // Coordinate Grid Lines & Crosshairs
                    Canvas { context, size in
                        // Grid lines
                        var grid = Path()
                        let w = size.width
                        let h = size.height
                        
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

                        context.stroke(grid, with: .color(Color.white.opacity(0.04)), lineWidth: 0.5)

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
                            let alpha = 0.08 + Double(i) * 0.04
                            context.stroke(contour, with: .color(Color(red: 0.78, green: 0.66, blue: 0.48).opacity(alpha)), lineWidth: 0.7)
                        }

                        // Topo Ridge Lines (Subtle dashed ridges)
                        var ridge1 = Path()
                        ridge1.move(to: center)
                        ridge1.addLine(to: CGPoint(x: w * 0.98, y: h * 0.8))
                        context.stroke(ridge1, with: .color(Color.white.opacity(0.08)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))

                        var ridge2 = Path()
                        ridge2.move(to: center)
                        ridge2.addLine(to: CGPoint(x: w * 0.6, y: h * 0.05))
                        context.stroke(ridge2, with: .color(Color.white.opacity(0.08)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))

                        // Technical Ascent Route Line (from Basecamp to Summit)
                        var route = Path()
                        route.move(to: CGPoint(x: w * 0.08, y: h * 0.82))
                        route.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.68), control1: CGPoint(x: w * 0.15, y: h * 0.80), control2: CGPoint(x: w * 0.22, y: h * 0.72))
                        route.addCurve(to: CGPoint(x: w * 0.48, y: h * 0.52), control1: CGPoint(x: w * 0.35, y: h * 0.62), control2: CGPoint(x: w * 0.42, y: h * 0.56))
                        route.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.38), control1: CGPoint(x: w * 0.54, y: h * 0.48), control2: CGPoint(x: w * 0.60, y: h * 0.42))
                        route.addCurve(to: center, control1: CGPoint(x: w * 0.72, y: h * 0.32), control2: CGPoint(x: w * 0.78, y: h * 0.28))
                        
                        context.stroke(route, with: .color(Color(red: 0.78, green: 0.66, blue: 0.48)), style: StrokeStyle(lineWidth: 1.4, dash: [4, 2]))
                    }
                    .frame(height: 72)

                    // Waypoint Pins & Geographical Labels Overlaid on Map
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height

                        // North Arrow in top-left
                        HStack(spacing: 2) {
                            Image(systemName: "location.north.line.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(bronzeAccent)
                            Text("N")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(bronzeAccent)
                        }
                        .position(x: 16, y: 12)

                        // Contour Altitude Labels
                        Text("5,000m")
                            .font(.system(size: 5.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)
                            .position(x: w * 0.48, y: h * 0.88)

                        Text("7,500m (Death Zone)")
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.85, green: 0.35, blue: 0.35).opacity(0.85))
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
            .background(Color.white.opacity(0.015), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderSubtle.opacity(0.3), lineWidth: 0.6))
        }
    }

    private func mapWaypointPin(label: String, isApex: Bool) -> some View {
        VStack(spacing: 1) {
            if isApex {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(bronzeAccent)
                Text(label)
                    .font(.system(size: 6, weight: .black, design: .monospaced))
                    .foregroundStyle(parchmentBone)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(bronzeAccent, lineWidth: 0.5))
            } else {
                Circle()
                    .fill(bronzeAccent)
                    .frame(width: 4, height: 4)
                Text(label)
                    .font(.system(size: 5, weight: .bold, design: .monospaced))
                    .foregroundStyle(parchmentBone.opacity(0.85))
                    .padding(.horizontal, 2)
                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 2))
            }
        }
    }

    // MARK: - 5. Waypoints & Route Trajectory Breakdown
    private var waypointTrajectorySection: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("ASCENT WAYPOINTS & CORRIDOR PROFILE")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(bronzeAccent.opacity(0.85))
                    .tracking(0.5)

                Spacer()

                Text("6-STAGE EXPEDITION PROFILE")
                    .font(.system(size: 6, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
            }

            // 6-Waypoint Step Grid with Altitude & Terrain Classification
            HStack(spacing: 4) {
                ForEach(routeWaypoints) { stage in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Text(stage.code)
                                .font(.system(size: 6.5, weight: .black, design: .monospaced))
                                .foregroundStyle(stage.code == "▲" ? Color.green : bronzeAccent)
                            Spacer()
                            Text("\(stage.altitudeMeters)m")
                                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(parchmentBone)
                        }

                        Text(stage.name)
                            .font(.system(size: 6.5, weight: .bold))
                            .foregroundStyle(parchmentBone.opacity(0.9))
                            .lineLimit(1)

                        HStack {
                            Text("\(String(format: "%.1f", stage.distKm)) km")
                                .font(.system(size: 5.5, weight: .medium, design: .monospaced))
                                .foregroundStyle(DS.Color.textTertiary)
                            Spacer()
                            Text(stage.terrain)
                                .font(.system(size: 5, weight: .medium))
                                .foregroundStyle(bronzeAccent.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.015), in: RoundedRectangle(cornerRadius: 3))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(borderSubtle.opacity(0.3), lineWidth: 0.5))
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
                    .foregroundStyle(bronzeAccent.opacity(0.85))
                    .tracking(0.5)
            }

            Text(trek.personalNotes.isEmpty ? "High-altitude summit waypoint logged under verified atmospheric conditions. Preserved in the Sovereign Alpine Register." : trek.personalNotes)
                .font(.system(size: 8.5, weight: .regular, design: .serif))
                .foregroundStyle(parchmentBone.opacity(0.85))
                .lineSpacing(1.5)
                .lineLimit(2)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.015), in: RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderSubtle.opacity(0.3), lineWidth: 0.5))
        }
    }

    // MARK: - 7. Attestation & Digital Verification
    private var attestationSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("REGISTRY ATTESTATION & FINGERPRINT")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(bronzeAccent)
                    .tracking(0.5)

                Text("HASH: \(verificationHash)")
                    .font(.system(size: 6.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)

                Text("OFFICIALLY RATIFIED BY PLUTO EXPEDITION LEDGER")
                    .font(.system(size: 5.5, weight: .medium))
                    .foregroundStyle(DS.Color.textTertiary.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("Mihir Maru")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(parchmentBone)

                Text("EXPEDITION LEADER & CHIEF SURVEYOR")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundStyle(bronzeAccent)
                    .tracking(0.6)
            }
        }
    }

    // MARK: - 8. Machine Readable Zone (MRZ Passport Footer)
    private var machineReadableZoneSection: some View {
        VStack(alignment: .leading, spacing: 1.5) {
            Text(mrzCodeLine1)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(parchmentBone.opacity(0.75))
                .tracking(1.8)

            Text(mrzCodeLine2)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(parchmentBone.opacity(0.75))
                .tracking(1.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(borderSubtle.opacity(0.4), lineWidth: 0.6))
    }
}
