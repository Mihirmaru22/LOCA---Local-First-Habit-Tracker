import SwiftUI

// MARK: - BackgroundCategory

enum BackgroundCategory: String, CaseIterable, Identifiable {
    case anime    = "🌸 Anime"
    case library  = "📚 Library"
    case nature   = "🌿 Nature"
    case animals  = "🐱 Animals"
    case cafe     = "☕ Cafe"
    case desk     = "🖥 Desk"
    case city     = "🏙 City"
    case colors   = "🌈 Colors"
    case other    = "✨ Other"

    var id: String { rawValue }
    
    var shortTitle: String {
        switch self {
        case .anime: return "Anime"
        case .library: return "Library"
        case .nature: return "Nature"
        case .animals: return "Animals"
        case .cafe: return "Cafe"
        case .desk: return "Desk"
        case .city: return "City"
        case .colors: return "Colors"
        case .other: return "Other"
        }
    }
}

// MARK: - BackgroundPreset

struct BackgroundPreset: Identifiable {
    let id: String
    let category: BackgroundCategory
    let title: String
    let colors: [Color]
    let symbolName: String
}

// MARK: - BackgroundPickerPanel

struct BackgroundPickerPanel: View {

    @Binding var isPresented: Bool
    @Binding var selectedPresetID: String
    @Binding var youtubeVideoID: String?
    @Binding var youtubeVolume: Double

    @State private var selectedCategory: BackgroundCategory = .anime
    @State private var youtubeInputText: String = ""

    // Static Presets Library
    private static let presets: [BackgroundPreset] = [
        // Anime
        BackgroundPreset(id: "anime_1", category: .anime, title: "Cherry Shrine", colors: [Color(red: 0.95, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.35, blue: 0.75)], symbolName: "sparkles"),
        BackgroundPreset(id: "anime_2", category: .anime, title: "Lo-Fi Study Girl", colors: [Color(red: 0.85, green: 0.35, blue: 0.45), Color(red: 0.25, green: 0.15, blue: 0.45)], symbolName: "pencil.and.outline"),
        BackgroundPreset(id: "anime_3", category: .anime, title: "Tokyo Rain Sunset", colors: [Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.95, green: 0.45, blue: 0.65)], symbolName: "cloud.sun.rain.fill"),
        BackgroundPreset(id: "anime_4", category: .anime, title: "Valley of Wind", colors: [Color(red: 0.25, green: 0.75, blue: 0.55), Color(red: 0.15, green: 0.35, blue: 0.65)], symbolName: "wind"),
        BackgroundPreset(id: "anime_5", category: .anime, title: "Night Market", colors: [Color(red: 0.95, green: 0.45, blue: 0.25), Color(red: 0.15, green: 0.15, blue: 0.35)], symbolName: "lantern.fill"),
        BackgroundPreset(id: "anime_6", category: .anime, title: "Sky Island Castle", colors: [Color(red: 0.45, green: 0.75, blue: 0.95), Color(red: 0.25, green: 0.45, blue: 0.85)], symbolName: "building.columns.fill"),

        // Library
        BackgroundPreset(id: "lib_1", category: .library, title: "Oxford Bodleian", colors: [Color(red: 0.35, green: 0.25, blue: 0.15), Color(red: 0.15, green: 0.10, blue: 0.05)], symbolName: "books.vertical.fill"),
        BackgroundPreset(id: "lib_2", category: .library, title: "Grand Reading Hall", colors: [Color(red: 0.45, green: 0.35, blue: 0.20), Color(red: 0.20, green: 0.15, blue: 0.10)], symbolName: "lamp.table.fill"),
        BackgroundPreset(id: "lib_3", category: .library, title: "Midnight Archives", colors: [Color(red: 0.15, green: 0.20, blue: 0.30), Color(red: 0.05, green: 0.08, blue: 0.15)], symbolName: "moon.stars.fill"),

        // Nature
        BackgroundPreset(id: "nat_1", category: .nature, title: "Alpine Mist", colors: [Color(red: 0.25, green: 0.55, blue: 0.65), Color(red: 0.15, green: 0.30, blue: 0.40)], symbolName: "mountain.2.fill"),
        BackgroundPreset(id: "nat_2", category: .nature, title: "Deep Bamboo Forest", colors: [Color(red: 0.15, green: 0.55, blue: 0.35), Color(red: 0.05, green: 0.25, blue: 0.15)], symbolName: "tree.fill"),
        BackgroundPreset(id: "nat_3", category: .nature, title: "Nordic Fjord", colors: [Color(red: 0.20, green: 0.40, blue: 0.60), Color(red: 0.10, green: 0.20, blue: 0.30)], symbolName: "water.waves"),

        // Animals
        BackgroundPreset(id: "ani_1", category: .animals, title: "Sleeping Cat Cafe", colors: [Color(red: 0.85, green: 0.65, blue: 0.45), Color(red: 0.45, green: 0.25, blue: 0.15)], symbolName: "cat.fill"),
        BackgroundPreset(id: "ani_2", category: .animals, title: "Golden Retriever Fire", colors: [Color(red: 0.75, green: 0.45, blue: 0.25), Color(red: 0.35, green: 0.15, blue: 0.05)], symbolName: "dog.fill"),
        BackgroundPreset(id: "ani_3", category: .animals, title: "Winter Deer", colors: [Color(red: 0.55, green: 0.65, blue: 0.75), Color(red: 0.25, green: 0.35, blue: 0.45)], symbolName: "pawprint.fill"),

        // Cafe
        BackgroundPreset(id: "cafe_1", category: .cafe, title: "Kyoto Matcha Bar", colors: [Color(red: 0.45, green: 0.60, blue: 0.35), Color(red: 0.20, green: 0.30, blue: 0.15)], symbolName: "cup.and.saucer.fill"),
        BackgroundPreset(id: "cafe_2", category: .cafe, title: "Parisian Rain Bistro", colors: [Color(red: 0.65, green: 0.45, blue: 0.35), Color(red: 0.30, green: 0.18, blue: 0.12)], symbolName: "mug.fill"),
        BackgroundPreset(id: "cafe_3", category: .cafe, title: "Night Espresso Lounge", colors: [Color(red: 0.35, green: 0.20, blue: 0.15), Color(red: 0.12, green: 0.08, blue: 0.05)], symbolName: "takeoutbag.and.cup.and.straw.fill"),

        // Desk
        BackgroundPreset(id: "desk_1", category: .desk, title: "Minimalist Apple Studio", colors: [Color(red: 0.25, green: 0.25, blue: 0.30), Color(red: 0.10, green: 0.10, blue: 0.12)], symbolName: "display"),
        BackgroundPreset(id: "desk_2", category: .desk, title: "Cyberpunk Terminal", colors: [Color(red: 0.10, green: 0.85, blue: 0.65), Color(red: 0.05, green: 0.10, blue: 0.20)], symbolName: "terminal.fill"),
        BackgroundPreset(id: "desk_3", category: .desk, title: "Writer's Typewriter", colors: [Color(red: 0.75, green: 0.65, blue: 0.50), Color(red: 0.30, green: 0.25, blue: 0.20)], symbolName: "keyboard.fill"),

        // City
        BackgroundPreset(id: "city_1", category: .city, title: "Tokyo Skytree Dawn", colors: [Color(red: 0.45, green: 0.65, blue: 0.95), Color(red: 0.95, green: 0.55, blue: 0.65)], symbolName: "building.2.fill"),
        BackgroundPreset(id: "city_2", category: .city, title: "Manhattan Midnight", colors: [Color(red: 0.15, green: 0.20, blue: 0.35), Color(red: 0.05, green: 0.08, blue: 0.15)], symbolName: "building.fill"),
        BackgroundPreset(id: "city_3", category: .city, title: "Hong Kong Neon Harbor", colors: [Color(red: 0.95, green: 0.25, blue: 0.55), Color(red: 0.15, green: 0.45, blue: 0.85)], symbolName: "tram.fill"),

        // Colors
        BackgroundPreset(id: "col_1", category: .colors, title: "Obsidian Deep Velvet", colors: [Color(red: 0.10, green: 0.10, blue: 0.15), Color(red: 0.02, green: 0.02, blue: 0.05)], symbolName: "circle.fill"),
        BackgroundPreset(id: "col_2", category: .colors, title: "Nordic Auroral Glow", colors: [Color(red: 0.20, green: 0.80, blue: 0.65), Color(red: 0.10, green: 0.30, blue: 0.60)], symbolName: "sparkles"),
        BackgroundPreset(id: "col_3", category: .colors, title: "Sunset Horizon", colors: [Color(red: 0.95, green: 0.45, blue: 0.30), Color(red: 0.35, green: 0.15, blue: 0.45)], symbolName: "sunset.fill"),

        // Other
        BackgroundPreset(id: "oth_1", category: .other, title: "Deep Space Nebula", colors: [Color(red: 0.35, green: 0.15, blue: 0.65), Color(red: 0.05, green: 0.05, blue: 0.15)], symbolName: "globe.americas.fill"),
        BackgroundPreset(id: "oth_2", category: .other, title: "Himalayan High Peak", colors: [Color(red: 0.30, green: 0.85, blue: 0.80), Color(red: 0.10, green: 0.20, blue: 0.30)], symbolName: "flag.fill")
    ]

    private var filteredPresets: [BackgroundPreset] {
        Self.presets.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack {
                Label("Background", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    isPresented = false
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // Horizontal Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(BackgroundCategory.allCases) { category in
                        let isSelected = selectedCategory == category
                        Button {
                            selectedCategory = category
                            Haptics.impact(.light)
                        } label: {
                            Text(category.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isSelected ? Color.blue : Color.white.opacity(0.1))
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 3-Column Thumbnail Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(filteredPresets) { preset in
                        let isSelected = selectedPresetID == preset.id && youtubeVideoID == nil

                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                selectedPresetID = preset.id
                                youtubeVideoID = nil
                            }
                            PlutoSoundEngine.shared.play(.tabSwitch)
                            Haptics.impact(.light)
                        } label: {
                            ZStack {
                                LinearGradient(colors: preset.colors, startPoint: .topLeading, endPoint: .bottomTrailing)

                                Image(systemName: preset.symbolName)
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.6))

                                if isSelected {
                                    ZStack {
                                        Color.black.opacity(0.25)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .heavy))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 210)

            Divider().overlay(Color.white.opacity(0.12))

            // YouTube Video Embed Section
            VStack(alignment: .leading, spacing: 8) {
                Label("YouTube Video", systemImage: "play.rectangle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.red)

                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))

                    TextField("Paste a YouTube link here", text: $youtubeInputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .onSubmit {
                            applyYouTubeURL()
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))

                // Video Sound Slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Original video sound")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Image(systemName: youtubeVolume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Slider(value: $youtubeVolume, in: 0.0...1.0)
                        .tint(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(width: 310)
        .background(
            Color.black.opacity(0.72)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
    }

    private func applyYouTubeURL() {
        let trimmed = youtubeInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = extractYouTubeID(from: trimmed) {
            withAnimation(.easeInOut(duration: 0.4)) {
                youtubeVideoID = id
            }
            PlutoSoundEngine.shared.play(.checkmark)
            Haptics.notify(.success)
        }
    }

    private func extractYouTubeID(from urlString: String) -> String? {
        if urlString.contains("youtu.be/") {
            return urlString.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }
        if urlString.contains("watch?v=") {
            return urlString.components(separatedBy: "watch?v=").last?.components(separatedBy: "&").first
        }
        if urlString.count == 11 && !urlString.contains("/") {
            return urlString
        }
        return nil
    }
}
