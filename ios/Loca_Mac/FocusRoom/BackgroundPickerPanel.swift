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
    let photoID: String
    let fallbackColors: [Color]

    var thumbnailURL: String {
        "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=260&q=70"
    }

    var fullImageURL: String {
        "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=2560&q=85"
    }
}

// MARK: - BackgroundPickerPanel

struct BackgroundPickerPanel: View {

    @Binding var isPresented: Bool
    @Binding var selectedPresetID: String
    @Binding var youtubeVideoID: String?
    @Binding var youtubeVolume: Double

    @State private var selectedCategory: BackgroundCategory = .anime
    @State private var youtubeInputText: String = ""

    // 54 High-Res Open Source Photo Presets (Unsplash Library)
    static let presets: [BackgroundPreset] = [
        // 🌸 Anime & Aesthetic Lofi
        BackgroundPreset(id: "anime_1", category: .anime, title: "Lofi Study Girl", photoID: "photo-1578632767115-351597cf2477", fallbackColors: [Color(red: 0.35, green: 0.25, blue: 0.55), Color(red: 0.15, green: 0.10, blue: 0.25)]),
        BackgroundPreset(id: "anime_2", category: .anime, title: "Cherry Blossom Shrine", photoID: "photo-1534447677768-be436bb09401", fallbackColors: [Color(red: 0.95, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.35, blue: 0.75)]),
        BackgroundPreset(id: "anime_3", category: .anime, title: "Tokyo Sunset Street", photoID: "photo-1509198397868-475647b2a1e5", fallbackColors: [Color(red: 0.95, green: 0.45, blue: 0.35), Color(red: 0.25, green: 0.15, blue: 0.45)]),
        BackgroundPreset(id: "anime_4", category: .anime, title: "Magical Sunset Valley", photoID: "photo-1518709268805-4e9042af9f23", fallbackColors: [Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.95, green: 0.45, blue: 0.65)]),
        BackgroundPreset(id: "anime_5", category: .anime, title: "Dreamy Twilight Clouds", photoID: "photo-1513836279014-a89f7a76ae86", fallbackColors: [Color(red: 0.25, green: 0.35, blue: 0.65), Color(red: 0.10, green: 0.15, blue: 0.35)]),
        BackgroundPreset(id: "anime_6", category: .anime, title: "Rainy Window Coffee", photoID: "photo-1607604276583-eef5d076aa5f", fallbackColors: [Color(red: 0.25, green: 0.25, blue: 0.35), Color(red: 0.10, green: 0.10, blue: 0.15)]),

        // 📚 Library & Classic Reading Halls
        BackgroundPreset(id: "lib_1", category: .library, title: "Grand Bodleian Hall", photoID: "photo-1521587760476-6c12a4b040da", fallbackColors: [Color(red: 0.35, green: 0.25, blue: 0.15), Color(red: 0.15, green: 0.10, blue: 0.05)]),
        BackgroundPreset(id: "lib_2", category: .library, title: "Vintage Reading Table", photoID: "photo-1507842229440-a3e9c5a1a1f0", fallbackColors: [Color(red: 0.45, green: 0.35, blue: 0.20), Color(red: 0.20, green: 0.15, blue: 0.10)]),
        BackgroundPreset(id: "lib_3", category: .library, title: "Midnight Archives", photoID: "photo-1541963463532-d68292c34b19", fallbackColors: [Color(red: 0.15, green: 0.20, blue: 0.30), Color(red: 0.05, green: 0.08, blue: 0.15)]),
        BackgroundPreset(id: "lib_4", category: .library, title: "Bookshelf Tunnel", photoID: "photo-1481627834876-b7833e8f5570", fallbackColors: [Color(red: 0.30, green: 0.20, blue: 0.15), Color(red: 0.10, green: 0.05, blue: 0.05)]),
        BackgroundPreset(id: "lib_5", category: .library, title: "Classic Vaulted Hall", photoID: "photo-1568667256549-094345857637", fallbackColors: [Color(red: 0.40, green: 0.30, blue: 0.20), Color(red: 0.15, green: 0.10, blue: 0.08)]),
        BackgroundPreset(id: "lib_6", category: .library, title: "Sunlit Stacks", photoID: "photo-1524995997946-a1c2e315a42f", fallbackColors: [Color(red: 0.50, green: 0.40, blue: 0.30), Color(red: 0.20, green: 0.15, blue: 0.10)]),

        // 🌿 Nature & Serene Landscapes
        BackgroundPreset(id: "nat_1", category: .nature, title: "Yosemite Alpine Mist", photoID: "photo-1506744038136-46273834b3fb", fallbackColors: [Color(red: 0.25, green: 0.55, blue: 0.65), Color(red: 0.15, green: 0.30, blue: 0.40)]),
        BackgroundPreset(id: "nat_2", category: .nature, title: "Misty Pine Forest", photoID: "photo-1470071459604-3b5ec3a7fe05", fallbackColors: [Color(red: 0.15, green: 0.55, blue: 0.35), Color(red: 0.05, green: 0.25, blue: 0.15)]),
        BackgroundPreset(id: "nat_3", category: .nature, title: "Mountain Wilderness", photoID: "photo-1511497584788-87676104235f", fallbackColors: [Color(red: 0.20, green: 0.40, blue: 0.60), Color(red: 0.10, green: 0.20, blue: 0.30)]),
        BackgroundPreset(id: "nat_4", category: .nature, title: "Lush Mountain Valley", photoID: "photo-1426604966848-d7adac402bff", fallbackColors: [Color(red: 0.30, green: 0.60, blue: 0.40), Color(red: 0.10, green: 0.25, blue: 0.15)]),
        BackgroundPreset(id: "nat_5", category: .nature, title: "Golden Hour Meadow", photoID: "photo-1472214103451-9374bd1c798e", fallbackColors: [Color(red: 0.85, green: 0.65, blue: 0.35), Color(red: 0.35, green: 0.20, blue: 0.10)]),
        BackgroundPreset(id: "nat_6", category: .nature, title: "Starry Snow Peak", photoID: "photo-1519681393784-d120267933ba", fallbackColors: [Color(red: 0.15, green: 0.20, blue: 0.45), Color(red: 0.05, green: 0.08, blue: 0.15)]),

        // 🐱 Animals & Cozy Companions
        BackgroundPreset(id: "ani_1", category: .animals, title: "Cozy Sleeping Cat", photoID: "photo-1514888286974-6c03e2ca1dba", fallbackColors: [Color(red: 0.85, green: 0.65, blue: 0.45), Color(red: 0.45, green: 0.25, blue: 0.15)]),
        BackgroundPreset(id: "ani_2", category: .animals, title: "Golden Retriever Study", photoID: "photo-1543466835-00a7907e9de1", fallbackColors: [Color(red: 0.75, green: 0.45, blue: 0.25), Color(red: 0.35, green: 0.15, blue: 0.05)]),
        BackgroundPreset(id: "ani_3", category: .animals, title: "Sunlit Kitten", photoID: "photo-1535268647677-300dbf3d78d1", fallbackColors: [Color(red: 0.90, green: 0.70, blue: 0.50), Color(red: 0.40, green: 0.25, blue: 0.15)]),
        BackgroundPreset(id: "ani_4", category: .animals, title: "Forest Deer", photoID: "photo-1484406566174-9da000fda645", fallbackColors: [Color(red: 0.45, green: 0.55, blue: 0.35), Color(red: 0.15, green: 0.25, blue: 0.15)]),
        BackgroundPreset(id: "ani_5", category: .animals, title: "Fluffy White Cat", photoID: "photo-1574158622682-e40e69881006", fallbackColors: [Color(red: 0.75, green: 0.75, blue: 0.85), Color(red: 0.25, green: 0.25, blue: 0.35)]),
        BackgroundPreset(id: "ani_6", category: .animals, title: "Rainy Window Puppy", photoID: "photo-1537151625747-768eb6cf92b2", fallbackColors: [Color(red: 0.55, green: 0.45, blue: 0.35), Color(red: 0.20, green: 0.15, blue: 0.10)]),

        // ☕ Cafe & Coffee Roasters
        BackgroundPreset(id: "cafe_1", category: .cafe, title: "Cozy Kyoto Coffee", photoID: "photo-1501339847302-ac426a4a7cbb", fallbackColors: [Color(red: 0.45, green: 0.35, blue: 0.25), Color(red: 0.20, green: 0.12, blue: 0.08)]),
        BackgroundPreset(id: "cafe_2", category: .cafe, title: "Window Seat Espresso", photoID: "photo-1554118811-1e0d58224f24", fallbackColors: [Color(red: 0.65, green: 0.45, blue: 0.35), Color(red: 0.30, green: 0.18, blue: 0.12)]),
        BackgroundPreset(id: "cafe_3", category: .cafe, title: "Latte Art Table", photoID: "photo-1442512595331-e89e73853f31", fallbackColors: [Color(red: 0.75, green: 0.55, blue: 0.40), Color(red: 0.35, green: 0.20, blue: 0.12)]),
        BackgroundPreset(id: "cafe_4", category: .cafe, title: "European Rain Bistro", photoID: "photo-1521017432531-fbd92d768814", fallbackColors: [Color(red: 0.50, green: 0.40, blue: 0.30), Color(red: 0.20, green: 0.15, blue: 0.10)]),
        BackgroundPreset(id: "cafe_5", category: .cafe, title: "Night Espresso Lounge", photoID: "photo-1559925393-8be0ec4767c8", fallbackColors: [Color(red: 0.35, green: 0.20, blue: 0.15), Color(red: 0.12, green: 0.08, blue: 0.05)]),
        BackgroundPreset(id: "cafe_6", category: .cafe, title: "Morning Roastery", photoID: "photo-1495474472287-4d71bcdd2085", fallbackColors: [Color(red: 0.80, green: 0.60, blue: 0.40), Color(red: 0.30, green: 0.18, blue: 0.10)]),

        // 🖥 Desk & Minimalist Workspace
        BackgroundPreset(id: "desk_1", category: .desk, title: "Clean Apple Studio", photoID: "photo-1527443224154-c4a3942d3acf", fallbackColors: [Color(red: 0.35, green: 0.35, blue: 0.40), Color(red: 0.10, green: 0.10, blue: 0.15)]),
        BackgroundPreset(id: "desk_2", category: .desk, title: "Dark Tech Studio", photoID: "photo-1518770660439-4636190af475", fallbackColors: [Color(red: 0.20, green: 0.25, blue: 0.35), Color(red: 0.05, green: 0.08, blue: 0.12)]),
        BackgroundPreset(id: "desk_3", category: .desk, title: "Sunlit Corporate Office", photoID: "photo-1497215728101-856f4ea42174", fallbackColors: [Color(red: 0.85, green: 0.85, blue: 0.90), Color(red: 0.30, green: 0.30, blue: 0.35)]),
        BackgroundPreset(id: "desk_4", category: .desk, title: "Designer iPad Desk", photoID: "photo-1581291518655-9523c932694b", fallbackColors: [Color(red: 0.70, green: 0.60, blue: 0.50), Color(red: 0.25, green: 0.20, blue: 0.15)]),
        BackgroundPreset(id: "desk_5", category: .desk, title: "High-Rise Glass Office", photoID: "photo-1486406146926-c627a92ad1ab", fallbackColors: [Color(red: 0.40, green: 0.50, blue: 0.60), Color(red: 0.15, green: 0.20, blue: 0.25)]),
        BackgroundPreset(id: "desk_6", category: .desk, title: "Warm Wooden Desk", photoID: "photo-1593062096033-9a26b09da705", fallbackColors: [Color(red: 0.60, green: 0.45, blue: 0.30), Color(red: 0.20, green: 0.15, blue: 0.10)]),

        // 🏙 City & Urban Skylines
        BackgroundPreset(id: "city_1", category: .city, title: "Tokyo Shinjuku Dusk", photoID: "photo-1503899036084-c55cdd92da26", fallbackColors: [Color(red: 0.45, green: 0.65, blue: 0.95), Color(red: 0.95, green: 0.55, blue: 0.65)]),
        BackgroundPreset(id: "city_2", category: .city, title: "Chicago Skyline", photoID: "photo-1477959858617-67f30bc75b82", fallbackColors: [Color(red: 0.30, green: 0.40, blue: 0.55), Color(red: 0.10, green: 0.15, blue: 0.25)]),
        BackgroundPreset(id: "city_3", category: .city, title: "Manhattan Midnight", photoID: "photo-1519501025264-65ba15a82390", fallbackColors: [Color(red: 0.15, green: 0.20, blue: 0.35), Color(red: 0.05, green: 0.08, blue: 0.15)]),
        BackgroundPreset(id: "city_4", category: .city, title: "Neon City Rain", photoID: "photo-1514565131-fce0801e5785", fallbackColors: [Color(red: 0.85, green: 0.25, blue: 0.65), Color(red: 0.15, green: 0.10, blue: 0.35)]),
        BackgroundPreset(id: "city_5", category: .city, title: "Los Angeles Sunset", photoID: "photo-1444723121867-7a241cacace9", fallbackColors: [Color(red: 0.95, green: 0.55, blue: 0.35), Color(red: 0.35, green: 0.15, blue: 0.35)]),
        BackgroundPreset(id: "city_6", category: .city, title: "City Skyscraper Upward", photoID: "photo-1480714378408-67cf0d13bc1b", fallbackColors: [Color(red: 0.25, green: 0.35, blue: 0.50), Color(red: 0.08, green: 0.12, blue: 0.20)]),

        // 🌈 Colors & Deep Mesh Gradients
        BackgroundPreset(id: "col_1", category: .colors, title: "Velvet Flow Abstract", photoID: "photo-1579783902614-a3fb3927b675", fallbackColors: [Color(red: 0.65, green: 0.25, blue: 0.45), Color(red: 0.15, green: 0.08, blue: 0.25)]),
        BackgroundPreset(id: "col_2", category: .colors, title: "Deep Space Nebula", photoID: "photo-1550684848-fac1c5b4e853", fallbackColors: [Color(red: 0.25, green: 0.15, blue: 0.45), Color(red: 0.05, green: 0.02, blue: 0.10)]),
        BackgroundPreset(id: "col_3", category: .colors, title: "Turquoise Sunset", photoID: "photo-1507525428034-b723cf961d3e", fallbackColors: [Color(red: 0.20, green: 0.70, blue: 0.80), Color(red: 0.90, green: 0.45, blue: 0.35)]),
        BackgroundPreset(id: "col_4", category: .colors, title: "Pastel Twilight Aura", photoID: "photo-1534447677768-be436bb09401", fallbackColors: [Color(red: 0.85, green: 0.65, blue: 0.85), Color(red: 0.40, green: 0.30, blue: 0.60)]),
        BackgroundPreset(id: "col_5", category: .colors, title: "Liquid Indigo Chrome", photoID: "photo-1518837695005-2083093ee35b", fallbackColors: [Color(red: 0.15, green: 0.35, blue: 0.75), Color(red: 0.05, green: 0.10, blue: 0.25)]),
        BackgroundPreset(id: "col_6", category: .colors, title: "Obsidian Gold Ripple", photoID: "photo-1508739773434-c26b3d09e071", fallbackColors: [Color(red: 0.10, green: 0.10, blue: 0.15), Color(red: 0.02, green: 0.02, blue: 0.05)]),

        // ✨ Other & Cosmological
        BackgroundPreset(id: "oth_1", category: .other, title: "Earth Orbital Satellite", photoID: "photo-1451187580459-43490279c0fa", fallbackColors: [Color(red: 0.20, green: 0.45, blue: 0.85), Color(red: 0.05, green: 0.05, blue: 0.15)]),
        BackgroundPreset(id: "oth_2", category: .other, title: "Cosmic Constellation", photoID: "photo-1446776811953-b23d57bd21aa", fallbackColors: [Color(red: 0.35, green: 0.15, blue: 0.65), Color(red: 0.05, green: 0.05, blue: 0.15)]),
        BackgroundPreset(id: "oth_3", category: .other, title: "High Alpine Sea of Clouds", photoID: "photo-1509114397022-ed747cca3f65", fallbackColors: [Color(red: 0.40, green: 0.60, blue: 0.80), Color(red: 0.15, green: 0.25, blue: 0.35)]),
        BackgroundPreset(id: "oth_4", category: .other, title: "Misty Lake Bridge", photoID: "photo-1470240731273-7821a6eeb6bd", fallbackColors: [Color(red: 0.30, green: 0.45, blue: 0.40), Color(red: 0.10, green: 0.18, blue: 0.15)]),
        BackgroundPreset(id: "oth_5", category: .other, title: "Pine Canopy Skyward", photoID: "photo-1513836279014-a89f7a76ae86", fallbackColors: [Color(red: 0.20, green: 0.50, blue: 0.35), Color(red: 0.08, green: 0.20, blue: 0.15)]),
        BackgroundPreset(id: "oth_6", category: .other, title: "Golden Canyon Horizon", photoID: "photo-1500530855697-b586d89ba3ee", fallbackColors: [Color(red: 0.90, green: 0.55, blue: 0.30), Color(red: 0.35, green: 0.18, blue: 0.10)])
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

            // 3-Column Photo Thumbnail Grid
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
                                // Async Thumbnail Image with Fallback Gradient
                                AsyncImage(url: URL(string: preset.thumbnailURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        LinearGradient(colors: preset.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    case .empty:
                                        ZStack {
                                            LinearGradient(colors: preset.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                            ProgressView().scaleEffect(0.6).tint(.white)
                                        }
                                    @unknown default:
                                        LinearGradient(colors: preset.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    }
                                }
                                .frame(height: 64)
                                .clipped()

                                if isSelected {
                                    ZStack {
                                        Color.black.opacity(0.35)
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20, weight: .heavy))
                                            .foregroundStyle(Color.blue)
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
                        .help(preset.title)
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
        let pattern = "(?<=watch\\?v=|/videos/|/embed/|youtu.be/|/v/|/e/|watch\\?feature=player_embedded&v=|%2Fvideos%2F|embed%2F|youtu.be%2F|%2Fv%2F)[^#&?\\n]*"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.utf16.count)),
           let range = Range(match.range, in: urlString) {
            let candidate = String(urlString[range])
            if candidate.count == 11 { return candidate }
        }
        if urlString.count == 11 && !urlString.contains("/") && !urlString.contains("?") {
            return urlString
        }
        return nil
    }
}
