import SwiftUI
import SwiftData
import MapKit

// MARK: - TrekPanoramicCard (Used in Layout 2: Panoramic Horizon)

struct TrekPanoramicCard: View {
    let trek: TrekRecord
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleStatus: () -> Void

    private var isConquered: Bool {
        trek.status == .conquered
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Header: Name & Conquered Icon
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trek.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineLimit(1)

                        Text("\(trek.region), \(trek.country)")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: onToggleStatus) {
                        Image(systemName: isConquered ? "trophy.fill" : "circle")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isConquered ? Color.cyan : DS.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Telemetry Badges Strip
                HStack(spacing: 6) {
                    // Altitude
                    HStack(spacing: 3) {
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 9))
                        Text("\(Int(trek.elevationMeters).formatted()) m")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))

                    // Difficulty
                    Text(trek.difficulty.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))

                    if let gain = trek.elevationGainMeters {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8))
                            Text("+\(Int(gain))m")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color.purple)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            .padding(DS.Space.md)
            .frame(width: 260, height: 110)
            .background(
                isSelected ? Color.white.opacity(0.08) : DS.Color.surfaceRecessed,
                in: RoundedRectangle(cornerRadius: DS.Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TrekBentoCard (Used in Layout 3: Alpine Bento Matrix)

struct TrekBentoCard: View {
    let trek: TrekRecord
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleStatus: () -> Void

    private var isConquered: Bool {
        trek.status == .conquered
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isConquered ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
                            .frame(width: 28, height: 28)
                        Image(systemName: isConquered ? "trophy.fill" : "mountain.2")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isConquered ? Color.cyan : DS.Color.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(trek.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineLimit(1)
                        Text("\(trek.region), \(trek.country)")
                            .font(DS.Text.footnote)
                            .foregroundStyle(DS.Color.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: onToggleStatus) {
                        Image(systemName: isConquered ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(isConquered ? Color.green : DS.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text("\(Int(trek.elevationMeters).formatted()) m")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cyan)

                    Spacer()

                    if let d = trek.trailDistanceKm {
                        Text(String(format: "%.1f km", d))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
            .padding(DS.Space.md)
            .background(
                isSelected ? Color.cyan.opacity(0.1) : DS.Color.surfaceRecessed,
                in: RoundedRectangle(cornerRadius: DS.Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(isSelected ? Color.cyan.opacity(0.8) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TrekEditorialCard (Used in Layout 4: Editorial Cards)

struct TrekEditorialCard: View {
    let trek: TrekRecord
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleStatus: () -> Void
    let onOpenQuickLook: (String, Int) -> Void

    private var isConquered: Bool {
        trek.status == .conquered
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                // Header Banner Strip
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

                    // Altitude Badge
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int(trek.elevationMeters).formatted()) m")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.cyan)
                        Text("\(Int(trek.elevationFeet).formatted()) ft")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }

                // Field Notes / Reflection
                if !trek.personalNotes.isEmpty {
                    Text(trek.personalNotes)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineLimit(3)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                }

                // Photos Strip if present
                if !trek.photoFileNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(trek.photoFileNames.prefix(4).enumerated()), id: \.offset) { index, fileName in
                                if let image = TrekMediaManager.shared.loadImage(named: fileName) {
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

                // Telemetry Footer
                HStack(spacing: DS.Space.lg) {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                            .font(.system(size: 10))
                        Text(trek.difficulty.rawValue)
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
}
