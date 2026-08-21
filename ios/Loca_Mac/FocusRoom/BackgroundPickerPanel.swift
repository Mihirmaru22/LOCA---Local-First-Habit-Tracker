//
//  BackgroundPickerPanel.swift
//  PLUTO
//
//  Curated 5-Preset High-Aesthetic Wallpaper Console.
//  Ultra-low memory footprint with downsampled hardware caching.
//

import SwiftUI

// MARK: - BackgroundPreset

struct BackgroundPreset: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let photoID: String
    let fallbackColors: [Color]

    var thumbnailURL: String {
        "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=320&q=65"
    }

    var fullImageURL: String {
        "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=1920&q=75"
    }
}

// MARK: - BackgroundPickerPanel

struct BackgroundPickerPanel: View {

    @Binding var isPresented: Bool
    @Binding var selectedPresetID: String

    // Curated 5 High-Aesthetic Open Source Wallpaper Presets
    static let presets: [BackgroundPreset] = [
        BackgroundPreset(
            id: "nat_forest",
            title: "Misty Pine Forest",
            emoji: "🌲",
            photoID: "photo-1470071459604-3b5ec3a7fe05",
            fallbackColors: [Color(red: 0.15, green: 0.55, blue: 0.35), Color(red: 0.05, green: 0.25, blue: 0.15)]
        ),
        BackgroundPreset(
            id: "cafe_rain",
            title: "Rainy Window Cafe",
            emoji: "☕",
            photoID: "photo-1607604276583-eef5d076aa5f",
            fallbackColors: [Color(red: 0.45, green: 0.35, blue: 0.25), Color(red: 0.20, green: 0.12, blue: 0.08)]
        ),
        BackgroundPreset(
            id: "lib_hall",
            title: "Grand Library Hall",
            emoji: "📚",
            photoID: "photo-1521587760476-6c12a4b040da",
            fallbackColors: [Color(red: 0.35, green: 0.25, blue: 0.15), Color(red: 0.15, green: 0.10, blue: 0.05)]
        ),
        BackgroundPreset(
            id: "cosmic_night",
            title: "Cosmic Night Sky",
            emoji: "🌌",
            photoID: "photo-1446776811953-b23d57bd21aa",
            fallbackColors: [Color(red: 0.35, green: 0.15, blue: 0.65), Color(red: 0.05, green: 0.05, blue: 0.15)]
        ),
        BackgroundPreset(
            id: "zen_peak",
            title: "High Alpine Peak",
            emoji: "🏔️",
            photoID: "photo-1509114397022-ed747cca3f65",
            fallbackColors: [Color(red: 0.40, green: 0.60, blue: 0.80), Color(red: 0.15, green: 0.25, blue: 0.35)]
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            Text("Curated serene study backdrops")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.45))
            Divider().opacity(0.25)
            presetListView
        }
        .padding(16)
        .frame(width: 310)
        .background(
            Color.black.opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 10)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)

                Text("WALLPAPERS (5 Presets)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                isPresented = false
                Haptics.impact(.light)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
        }
    }

    private var presetListView: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Self.presets) { preset in
                    presetRow(preset: preset)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxHeight: 280)
    }

    private func presetRow(preset: BackgroundPreset) -> some View {
        let isSelected = selectedPresetID == preset.id

        return Button {
            withAnimation(.easeInOut(duration: 0.35)) {
                selectedPresetID = preset.id
            }
            PlutoSoundEngine.shared.play(.tabSwitch)
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 12) {
                thumbnailView(preset: preset, isSelected: isSelected)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(preset.emoji)
                            .font(.system(size: 12))
                        Text(preset.title)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(Color.white)
                    }

                    Text(isSelected ? "Active Backdrop" : "Click to apply")
                        .font(.system(size: 9.5))
                        .foregroundStyle(isSelected ? Color.blue.opacity(0.9) : Color.white.opacity(0.40))
                }

                Spacer()
            }
            .padding(6)
            .background(
                isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.02),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.35) : Color.white.opacity(0.05), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func thumbnailView(preset: BackgroundPreset, isSelected: Bool) -> some View {
        ZStack {
            FocusCachedImageView(
                urlString: preset.thumbnailURL,
                fallbackColors: preset.fallbackColors
            )
            .frame(width: 72, height: 48)
            .clipped()

            if isSelected {
                Color.black.opacity(0.3)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blue)
            }
        }
        .frame(width: 72, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 0.8)
        )
    }
}
