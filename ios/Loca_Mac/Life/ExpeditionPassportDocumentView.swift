import SwiftUI
import AppKit
import CoreLocation

// MARK: - ExpeditionPassportDocumentView

/// Authentic, prestigious archival-grade Alpine Expedition Passport & Summit Dossier.
/// Designed according to diplomatic mountaineering registry standards (Swiss Alpine Club,
/// Himalayan Database, and Survey of India expedition certification).
/// Formatted for Letter/A4 canvas (600 × 840 pt) suitable for screen inspection,
/// vector PDF export, and high-DPI archival printing.
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
    private let archivalDark    = Color(red: 0.07, green: 0.08, blue: 0.11) // Deep Obsidian Slate
    private let borderSubtle    = Color(red: 0.78, green: 0.66, blue: 0.48).opacity(0.25)
    private let sealCrimson     = Color(red: 0.68, green: 0.20, blue: 0.20) // Archival Stamp Inked Crimson

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {

                // 1. Diplomatic Header & Alpine Authority Registry
                officialHeaderSection

                Divider().overlay(borderSubtle)

                // 2. Bearer & Summit Geodetic Dossier (Photo + Data Grid)
                climberDossierSection

                // 3. Technical Topographical Telemetry Grid
                telemetryGridSection

                // 4. Hypsometric Topographic Cross-Section & Archival Stamp
                hypsometricProfileAndSealSection

                // 5. Official Expedition Field Notes & Ledger
                fieldNotesSection

                Spacer(minLength: 4)

                Divider().overlay(borderSubtle)

                // 6. Attestation & Digital Verification Signatures
                attestationSection

                // 7. ICAO Standard Machine Readable Zone (MRZ)
                machineReadableZoneSection
            }
            .padding(26)
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
            // Official Crest & Registry Authority
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

            // Classification & Serial Tracking
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
            // Climber Passport Photo Frame
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 96, height: 106)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(borderSubtle, lineWidth: 1)
                        )

                    if let firstPhoto = trek.photoFileNames.first,
                       let img = TrekMediaManager.shared.loadPhoto(fileName: firstPhoto) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 94, height: 104)
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

            // Official Passport Record Data Grid
            VStack(alignment: .leading, spacing: 6) {
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
        .padding(10)
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
                .font(.system(size: 10.5, weight: .bold, design: .serif))
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
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(parchmentBone)

            Text(secondary)
                .font(.system(size: 6.5, weight: .medium))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderSubtle.opacity(0.4), lineWidth: 0.6))
    }

    // MARK: - 4. Hypsometric Topographic Cross-Section & Archival Stamp
    private var hypsometricProfileAndSealSection: some View {
        HStack(spacing: 12) {
            // Authentic Archival Seal (Double-Ring Engraved Registry Stamp)
            ZStack {
                // Outer Seal Ring
                Circle()
                    .strokeBorder(isConquered ? sealCrimson : bronzeMuted, lineWidth: 1.5)
                    .frame(width: 86, height: 86)

                // Inner Seal Ring
                Circle()
                    .strokeBorder(isConquered ? sealCrimson.opacity(0.6) : bronzeMuted.opacity(0.5), lineWidth: 0.8)
                    .frame(width: 76, height: 76)

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

            // Hypsometric Elevation Cross-Section
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 7))
                        .foregroundStyle(bronzeAccent)

                    Text("HYPSOMETRIC TOPOGRAPHY & ELEVATION CROSS-SECTION")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(bronzeAccent)

                    Spacer()

                    Text("DATUM: \(Int(trek.elevationMeters)) m")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                // Elevation Graph with subtle hypsometric gradient
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 52)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.04), lineWidth: 0.6))

                    // Altitude Reference Grid Lines
                    VStack {
                        Divider().overlay(Color.white.opacity(0.03))
                        Spacer()
                        Divider().overlay(Color.white.opacity(0.03))
                        Spacer()
                    }
                    .frame(height: 52)

                    // Hypsometric Altitude Fill & Contour
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 52))
                        path.addLine(to: CGPoint(x: 0, y: 44))
                        path.addCurve(to: CGPoint(x: 90, y: 36), control1: CGPoint(x: 30, y: 44), control2: CGPoint(x: 60, y: 40))
                        path.addCurve(to: CGPoint(x: 210, y: 12), control1: CGPoint(x: 130, y: 30), control2: CGPoint(x: 170, y: 16))
                        path.addCurve(to: CGPoint(x: 320, y: 38), control1: CGPoint(x: 250, y: 8), control2: CGPoint(x: 285, y: 34))
                        path.addLine(to: CGPoint(x: 320, y: 52))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [bronzeAccent.opacity(0.18), bronzeAccent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 44))
                        path.addCurve(to: CGPoint(x: 90, y: 36), control1: CGPoint(x: 30, y: 44), control2: CGPoint(x: 60, y: 40))
                        path.addCurve(to: CGPoint(x: 210, y: 12), control1: CGPoint(x: 130, y: 30), control2: CGPoint(x: 170, y: 16))
                        path.addCurve(to: CGPoint(x: 320, y: 38), control1: CGPoint(x: 250, y: 8), control2: CGPoint(x: 285, y: 34))
                    }
                    .stroke(bronzeAccent.opacity(0.85), lineWidth: 1.2)

                    // Key Elevation Waypoint Markers
                    HStack {
                        Text("Basecamp")
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("High Camp")
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("Summit (\(Int(trek.elevationMeters))m)")
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(bronzeAccent)
                        Spacer()
                        Text("Decent")
                            .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
                }
            }
            .padding(6)
            .background(Color.white.opacity(0.015), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderSubtle.opacity(0.3), lineWidth: 0.6))
        }
    }

    // MARK: - 5. Official Expedition Field Notes
    private var fieldNotesSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("FIELD LOGBOOK OBSERVATIONS & GEOLOGICAL NARRATIVE")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(bronzeAccent.opacity(0.85))
                    .tracking(0.5)
            }

            Text(trek.personalNotes.isEmpty ? "High-altitude summit waypoint logged under verified atmospheric conditions. Preserved in the Sovereign Alpine Register." : trek.personalNotes)
                .font(.system(size: 9, weight: .regular, design: .serif))
                .foregroundStyle(parchmentBone.opacity(0.85))
                .lineSpacing(2)
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.015), in: RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderSubtle.opacity(0.3), lineWidth: 0.6))
        }
    }

    // MARK: - 6. Attestation & Digital Verification
    private var attestationSection: some View {
        HStack(alignment: .center) {
            // Cryptographic Fingerprint Verification
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

            // Authorized Signature Block
            VStack(alignment: .trailing, spacing: 1) {
                Text("Mihir Maru")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(parchmentBone)

                Text("EXPEDITION LEADER & CHIEF SURVEYOR")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundStyle(bronzeAccent)
                    .tracking(0.6)
            }
        }
    }

    // MARK: - 7. Machine Readable Zone (MRZ Passport Footer)
    private var machineReadableZoneSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(mrzCodeLine1)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundStyle(parchmentBone.opacity(0.75))
                .tracking(1.8)

            Text(mrzCodeLine2)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundStyle(parchmentBone.opacity(0.75))
                .tracking(1.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(borderSubtle.opacity(0.4), lineWidth: 0.6))
    }
}
