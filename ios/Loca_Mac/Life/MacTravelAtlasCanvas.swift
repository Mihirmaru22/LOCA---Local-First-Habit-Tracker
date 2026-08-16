import SwiftUI
import SwiftData
import MapKit

// MARK: - TravelFilter

enum TravelFilter: String, CaseIterable, Identifiable {
    case all             = "All States 🇮🇳"
    case western         = "Western India 🦁"
    case northern        = "Northern India 🏜️"
    case southern        = "Southern India 🌴"
    case northEast       = "North-East & Sikkim 🏔️"
    case eastern         = "Eastern India 🪷"
    case central         = "Central India 🏛️"
    case unionTerritory  = "Union Territories 🇮🇳"
    case visited         = "Visited 🏆"
    case wishlist        = "Wishlist 📍"
    case subcontinent    = "Subcontinent 🌐"

    var id: String { rawValue }
}

// MARK: - TravelLayoutVariant

enum TravelLayoutVariant: String, CaseIterable, Identifiable {
    case splitMapInspector = "Split Canvas"
    case editorialList     = "Editorial Dossiers"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .splitMapInspector: return "square.split.2x1.fill"
        case .editorialList:     return "doc.richtext.fill"
        }
    }
}

// MARK: - MapColorTheme

enum MapColorTheme: String, CaseIterable, Identifiable {
    case visitedGlow  = "Explored Glow ✨"
    case frontierHunt = "Frontier Hunt 🎯"
    case allZones     = "Vivid Zones 🌈"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .visitedGlow:  return "sparkles"
        case .frontierHunt: return "scope"
        case .allZones:     return "paintpalette.fill"
        }
    }
}

// MARK: - MacTravelAtlasCanvas

/// Fullscreen interactive Travel Odyssey & State Atlas canvas for macOS.
struct MacTravelAtlasCanvas: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<TravelRecord> { $0.archivedAt == nil }, sort: \TravelRecord.name)
    private var activeStates: [TravelRecord]

    // Navigation & Selection States
    @State private var selectedState: TravelRecord? = nil
    @State private var selectedFilter: TravelFilter = .all
    @State private var layoutVariant: TravelLayoutVariant = .splitMapInspector
    @State private var mapColorTheme: MapColorTheme = .visitedGlow
    @State private var searchText: String = ""

    // MapKit Camera Position centered over the Indian Subcontinent
    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 22.0, longitude: 79.5),
            distance: 3_800_000,
            heading: 0,
            pitch: 25
        )
    )

    // New City text field state
    @State private var newCityInput: String = ""

    // Filtered States
    private var filteredStates: [TravelRecord] {
        activeStates.filter { state in
            // Search Query Match
            let matchesSearch = searchText.isEmpty ||
                state.name.localizedCaseInsensitiveContains(searchText) ||
                state.capital.localizedCaseInsensitiveContains(searchText) ||
                state.visitedCities.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                state.topAttractions.contains { $0.localizedCaseInsensitiveContains(searchText) }

            guard matchesSearch else { return false }

            switch selectedFilter {
            case .all:
                return state.country == "India"
            case .western:
                return state.zone == .western
            case .northern:
                return state.zone == .northern
            case .southern:
                return state.zone == .southern
            case .northEast:
                return state.zone == .northEast
            case .eastern:
                return state.zone == .eastern
            case .central:
                return state.zone == .central
            case .unionTerritory:
                return state.zone == .unionTerritory
            case .visited:
                return state.isVisited
            case .wishlist:
                return state.status == .wishlist
            case .subcontinent:
                return state.zone == .subcontinent || state.country != "India"
            }
        }
    }

    // Telemetry Statistics
    private var visitedStatesCount: Int {
        activeStates.filter { $0.country == "India" && $0.zone != .unionTerritory && $0.isVisited }.count
    }

    private var visitedUTCount: Int {
        activeStates.filter { $0.country == "India" && $0.zone == .unionTerritory && $0.isVisited }.count
    }

    private var totalCitiesExplored: Int {
        activeStates.reduce(0) { $0 + $1.visitedCities.count }
    }

    private var explorationPercentage: Double {
        let total = 28.0
        return (Double(visitedStatesCount) / total) * 100.0
    }

    private var odysseyRank: String {
        if visitedStatesCount >= 20 {
            return "Grand Explorer of Bharat 🇮🇳"
        } else if visitedStatesCount >= 10 {
            return "Subcontinent Voyager 🧭"
        } else if visitedStatesCount >= 5 {
            return "Regional Pioneer 🗺️"
        } else {
            return "Aspiring Wanderer 🎒"
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // 1. Odyssey Telemetry Banner
            odysseyTelemetryBanner

            Divider()

            // 2. Main Selected Layout
            switch layoutVariant {
            case .splitMapInspector:
                splitMapLayout
            case .editorialList:
                editorialListLayout
            }
        }
        .onAppear {
            TravelSeeder.seedIfNeeded(context: modelContext)
            if selectedState == nil {
                selectedState = activeStates.first(where: { $0.name == "Gujarat" }) ?? activeStates.first
            }
        }
    }

    // MARK: - 1. Odyssey Telemetry Banner
    private var odysseyTelemetryBanner: some View {
        HStack(spacing: DS.Space.lg) {
            // Stats Group
            HStack(spacing: DS.Space.xl) {
                // States Visited
                HStack(spacing: DS.Space.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(visitedStatesCount) / 28 STATES")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("\(Int(explorationPercentage))% OF INDIA EXPLORED")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.orange)
                    }
                }

                Divider().frame(height: 24)

                // Union Territories
                HStack(spacing: DS.Space.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.blue)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(visitedUTCount) / 8 UNION TERRITORIES")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("Federal Enclaves")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }

                Divider().frame(height: 24)

                // Total Cities
                HStack(spacing: DS.Space.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.green)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(totalCitiesExplored) CITIES & DISTRICTS")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("Footprint Recorded")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }

                Divider().frame(height: 24)

                // Odyssey Rank
                HStack(spacing: DS.Space.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: "medal.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.purple)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(odysseyRank)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("Traveler Status")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
            }

            Spacer()

            // Layout Switcher
            HStack(spacing: 2) {
                ForEach(TravelLayoutVariant.allCases) { variant in
                    let isSelected = layoutVariant == variant
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            layoutVariant = variant
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: variant.icon)
                                .font(.system(size: 11))
                            Text(variant.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundStyle(isSelected ? Color.white : DS.Color.textSecondary)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(
                            isSelected ? Color.white.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, 10)
        .background(DS.Color.surface)
    }

    // MARK: - 2. Split Map Layout (Sidebar + Map + State Dossier)
    private var splitMapLayout: some View {
        HStack(spacing: 0) {
            // Left: State Directory Column
            VStack(spacing: 0) {
                stateSearchAndFilterHeader

                Divider()

                stateListScrollView
            }
            .frame(width: 360)
            .background(DS.Color.surface)

            Divider()

            // Center & Right: Map + Selected State Dossier
            ZStack(alignment: .topTrailing) {
                // Interactive MapKit Map with Full Fog-of-War Territory Illumination
                Map(position: $mapCameraPosition) {
                    ForEach(activeStates) { state in
                        // Real Geopolitical State Boundary Polygon
                        if let boundary = IndianStateBoundaryData.polygon(for: state.stateCode) {
                            if mapColorTheme == .visitedGlow {
                                if state.isVisited {
                                    MapPolygon(coordinates: boundary)
                                        .foregroundStyle(zoneColor(for: state.zone).opacity(selectedState?.id == state.id ? 0.55 : 0.38))
                                        .stroke(zoneColor(for: state.zone), lineWidth: selectedState?.id == state.id ? 3.5 : 2.0)
                                } else {
                                    MapPolygon(coordinates: boundary)
                                        .foregroundStyle(Color.gray.opacity(0.08))
                                        .stroke(Color.gray.opacity(0.25), style: StrokeStyle(lineWidth: 1.0, dash: [4, 4]))
                                }
                            } else if mapColorTheme == .frontierHunt {
                                if !state.isVisited {
                                    MapPolygon(coordinates: boundary)
                                        .foregroundStyle(Color.orange.opacity(0.40))
                                        .stroke(Color.orange, lineWidth: 2.5)
                                } else {
                                    MapPolygon(coordinates: boundary)
                                        .foregroundStyle(Color.green.opacity(0.20))
                                        .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
                                }
                            } else {
                                // Vivid All Zones
                                MapPolygon(coordinates: boundary)
                                    .foregroundStyle(zoneColor(for: state.zone).opacity(state.isVisited ? 0.42 : 0.18))
                                    .stroke(zoneColor(for: state.zone).opacity(state.isVisited ? 1.0 : 0.4), lineWidth: state.isVisited ? 2.5 : 1.0)
                            }
                        } else {
                            // Fallback for smaller islands or enclaves
                            if state.isVisited {
                                MapCircle(center: state.coordinate, radius: 80_000)
                                    .foregroundStyle(zoneColor(for: state.zone).opacity(0.35))
                                    .stroke(zoneColor(for: state.zone), lineWidth: 2.0)
                            }
                        }

                        // Custom Rich Annotation Pin
                        Annotation(state.name, coordinate: state.coordinate) {
                            Button {
                                selectState(state)
                            } label: {
                                StateMapPin(
                                    state: state,
                                    isSelected: selectedState?.id == state.id,
                                    colorTheme: mapColorTheme
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))

                // Top-Left Floating Map Theme & Region Strip
                VStack(alignment: .leading, spacing: 8) {
                    // Illumination Mode Switcher
                    HStack(spacing: 4) {
                        ForEach(MapColorTheme.allCases) { theme in
                            let isSelected = mapColorTheme == theme
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    mapColorTheme = theme
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: theme.icon)
                                        .font(.system(size: 10))
                                    Text(theme.rawValue)
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                }
                                .foregroundStyle(isSelected ? Color.white : DS.Color.textSecondary)
                                .padding(.horizontal, 8)
                                .frame(height: 24)
                                .background(
                                    isSelected ? Color.orange : Color.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.8))

                    // Quick Jump Region Bar
                    HStack(spacing: 4) {
                        quickJumpButton(title: "All India 🇮🇳", lat: 22.0, lon: 79.5, dist: 3_800_000)
                        quickJumpButton(title: "Gujarat 🦁", lat: 22.25, lon: 71.20, dist: 900_000)
                        quickJumpButton(title: "Maharashtra 🏰", lat: 19.75, lon: 75.71, dist: 950_000)
                        quickJumpButton(title: "Rajasthan 🏜️", lat: 27.02, lon: 74.21, dist: 1_000_000)
                        quickJumpButton(title: "Himalayas 🏔️", lat: 31.50, lon: 77.50, dist: 1_200_000)
                        quickJumpButton(title: "South 🌴", lat: 12.50, lon: 77.00, dist: 1_300_000)
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                // Floating State Dossier Inspector (Right Side)
                if let state = selectedState {
                    stateDetailDossierCard(state: state)
                        .frame(width: 380)
                        .padding(16)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - 3. Editorial List Layout
    private var editorialListLayout: some View {
        VStack(spacing: 0) {
            stateSearchAndFilterHeader

            Divider()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
                    ForEach(filteredStates) { state in
                        editorialStateCard(state: state)
                    }
                }
                .padding(DS.Space.lg)
            }
        }
        .background(DS.Color.background)
    }

    // MARK: - Search & Filter Header (Standardized 28pt Buttons)
    private var stateSearchAndFilterHeader: some View {
        VStack(spacing: DS.Space.sm) {
            // Search Field
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.textTertiary)

                TextField("Search states, capitals, cities, attractions...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, 6)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))

            // Standardized Filter Chips with Single-Line Clamping
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TravelFilter.allCases) { filter in
                        let isSelected = selectedFilter == filter
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                selectedFilter = filter
                            }
                            Haptics.impact(.light)
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(isSelected ? Color.white : DS.Color.textSecondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 10)
                                .frame(height: 28)
                                .background(
                                    isSelected
                                        ? LinearGradient(
                                            colors: [Color(red: 0.95, green: 0.55, blue: 0.15), Color(red: 0.85, green: 0.35, blue: 0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [DS.Color.surfaceRecessed],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                    in: RoundedRectangle(cornerRadius: 7)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(isSelected ? Color.orange.opacity(0.5) : DS.Color.border.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(DS.Space.md)
    }

    // MARK: - State List Scroll View
    private var stateListScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(filteredStates) { state in
                    let isSelected = selectedState?.id == state.id
                    Button {
                        selectState(state)
                    } label: {
                        HStack(spacing: 10) {
                            // State Code Badge
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(state.isVisited ? Color.green.opacity(0.18) : Color.white.opacity(0.06))
                                    .frame(width: 34, height: 34)

                                Text(state.stateCode)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(state.isVisited ? Color.green : DS.Color.textSecondary)
                            }

                            // State Name & Details
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(state.name)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                                        .foregroundStyle(DS.Color.textPrimary)

                                    if state.isVisited {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.green)
                                    }
                                }

                                Text("Capital: \(state.capital) • \(state.visitedCities.count) cities explored")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Color.textTertiary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Visited Toggle Button
                            Button {
                                toggleVisited(state)
                            } label: {
                                Text(state.isVisited ? "Visited" : "Wishlist")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(state.isVisited ? Color.green : Color.skyBlue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        (state.isVisited ? Color.green : Color.blue).opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 4)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? Color.white.opacity(0.08) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Selected State Detail Dossier Card
    private func stateDetailDossierCard(state: TravelRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(state.name.uppercased())
                                .font(.system(size: 18, weight: .black, design: .serif))
                                .foregroundStyle(Color.white)

                            Text("(\(state.stateCode))")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.orange)
                        }

                        Text("Capital: \(state.capital) · \(state.zone.title)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()

                    // Visited Status Button
                    Button {
                        toggleVisited(state)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: state.isVisited ? "checkmark.seal.fill" : "plus.circle.fill")
                            Text(state.isVisited ? "Explored" : "Mark Visited")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(state.isVisited ? Color.black : Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            state.isVisited
                                ? LinearGradient(colors: [Color.green, Color(red: 0.2, green: 0.8, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider().overlay(Color.white.opacity(0.1))

                // Key Info Grid
                HStack(spacing: 8) {
                    infoTile(title: "BEST SEASON", value: state.bestSeason.isEmpty ? "Oct – Mar" : state.bestSeason, icon: "calendar")
                    infoTile(title: "LANGUAGE", value: state.officialLanguage.isEmpty ? "Regional" : state.officialLanguage, icon: "bubble.left.and.bubble.right.fill")
                }

                // Cities & Districts Explored
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.orange)
                        Text("CITIES & DISTRICTS VISITED (\(state.visitedCities.count))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    // Chips
                    FlowLayout(spacing: 6) {
                        ForEach(state.visitedCities, id: \.self) { city in
                            HStack(spacing: 4) {
                                Text(city)
                                    .font(.system(size: 10, weight: .semibold))
                                Button {
                                    removeCity(city, from: state)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8))
                                        .foregroundStyle(DS.Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // Add city field
                    HStack(spacing: 6) {
                        TextField("Add visited city / district...", text: $newCityInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .onSubmit {
                                addCity(to: state)
                            }

                        Button {
                            addCity(to: state)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.orange)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                }

                // Top Attractions
                if !state.topAttractions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.yellow)
                            Text("ICONIC ATTRACTIONS & HERITAGE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(state.topAttractions, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.green)
                                        .padding(.top, 2)
                                    Text(item)
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                            }
                        }
                    }
                }

                // Culinary & Culture Highlights
                if !state.cuisineHighlights.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.orange)
                            Text("CUISINE & LOCAL DELICACIES")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                        }

                        Text(state.cuisineHighlights)
                            .font(.system(size: 11, weight: .regular, design: .serif))
                            .foregroundStyle(DS.Color.textSecondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                    }
                }

                // Travel Journal Notes
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.orange)
                        Text("TRAVEL MEMOIRS & NOTES")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    Text(state.personalNotes.isEmpty ? "No personal travel notes recorded for this state yet." : state.personalNotes)
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.5), radius: 12)
        )
    }

    // MARK: - Editorial State Card (Grid View)
    private func editorialStateCard(state: TravelRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(state.isVisited ? Color.green.opacity(0.18) : Color.white.opacity(0.06))
                        .frame(width: 32, height: 32)
                    Text(state.stateCode)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(state.isVisited ? Color.green : Color.orange)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(state.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("Capital: \(state.capital)")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Spacer()

                Button {
                    toggleVisited(state)
                } label: {
                    Text(state.isVisited ? "Visited 🏆" : "Wishlist 📍")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(state.isVisited ? Color.green : Color.skyBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            (state.isVisited ? Color.green : Color.blue).opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 4)
                        )
                }
                .buttonStyle(.plain)
            }

            if !state.visitedCities.isEmpty {
                Text("Cities: " + state.visitedCities.prefix(4).joined(separator: ", "))
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(1)
            }

            if !state.topAttractions.isEmpty {
                Text("Top Sights: " + state.topAttractions.prefix(2).joined(separator: " • "))
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func infoTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(Color.orange)
                Text(title)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
    }

    private func zoneColor(for zone: TravelZone) -> Color {
        switch zone {
        case .western:        return Color(red: 0.98, green: 0.55, blue: 0.15) // Saffron Orange
        case .northern:       return Color(red: 0.95, green: 0.75, blue: 0.20) // Desert Gold
        case .southern:       return Color(red: 0.20, green: 0.85, blue: 0.45) // Emerald Green
        case .eastern:        return Color(red: 0.95, green: 0.35, blue: 0.45) // Crimson Lotus
        case .northEast:      return Color(red: 0.75, green: 0.40, blue: 0.98) // Orchid Purple
        case .central:        return Color(red: 0.90, green: 0.50, blue: 0.30) // Terracotta
        case .unionTerritory: return Color(red: 0.25, green: 0.75, blue: 0.98) // Azure Blue
        case .subcontinent:   return Color(red: 0.30, green: 0.60, blue: 0.95) // Royal Indigo
        }
    }

    private func quickJumpButton(title: String, lat: Double, lon: Double, dist: Double) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                mapCameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        distance: dist,
                        heading: 0,
                        pitch: dist < 1_500_000 ? 30 : 15
                    )
                )
            }
            Haptics.selection()
        } label: {
            Text(title)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions
    private func selectState(_ state: TravelRecord) {
        withAnimation(.spring(response: 0.3)) {
            selectedState = state
            mapCameraPosition = .camera(
                MapCamera(
                    centerCoordinate: state.coordinate,
                    distance: 1_200_000,
                    heading: 0,
                    pitch: 20
                )
            )
        }
        Haptics.selection()
    }

    private func toggleVisited(_ state: TravelRecord) {
        withAnimation(.spring(response: 0.25)) {
            if state.isVisited {
                state.status = .wishlist
            } else {
                state.status = .visited
                state.dateVisited = Date()
            }
            try? modelContext.save()
        }
        Haptics.impact(.light)
    }

    private func addCity(to state: TravelRecord) {
        let trimmed = newCityInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !state.visitedCities.contains(trimmed) {
            state.visitedCities.append(trimmed)
            try? modelContext.save()
        }
        newCityInput = ""
    }

    private func removeCity(_ city: String, from state: TravelRecord) {
        state.visitedCities.removeAll { $0 == city }
        try? modelContext.save()
    }
}

// MARK: - StateMapPin View
private struct StateMapPin: View {
    let state: TravelRecord
    let isSelected: Bool
    let colorTheme: MapColorTheme

    var isHighlighted: Bool {
        switch colorTheme {
        case .visitedGlow:  return state.isVisited
        case .frontierHunt: return !state.isVisited
        case .allZones:     return true
        }
    }

    var pinColor: Color {
        if colorTheme == .visitedGlow {
            return state.isVisited ? Color(red: 0.20, green: 0.85, blue: 0.45) : Color.gray.opacity(0.45)
        } else if colorTheme == .frontierHunt {
            return !state.isVisited ? Color.orange : Color(red: 0.20, green: 0.85, blue: 0.45).opacity(0.6)
        } else {
            return state.isVisited ? Color.green : Color.skyBlue
        }
    }

    var body: some View {
        ZStack {
            if isHighlighted && (state.isVisited || colorTheme == .frontierHunt) {
                Circle()
                    .fill(pinColor.opacity(0.25))
                    .frame(width: isSelected ? 42 : 32, height: isSelected ? 42 : 32)
                    .blur(radius: 4)

                Circle()
                    .stroke(pinColor, lineWidth: 1.5)
                    .frame(width: isSelected ? 34 : 26, height: isSelected ? 34 : 26)
            }

            Circle()
                .fill(pinColor)
                .frame(width: isSelected ? 26 : 20, height: isSelected ? 26 : 20)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isHighlighted ? pinColor.opacity(0.8) : Color.clear, radius: 6)

            Text(state.stateCode)
                .font(.system(size: isSelected ? 9 : 7.5, weight: .black, design: .monospaced))
                .foregroundStyle(isHighlighted && state.isVisited ? Color.black : Color.white)
        }
    }
}

// MARK: - FlowLayout Helper for City Chips
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height = y + rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private extension Color {
    static let skyBlue = Color(red: 0.22, green: 0.74, blue: 0.97)
}
