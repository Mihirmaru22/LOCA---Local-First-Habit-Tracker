import SwiftUI
import SwiftData
import MapKit
import AppKit

// MARK: - TrekEditorialCard (Used in Layout 2: Editorial Cards)

/// Magazine-style vertical expedition card with 4K photo previews,
/// alpine weather telemetry capsule, field notes blockquote, and 1-click status toggle.
struct TrekEditorialCard: View {
    let trek: TrekRecord
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleStatus: () -> Void
    var onOpenPassport: () -> Void = {}
    let onOpenQuickLook: (String, Int) -> Void

    private var isConquered: Bool {
        trek.status == .conquered
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                headerView
                weatherCapsuleView
                notesView
                photoStripView
                footerView
            }
            .padding(DS.Space.lg)
            .background(
                isSelected ? Color.white.opacity(0.06) : DS.Color.surface,
                in: RoundedRectangle(cornerRadius: DS.Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(trek.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)

                    if isConquered {
                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                            Text("SUMMITED")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.15), in: Capsule())
                    }
                }

                Text("\(trek.region), \(trek.country)")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(trek.elevationMeters).formatted()) m")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cyan)
                Text("\(Int(trek.elevationFeet).formatted()) ft")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    private var weatherCapsuleView: some View {
        HStack(spacing: 6) {
            Image(systemName: weatherIcon(for: trek))
                .font(.system(size: 10))
                .foregroundStyle(Color.cyan)
            Text(weatherCondition(for: trek))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 5))
    }

    @ViewBuilder
    private var notesView: some View {
        if !trek.personalNotes.isEmpty {
            Text(trek.personalNotes)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.textSecondary)
                .lineLimit(3)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    @ViewBuilder
    private var photoStripView: some View {
        if !trek.photoFileNames.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(trek.photoFileNames.prefix(4).enumerated()), id: \.offset) { index, fileName in
                        if let image = TrekMediaManager.shared.loadPhoto(fileName: fileName) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .onTapGesture {
                                    onOpenQuickLook(fileName, index)
                                }
                        }
                    }
                }
            }
        }
    }

    private var footerView: some View {
        HStack(spacing: DS.Space.lg) {
            HStack(spacing: 4) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 10))
                Text(trek.difficulty.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color.orange)

            if let gain = trek.elevationGainMeters {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                    Text("+\(Int(gain))m vertical")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Color.purple)
            }

            if let d = trek.trailDistanceKm {
                HStack(spacing: 3) {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 10))
                    Text(String(format: "%.1f km", d))
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Color.green)
            }

            Spacer()

            Button(action: onOpenPassport) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.richtext.fill")
                    Text("Passport")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)

            Button(action: onToggleStatus) {
                HStack(spacing: 4) {
                    Image(systemName: isConquered ? "checkmark.seal.fill" : "plus.circle")
                    Text(isConquered ? "Conquered" : "Mark Conquered")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isConquered ? Color.cyan : DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func weatherIcon(for trek: TrekRecord) -> String {
        if trek.elevationMeters >= 5000 {
            return "wind.snow"
        } else if trek.elevationMeters >= 3000 {
            return "thermometer.snowflake"
        } else {
            return "sun.max.fill"
        }
    }

    private func weatherCondition(for trek: TrekRecord) -> String {
        if trek.elevationMeters >= 8000 {
            return "Extreme Altitude: -32°C · Hurricane Ridge"
        } else if trek.elevationMeters >= 4000 {
            return "Alpine Frost: -14°C · 35 km/h Wind"
        } else if trek.elevationMeters >= 2500 {
            return "Clear Skies: -4°C · Optimal Visibility"
        } else {
            return "Temperate Ridge: +8°C · Moderate Breeze"
        }
    }
}
