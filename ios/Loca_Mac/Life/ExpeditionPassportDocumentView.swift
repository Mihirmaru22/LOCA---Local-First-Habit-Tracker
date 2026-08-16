import SwiftUI
import AppKit
import CoreLocation

// MARK: - ExpeditionPassportDocumentView

/// Luxury high-resolution Alpine Certificate and Expedition Passport document view.
/// Styled for standard Letter/A4 aspect ratio (600 × 840 pt) suitable for screen inspection,
/// vector PDF generation, and 4K image rendering.
struct ExpeditionPassportDocumentView: View {

    let trek: TrekRecord

    private var isConquered: Bool {
        trek.status == .conquered
    }

    private var certificateID: String {
        let code = abs(trek.id.hashValue) % 1_000_000
        return String(format: "PLUTO-EXP-%06d", code)
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Outer Ornamental Border
            VStack(spacing: DS.Space.lg) {

                // 1. Header Official Crest & Serial Bar
                headerCrestSection

                Divider().overlay(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.4))

                // 2. Mountain Title & Geographical Coordinates
                mountainTitleSection

                // 3. Telemetry Matrix Strip (4 Key Stats)
                telemetryMatrixSection

                // 4. Official Status Stamp & Elevation Profile
                statusAndProfileSection

                // 5. Summit Photo Gallery or Certified Alpine Badge
                photoGallerySection

                // 6. Field Memoirs & Weather Narrative
                fieldMemoirsSection

                Spacer(minLength: 10)

                Divider().overlay(Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.3))

                // 7. Official Seal, Signature & Security Token
                footerRegistrySection
            }
            .padding(32)
        }
        .frame(width: 600, height: 840)
        .background(
            // Luxury Obsidian & Parchment Alpine Gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.14),
                    Color(red: 0.04, green: 0.06, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            // Gold Ingot Certificate Double Frame
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
                    .stroke(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.3), lineWidth: 0.8)
                    .padding(14)
            }
        )
    }

    // MARK: - Subviews

    // 1. Header Crest Section
    private var headerCrestSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                    Text("PLUTO MOUNTAINEERING REGISTRY")
                        .font(.system(size: 11, weight: .black, design: .serif))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                        .tracking(1.5)
                }

                Text("OFFICIAL EXPEDITION PASSPORT & SUMMIT DOSSIER")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(1.0)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(certificateID)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))

                Text("ISSUED: \(Date().formatted(.dateTime.day().month(.abbreviated).year()))")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    // 2. Mountain Title Section
    private var mountainTitleSection: some View {
        VStack(spacing: 6) {
            Text(trek.name.uppercased())
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(Color.white)
                .tracking(2.0)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Text("\(trek.region), \(trek.country)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)

                Text("•")
                    .foregroundStyle(DS.Color.textTertiary)

                Text(trek.coordinatesString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.cyan)
            }
        }
    }

    // 3. Telemetry Matrix Section (4 Stat Tiles)
    private var telemetryMatrixSection: some View {
        HStack(spacing: 12) {
            statCell(
                title: "PEAK ALTITUDE",
                value: "\(Int(trek.elevationMeters).formatted()) m",
                subtext: "\(Int(trek.elevationFeet).formatted()) ft",
                color: Color.cyan
            )

            statCell(
                title: "VERTICAL ASCENT",
                value: trek.elevationGainMeters != nil ? "+\(Int(trek.elevationGainMeters!).formatted()) m" : "—",
                subtext: "Cumulative gain",
                color: Color.purple
            )

            statCell(
                title: "TRAIL DISTANCE",
                value: trek.trailDistanceKm != nil ? String(format: "%.1f km", trek.trailDistanceKm!) : "—",
                subtext: "Corridor length",
                color: Color.green
            )

            statCell(
                title: "DIFFICULTY GRADE",
                value: trek.difficulty.title,
                subtext: "Alpine Scale",
                color: Color.orange
            )
        }
    }

    private func statCell(title: String, value: String, subtext: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)
                .tracking(0.6)

            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(color)

            Text(subtext)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 0.8))
    }

    // 4. Status Stamp & Elevation Profile
    private var statusAndProfileSection: some View {
        HStack(spacing: 16) {

            // Official Wax Seal / Stamp
            ZStack {
                Circle()
                    .fill(
                        isConquered
                            ? Color(red: 0.85, green: 0.65, blue: 0.15).opacity(0.18)
                            : Color.cyan.opacity(0.15)
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle().stroke(
                            isConquered ? Color(red: 0.95, green: 0.80, blue: 0.30) : Color.cyan,
                            style: StrokeStyle(lineWidth: 2, dash: [4, 3])
                        )
                    )

                VStack(spacing: 2) {
                    Image(systemName: isConquered ? "trophy.fill" : "flag.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isConquered ? Color(red: 0.95, green: 0.80, blue: 0.30) : Color.cyan)

                    Text(isConquered ? "CONQUERED" : "REGISTERED")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(isConquered ? Color(red: 0.95, green: 0.80, blue: 0.30) : Color.cyan)

                    if let date = trek.dateConquered {
                        Text(date.formatted(.dateTime.month(.abbreviated).year()))
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }

            // Elevation Gradient Sparkline Box
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.cyan)
                    Text("TERRAIN TOPOGRAPHY & SLOPE CORRIDOR")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                    Spacer()
                    Text("Basecamp ➔ Summit")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                // Visual simulated alpine profile line
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 54)

                    // Wave / Peak shape
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 48))
                        path.addCurve(to: CGPoint(x: 120, y: 36), control1: CGPoint(x: 40, y: 48), control2: CGPoint(x: 80, y: 40))
                        path.addCurve(to: CGPoint(x: 260, y: 12), control1: CGPoint(x: 160, y: 32), control2: CGPoint(x: 200, y: 16))
                        path.addCurve(to: CGPoint(x: 380, y: 44), control1: CGPoint(x: 300, y: 10), control2: CGPoint(x: 340, y: 38))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.cyan, Color.purple, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.5
                    )
                    .padding(.horizontal, 8)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }

    // 5. Photo Gallery Section
    private var photoGallerySection: some View {
        HStack(spacing: 8) {
            if trek.photoFileNames.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.7))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ALPINE ASCENT BADGE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                        Text("Certified summit conquest verified by Pluto Trek Engine")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.green.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
            } else {
                ForEach(Array(trek.photoFileNames.prefix(3).enumerated()), id: \.offset) { _, fileName in
                    if let img = TrekMediaManager.shared.loadPhoto(fileName: fileName) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.18), lineWidth: 1))
                    }
                }
            }
        }
    }

    // 6. Field Memoirs & Weather Narrative
    private var fieldMemoirsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                Text("EXPEDITION LOGBOOK MEMOIRS & FIELD NOTES")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
            }

            Text(trek.personalNotes.isEmpty ? "No expedition memoirs recorded for this summit. The high mountain silence speaks for itself." : trek.personalNotes)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(3)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
    }

    // 7. Footer Registry Section
    private var footerRegistrySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("VERIFIED BY PLUTO ALPINE CLUB")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                    .tracking(0.8)

                Text("Cryptographic Summit Ledger ID: \(trek.id.uuidString.prefix(18))")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                // Signature line
                Text("Mihir Maru")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.white)

                Text("EXPEDITION LEADER SIGNATURE")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
            }
        }
    }
}
