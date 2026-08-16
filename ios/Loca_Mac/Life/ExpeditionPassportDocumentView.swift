import SwiftUI
import AppKit
import CoreLocation

// MARK: - ExpeditionPassportDocumentView

/// Authentic, luxury high-resolution Alpine Expedition Passport and Summit Permit document view.
/// Styled for standard Letter/A4 aspect ratio (600 × 840 pt) suitable for screen inspection,
/// vector PDF generation, and high-DPI image rendering.
struct ExpeditionPassportDocumentView: View {

    let trek: TrekRecord

    private var isConquered: Bool {
        trek.status == .conquered
    }

    private var permitNumber: String {
        let code = abs(trek.id.hashValue) % 1_000_000
        return String(format: "EXP-%06d", code)
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

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {

                // 1. Passport Official Header (Emblem, Title, Serial & Type)
                passportHeaderSection

                Divider().overlay(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.35))

                // 2. Bearer & Summit Biometric Dossier (Photo + Data Grid)
                bearerDossierSection

                // 3. Official Telemetry Grid (4 Telemetry Cells)
                telemetryGridSection

                // 4. Stamped Visas & Topographic Profile
                stampsAndProfileSection

                // 5. Expedition Log Memoirs
                logMemoirsSection

                Spacer(minLength: 4)

                Divider().overlay(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.35))

                // 6. Official Seal & Expedition Authority Signature
                sealAndSignatureSection

                // 7. Machine Readable Zone (MRZ Passport Footer)
                machineReadableZoneSection
            }
            .padding(26)
        }
        .frame(width: 600, height: 840)
        .background(
            // Authentic Deep Navy & Obsidian Passport Textured Gradient
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.14),
                        Color(red: 0.03, green: 0.05, blue: 0.09)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle Guilloché / Topographic Watermark Lines
                Canvas { context, size in
                    var path = Path()
                    let step: CGFloat = 24
                    for y in stride(from: CGFloat(0), to: size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addCurve(
                            to: CGPoint(x: size.width, y: y + 8),
                            control1: CGPoint(x: size.width * 0.35, y: y - 12),
                            control2: CGPoint(x: size.width * 0.65, y: y + 20)
                        )
                    }
                    context.stroke(path, with: .color(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.03)), lineWidth: 0.8)
                }
            }
        )
        .overlay(
            // Dual Gold Engraved Border with Ornamental Corner Marks
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.80, blue: 0.30),
                                Color(red: 0.60, green: 0.45, blue: 0.15),
                                Color(red: 0.95, green: 0.80, blue: 0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .padding(8)

                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.35), lineWidth: 0.8)
                    .padding(14)
            }
        )
    }

    // MARK: - 1. Passport Header Section
    private var passportHeaderSection: some View {
        HStack(alignment: .center) {
            // Left: Crest & Title
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("INTERNATIONAL ALPINE MOUNTAINEERING REGISTRY")
                        .font(.system(size: 9, weight: .black, design: .serif))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                        .tracking(1.2)

                    Text("OFFICIAL EXPEDITION PASSPORT · PASSEPORT D'EXPÉDITION")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .tracking(0.8)
                }
            }

            Spacer()

            // Right: Type, Code & Permit Number
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 6) {
                    Text("TYPE: P")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                    Text("CODE: IND")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                }
                Text("PERMIT NO: \(permitNumber)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white)
            }
        }
    }

    // MARK: - 2. Bearer & Summit Biometric Dossier (Passport Page Layout)
    private var bearerDossierSection: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left: Passport Photo Box
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 100, height: 110)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.4), lineWidth: 1))

                    if let firstPhoto = trek.photoFileNames.first,
                       let img = TrekMediaManager.shared.loadPhoto(fileName: firstPhoto) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 98, height: 108)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "person.crop.rectangle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.6))
                            Text("SUMMIT PHOTO")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                }

                Text("DIGITAL BIOMETRIC FIX")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.6))
            }

            // Right: Official Passport Data Fields
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 16) {
                    passportField(label: "SURNAME / NOM", value: "MARU")
                    passportField(label: "GIVEN NAMES / PRÉNOMS", value: "MIHIR")
                }

                HStack(spacing: 16) {
                    passportField(label: "NATIONALITY / NATIONALITÉ", value: "INDIAN · HIMALAYAN DIVISION")
                    passportField(label: "SUMMIT STATUS", value: isConquered ? "CONQUERED 🏆" : "REGISTERED 📍")
                }

                passportField(label: "TARGET SUMMIT & RANGE", value: "\(trek.name.uppercased()) · \(trek.region.uppercased())")

                HStack(spacing: 16) {
                    passportField(label: "SUMMIT COORDINATES", value: trek.coordinatesString)
                    passportField(label: "DATE OF RECORD", value: (trek.dateConquered ?? Date()).formatted(.dateTime.day().month(.abbreviated).year()))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private func passportField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.75))
                .tracking(0.5)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(Color.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 3. Official Telemetry Grid (4 Telemetry Cells)
    private var telemetryGridSection: some View {
        HStack(spacing: 8) {
            telemetryCell(
                title: "PEAK ALTITUDE",
                value: "\(Int(trek.elevationMeters).formatted()) m",
                subtext: "\(Int(trek.elevationFeet).formatted()) ft ASL",
                accent: Color.cyan
            )

            telemetryCell(
                title: "VERTICAL ASCENT",
                value: trek.elevationGainMeters != nil ? "+\(Int(trek.elevationGainMeters!).formatted()) m" : "—",
                subtext: "Cumulative Gain",
                accent: Color.purple
            )

            telemetryCell(
                title: "TRAIL CORRIDOR",
                value: trek.trailDistanceKm != nil ? String(format: "%.1f km", trek.trailDistanceKm!) : "—",
                subtext: "Basecamp ➔ Peak",
                accent: Color.green
            )

            telemetryCell(
                title: "ALPINE GRADE",
                value: trek.difficulty.title,
                subtext: "UIAA Scale",
                accent: Color.orange
            )
        }
    }

    private func telemetryCell(title: String, value: String, subtext: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)
                .tracking(0.6)

            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(accent)

            Text(subtext)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
    }

    // MARK: - 4. Stamped Visas & Elevation Profile
    private var stampsAndProfileSection: some View {
        HStack(spacing: 12) {
            // Authentic Red/Gold Rubber Stamp with -7° rotation
            ZStack {
                Circle()
                    .strokeBorder(
                        isConquered ? Color(red: 0.88, green: 0.30, blue: 0.25) : Color.cyan,
                        style: StrokeStyle(lineWidth: 2, dash: [4, 2])
                    )
                    .frame(width: 82, height: 82)

                Circle()
                    .strokeBorder(
                        isConquered ? Color(red: 0.88, green: 0.30, blue: 0.25).opacity(0.5) : Color.cyan.opacity(0.5),
                        lineWidth: 1
                    )
                    .frame(width: 74, height: 74)

                VStack(spacing: 1) {
                    Text("DISTRICT ALPINE REGISTRY")
                        .font(.system(size: 5.5, weight: .black))
                        .foregroundStyle(isConquered ? Color(red: 0.88, green: 0.30, blue: 0.25) : Color.cyan)
                        .tracking(0.4)

                    Image(systemName: isConquered ? "seal.fill" : "flag.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isConquered ? Color(red: 0.88, green: 0.30, blue: 0.25) : Color.cyan)

                    Text(isConquered ? "SUMMIT CONQUERED" : "PERMIT VALIDATED")
                        .font(.system(size: 6.5, weight: .black))
                        .foregroundStyle(isConquered ? Color(red: 0.88, green: 0.30, blue: 0.25) : Color.cyan)

                    if let date = trek.dateConquered {
                        Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(isConquered ? Color(red: 0.88, green: 0.30, blue: 0.25) : Color.cyan)
                    }
                }
            }
            .rotationEffect(.degrees(-7))

            // Elevation Profile Corridor
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.cyan)
                    Text("TERRAIN TOPOGRAPHY & SUMMIT TRAJECTORY")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                    Spacer()
                    Text("Elevation Profile")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.02))
                        .frame(height: 48)

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 42))
                        path.addCurve(to: CGPoint(x: 100, y: 32), control1: CGPoint(x: 35, y: 42), control2: CGPoint(x: 70, y: 36))
                        path.addCurve(to: CGPoint(x: 230, y: 10), control1: CGPoint(x: 140, y: 28), control2: CGPoint(x: 180, y: 14))
                        path.addCurve(to: CGPoint(x: 340, y: 38), control1: CGPoint(x: 270, y: 8), control2: CGPoint(x: 305, y: 34))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.cyan, Color.purple, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .padding(.horizontal, 6)
                }
            }
            .padding(7)
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
    }

    // MARK: - 5. Expedition Log Memoirs
    private var logMemoirsSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                Text("EXPEDITION LOGBOOK MEMOIRS & FIELD NOTES")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.5)
            }

            Text(trek.personalNotes.isEmpty ? "Official summit conquest recorded under clear alpine skies. Verified in the High-Altitude Ledger." : trek.personalNotes)
                .font(.system(size: 9.5, weight: .regular, design: .serif))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(2)
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.04), lineWidth: 1))
        }
    }

    // MARK: - 6. Official Seal & Signature Section
    private var sealAndSignatureSection: some View {
        HStack(alignment: .center) {
            // Gold Embossed Official Seal
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.80, blue: 0.30),
                                    Color(red: 0.70, green: 0.50, blue: 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.3), radius: 4)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(red: 0.15, green: 0.10, blue: 0.02))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("VERIFIED ALPINE CONQUEST")
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                        .tracking(0.6)

                    Text("PLUTO HIMALAYAN EXPEDITION AUTHORITY")
                        .font(.system(size: 6.5, weight: .medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }

            Spacer()

            // Expedition Leader Signature
            VStack(alignment: .trailing, spacing: 1) {
                Text("Mihir Maru")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.white)

                Text("EXPEDITION LEADER SIGNATURE")
                    .font(.system(size: 6.5, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
            }
        }
    }

    // MARK: - 7. Machine Readable Zone (MRZ Passport Footer)
    private var machineReadableZoneSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(mrzCodeLine1)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.85))
                .tracking(1.8)

            Text(mrzCodeLine2)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.85))
                .tracking(1.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.2), lineWidth: 0.8))
    }
}
