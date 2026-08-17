import SwiftUI
import AppKit
import CoreLocation

// MARK: - PassportEditionTheme

/// The 4 prestigious real-world diplomatic & historical mountaineering certificate aesthetics:
/// 1. 🏛️ Diplomatic Ivory: Swiss Alpine Club & UN Diplomatic Treaty (Luminous Ivory & Oxford Navy)
/// 2. 📜 Royal Geographic Vellum: Royal Geographical Society 1953 Everest & Colonial Archival Vellum (Antique Sepia & Burgundy)
/// 3. ❄️ Nordic Polar Technical: Scandinavian Arctic & Japanese Alpine Club (Glacial Ice Slate & Arctic Blue)
/// 4. 👑 Sovereign Obsidian Gold: Head of State Special Diplomatic Passport (Matte Obsidian & 24K Gold Foil)
enum PassportEditionTheme: String, CaseIterable, Identifiable {
    case diplomaticIvory   = "Diplomatic Ivory"
    case royalVellum       = "Royal Geographic Vellum"
    case nordicTechnical   = "Nordic Polar Technical"
    case obsidianGold      = "Sovereign Obsidian Gold"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .diplomaticIvory: return "building.columns.fill"
        case .royalVellum:     return "scroll.fill"
        case .nordicTechnical: return "mountain.2.fill"
        case .obsidianGold:    return "crown.fill"
        }
    }

    var shortTag: String {
        switch self {
        case .diplomaticIvory: return "GENEVA / SWISS"
        case .royalVellum:     return "RGS 1953 VINTAGE"
        case .nordicTechnical: return "NORDIC TECHNICAL"
        case .obsidianGold:    return "SOVEREIGN GOLD"
        }
    }
}

// MARK: - ExpeditionPassportDocumentView

/// Authentic, prestigious Alpine Expedition Passport & Summit Dossier.
/// Supports 4 live distinct diplomatic & historical document editions (Ivory, Vintage Vellum, Nordic Slate, Obsidian Gold).
/// Features precision cartographic contour maps, geodetic coordinates, dynamic route stages, and state seals.
struct ExpeditionPassportDocumentView: View {

    let trek: TrekRecord
    var theme: PassportEditionTheme = .diplomaticIvory

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
        let raw = "\(trek.name)-\(trek.elevationMeters)-\(permitNumber)-\(recordYear)-\(theme.rawValue)"
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

    // MARK: - Dynamic Theme Color Tokens

    private var bgGradient: [Color] {
        switch theme {
        case .diplomaticIvory:
            return [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.94, green: 0.92, blue: 0.88)]
        case .royalVellum:
            return [Color(red: 0.95, green: 0.91, blue: 0.82), Color(red: 0.89, green: 0.84, blue: 0.73)]
        case .nordicTechnical:
            return [Color(red: 0.96, green: 0.97, blue: 0.99), Color(red: 0.90, green: 0.93, blue: 0.96)]
        case .obsidianGold:
            return [Color(red: 0.09, green: 0.10, blue: 0.13), Color(red: 0.04, green: 0.05, blue: 0.07)]
        }
    }

    private var inkPrimary: Color {
        switch theme {
        case .diplomaticIvory: return Color(red: 0.10, green: 0.12, blue: 0.16)
        case .royalVellum:     return Color(red: 0.16, green: 0.12, blue: 0.08)
        case .nordicTechnical: return Color(red: 0.08, green: 0.11, blue: 0.16)
        case .obsidianGold:    return Color(red: 0.95, green: 0.86, blue: 0.65) // Metallic Gold Ink
        }
    }

    private var inkSecondary: Color {
        switch theme {
        case .diplomaticIvory: return Color(red: 0.28, green: 0.32, blue: 0.40)
        case .royalVellum:     return Color(red: 0.32, green: 0.24, blue: 0.16)
        case .nordicTechnical: return Color(red: 0.22, green: 0.28, blue: 0.38)
        case .obsidianGold:    return Color(red: 0.80, green: 0.82, blue: 0.88)
        }
    }

    private var inkTertiary: Color {
        switch theme {
        case .diplomaticIvory: return Color(red: 0.50, green: 0.54, blue: 0.62)
        case .royalVellum:     return Color(red: 0.52, green: 0.44, blue: 0.34)
        case .nordicTechnical: return Color(red: 0.46, green: 0.52, blue: 0.60)
        case .obsidianGold:    return Color(red: 0.55, green: 0.58, blue: 0.65)
        }
    }

    private var accentColor: Color {
        switch theme {
        case .diplomaticIvory: return Color(red: 0.68, green: 0.54, blue: 0.32) // Intaglio Gold
        case .royalVellum:     return Color(red: 0.55, green: 0.40, blue: 0.20) // Antique Brass
        case .nordicTechnical: return Color(red: 0.14, green: 0.42, blue: 0.65) // Glacial Blue
        case .obsidianGold:    return Color(red: 0.88, green: 0.74, blue: 0.44) // Radiant 24K Gold
        }
    }

    private var outerBorderColor: Color {
        switch theme {
        case .diplomaticIvory: return Color(red: 0.12, green: 0.18, blue: 0.28)
        case .royalVellum:     return Color(red: 0.35, green: 0.25, blue: 0.15)
        case .nordicTechnical: return Color(red: 0.14, green: 0.28, blue: 0.45)
        case .obsidianGold:    return Color(red: 0.78, green: 0.64, blue: 0.36)
        }
    }

    private var cardFillColor: Color {
        switch theme {
        case .diplomaticIvory: return Color.white.opacity(0.65)
        case .royalVellum:     return Color(red: 0.98, green: 0.96, blue: 0.90).opacity(0.7)
        case .nordicTechnical: return Color.white.opacity(0.85)
        case .obsidianGold:    return Color.black.opacity(0.35)
        }
    }

    private var sealColor: Color {
        switch theme {
        case .diplomaticIvory: return isConquered ? Color(red: 0.62, green: 0.14, blue: 0.14) : Color(red: 0.12, green: 0.18, blue: 0.28)
        case .royalVellum:     return isConquered ? Color(red: 0.48, green: 0.12, blue: 0.14) : Color(red: 0.32, green: 0.22, blue: 0.12)
        case .nordicTechnical: return isConquered ? Color(red: 0.12, green: 0.38, blue: 0.58) : Color(red: 0.25, green: 0.32, blue: 0.42)
        case .obsidianGold:    return isConquered ? Color(red: 0.88, green: 0.74, blue: 0.44) : Color(red: 0.65, green: 0.55, blue: 0.38)
        }
    }

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

                Divider().overlay(outerBorderColor.opacity(0.35))

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

                Divider().overlay(outerBorderColor.opacity(0.35))

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
                    colors: bgGradient,
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
                    let alpha = theme == .obsidianGold ? 0.03 : 0.06
                    context.stroke(path, with: .color(accentColor.opacity(alpha)), lineWidth: 0.75)
                }

                // Subtle Center Diplomatic Watermark Insignia
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 230))
                    .foregroundStyle(accentColor.opacity(theme == .obsidianGold ? 0.02 : 0.035))
            }
        )
        .overlay(
            // Diplomatic Intaglio Dual Security Border
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(outerBorderColor, lineWidth: 1.4)
                    .padding(6)

                RoundedRectangle(cornerRadius: 4)
                    .stroke(outerBorderColor.opacity(0.4), lineWidth: 0.8)
                    .padding(10)

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
                    .fill(accentColor.opacity(0.6))
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
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(accentColor, lineWidth: 1.2)
                        .frame(width: 36, height: 36)

                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: "laurel.leading")
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor)
                        .offset(x: -6)

                    Image(systemName: "laurel.trailing")
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor)
                        .offset(x: 6)

                    Image(systemName: "compass.drawing")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(inkPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme == .royalVellum ? "ROYAL GEOGRAPHICAL SOCIETY · HIMALAYAN SURVEY" : "REPUBLIC OF INDIA · HIMALAYAN EXPEDITION REGISTRY")
                        .font(.system(size: 10, weight: .black, design: .serif))
                        .foregroundStyle(inkPrimary)
                        .tracking(1.4)

                    Text(theme == .royalVellum ? "OFFICIAL EXPEDITION DISPATCH · HIGH-ALTITUDE RECORD" : "OFFICIAL DIPLOMATIC SUMMIT DOSSIER · ACTE OFFICIEL D'EXPÉDITION")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(0.8)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("SERIES:")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(inkTertiary)
                    Text("2026/IND-WGS84")
                        .font(.system(size: 7, weight: .black, design: .monospaced))
                        .foregroundStyle(accentColor)
                }

                Text("PERMIT NO: \(permitNumber)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(inkPrimary)
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
                        .fill(theme == .obsidianGold ? Color.black.opacity(0.5) : Color.white)
                        .frame(width: 96, height: 102)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(outerBorderColor.opacity(0.3), lineWidth: 1)
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
                                .foregroundStyle(accentColor.opacity(0.5))
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

            // Data Grid
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
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(outerBorderColor.opacity(0.3), lineWidth: 0.8))
    }

    private func officialDataField(label: String, value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                .foregroundStyle(accentColor)
                .tracking(0.5)

            if highlight {
                Text(value)
                    .font(.system(size: 9.5, weight: .black, design: .serif))
                    .foregroundStyle(theme == .obsidianGold ? Color(red: 0.45, green: 0.90, blue: 0.60) : Color(red: 0.11, green: 0.45, blue: 0.24))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        theme == .obsidianGold ? Color.green.opacity(0.15) : Color(red: 0.11, green: 0.45, blue: 0.24).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 2)
                    )
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
                .foregroundStyle(accentColor)
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
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(outerBorderColor.opacity(0.3), lineWidth: 0.7))
    }

    // MARK: - 4. Cartographic Topographic Map & State Seal Section
    private var topographicMapAndSealSection: some View {
        HStack(spacing: 12) {
            // Left: State / Expedition Seal
            ZStack {
                Circle()
                    .strokeBorder(sealColor, lineWidth: 1.6)
                    .frame(width: 84, height: 84)

                Circle()
                    .strokeBorder(sealColor.opacity(0.6), lineWidth: 0.8)
                    .frame(width: 74, height: 74)

                VStack(spacing: 1) {
                    Text(theme == .royalVellum ? "★ ROYAL GEOGRAPHIC ★" : "★ STATE SURVEY ★")
                        .font(.system(size: 4.8, weight: .black, design: .monospaced))
                        .foregroundStyle(sealColor)
                        .tracking(0.5)

                    Image(systemName: isConquered ? "seal.fill" : "mountain.2.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(sealColor)

                    Text(isConquered ? "SUMMIT RATIFIED" : "PERMIT GRANTED")
                        .font(.system(size: 6.5, weight: .black, design: .serif))
                        .foregroundStyle(sealColor)
                        .tracking(0.4)

                    Text("EXP #\(String(permitNumber.suffix(6)))")
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(sealColor)

                    Text(recordYear)
                        .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(sealColor.opacity(0.8))
                }
            }

            // Right: Rich Cartographic Topographical Map
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(accentColor)

                        Text("CARTOGRAPHIC SURVEY & ASCENT TOPOGRAPHY")
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(inkPrimary)
                    }

                    Spacer()

                    Text("UTM 45N · WGS84 DATUM")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(inkTertiary)
                }

                // Map Canvas with Topographic Contour Isohypses & Marked Route
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme == .obsidianGold ? Color.black.opacity(0.6) : Color.white.opacity(0.75))
                        .frame(height: 72)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(outerBorderColor.opacity(0.3), lineWidth: 0.8))

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

                        context.stroke(grid, with: .color(accentColor.opacity(0.12)), lineWidth: 0.5)

                        // Topographical Elevation Contour Isohypses
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
                            let alpha = theme == .obsidianGold ? (0.12 + Double(i) * 0.06) : (0.15 + Double(i) * 0.08)
                            let strokeColor = theme == .obsidianGold ? accentColor : (theme == .royalVellum ? Color(red: 0.45, green: 0.35, blue: 0.25) : Color(red: 0.45, green: 0.52, blue: 0.62))
                            context.stroke(contour, with: .color(strokeColor.opacity(alpha)), lineWidth: 0.75)
                        }

                        // Topo Ridge Lines
                        var ridge1 = Path()
                        ridge1.move(to: center)
                        ridge1.addLine(to: CGPoint(x: w * 0.98, y: h * 0.8))
                        context.stroke(ridge1, with: .color(accentColor.opacity(0.2)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))

                        var ridge2 = Path()
                        ridge2.move(to: center)
                        ridge2.addLine(to: CGPoint(x: w * 0.6, y: h * 0.05))
                        context.stroke(ridge2, with: .color(accentColor.opacity(0.2)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))

                        // Technical Ascent Route Line
                        var route = Path()
                        route.move(to: CGPoint(x: w * 0.08, y: h * 0.82))
                        route.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.68), control1: CGPoint(x: w * 0.15, y: h * 0.80), control2: CGPoint(x: w * 0.22, y: h * 0.72))
                        route.addCurve(to: CGPoint(x: w * 0.48, y: h * 0.52), control1: CGPoint(x: w * 0.35, y: h * 0.62), control2: CGPoint(x: w * 0.42, y: h * 0.56))
                        route.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.38), control1: CGPoint(x: w * 0.54, y: h * 0.48), control2: CGPoint(x: w * 0.60, y: h * 0.42))
                        route.addCurve(to: center, control1: CGPoint(x: w * 0.72, y: h * 0.32), control2: CGPoint(x: w * 0.78, y: h * 0.28))

                        let routeColor = theme == .obsidianGold ? accentColor : outerBorderColor
                        context.stroke(route, with: .color(routeColor), style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    }
                    .frame(height: 72)

                    // Waypoint Pins Overlaid on Map
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height

                        HStack(spacing: 2) {
                            Image(systemName: "location.north.line.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(accentColor)
                            Text("N")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundStyle(accentColor)
                        }
                        .position(x: 16, y: 12)

                        Text("5,000m")
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(inkTertiary)
                            .position(x: w * 0.48, y: h * 0.88)

                        Text("7,500m (Death Zone)")
                            .font(.system(size: 5.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.25))
                            .position(x: w * 0.68, y: h * 0.16)

                        mapWaypointPin(label: "BC (5.3k)", isApex: false)
                            .position(x: w * 0.08, y: h * 0.82)

                        mapWaypointPin(label: "C2 (6.4k)", isApex: false)
                            .position(x: w * 0.48, y: h * 0.52)

                        mapWaypointPin(label: "C4 (7.9k)", isApex: false)
                            .position(x: w * 0.65, y: h * 0.38)

                        mapWaypointPin(label: "▲ SUMMIT (\(Int(trek.elevationMeters))m)", isApex: true)
                            .position(x: w * 0.82, y: h * 0.28)
                    }
                    .frame(height: 72)
                }
            }
            .padding(6)
            .background(cardFillColor, in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(outerBorderColor.opacity(0.3), lineWidth: 0.6))
        }
    }

    private func mapWaypointPin(label: String, isApex: Bool) -> some View {
        VStack(spacing: 1) {
            if isApex {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.system(size: 6, weight: .black, design: .monospaced))
                    .foregroundStyle(theme == .obsidianGold ? Color.black : Color.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(theme == .obsidianGold ? accentColor : outerBorderColor, in: RoundedRectangle(cornerRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(accentColor, lineWidth: 0.6))
            } else {
                Circle()
                    .fill(accentColor)
                    .frame(width: 4, height: 4)
                Text(label)
                    .font(.system(size: 5, weight: .bold, design: .monospaced))
                    .foregroundStyle(inkPrimary)
                    .padding(.horizontal, 2)
                    .background(cardFillColor, in: RoundedRectangle(cornerRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(accentColor.opacity(0.4), lineWidth: 0.4))
            }
        }
    }

    // MARK: - 5. Waypoints & Route Trajectory Breakdown
    private var waypointTrajectorySection: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("ASCENT WAYPOINTS & CORRIDOR PROFILE")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .tracking(0.5)

                Spacer()

                Text("6-STAGE EXPEDITION PROFILE")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundStyle(inkTertiary)
            }

            HStack(spacing: 4) {
                ForEach(routeWaypoints) { stage in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Text(stage.code)
                                .font(.system(size: 6.5, weight: .black, design: .monospaced))
                                .foregroundStyle(stage.code == "▲" ? (theme == .obsidianGold ? Color.green : Color(red: 0.11, green: 0.45, blue: 0.24)) : accentColor)
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
                                .foregroundStyle(accentColor)
                                .lineLimit(1)
                        }
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity)
                    .background(cardFillColor, in: RoundedRectangle(cornerRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(outerBorderColor.opacity(0.3), lineWidth: 0.6))
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
                    .foregroundStyle(accentColor)
                    .tracking(0.5)
            }

            Text(trek.personalNotes.isEmpty ? "High-altitude summit waypoint logged under verified atmospheric conditions. Preserved in the Sovereign Alpine Register." : trek.personalNotes)
                .font(.system(size: 8.5, weight: .regular, design: .serif))
                .foregroundStyle(inkPrimary)
                .lineSpacing(1.5)
                .lineLimit(2)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor, in: RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(outerBorderColor.opacity(0.3), lineWidth: 0.6))
        }
    }

    // MARK: - 7. Attestation & Digital Verification
    private var attestationSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("REGISTRY ATTESTATION & FINGERPRINT")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentColor)
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
                    .foregroundStyle(inkPrimary)

                Text("EXPEDITION LEADER & CHIEF SURVEYOR")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentColor)
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
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(outerBorderColor.opacity(0.3), lineWidth: 0.6))
    }
}
