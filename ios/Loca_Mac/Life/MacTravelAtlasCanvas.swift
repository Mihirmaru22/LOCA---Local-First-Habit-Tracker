import SwiftUI
import SwiftData
import MapKit

// MARK: - TravelFilter

enum TravelFilter: String, CaseIterable, Identifiable {
    case all             = "All"
    case western         = "West 🦁"
    case northern        = "North 🏜️"
    case southern        = "South 🌴"
    case northEast       = "North-East 🏔️"
    case eastern         = "East 🪷"
    case central         = "Central 🏛️"
    case unionTerritory  = "UTs 🇮🇳"
    case visited         = "Visited 🏆"
    case wishlist        = "Wishlist 📍"

    var id: String { rawValue }
}

// MARK: - MacTravelAtlasCanvas (Minimalist Sovereign Travel Odyssey & State Atlas)

struct MacTravelAtlasCanvas: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<TravelRecord> { $0.archivedAt == nil }, sort: \TravelRecord.name)
    private var activeStates: [TravelRecord]

    // Navigation & Selection States
    @State private var selectedState: TravelRecord? = nil
    @State private var selectedFilter: TravelFilter = .all
    @State private var searchText: String = ""
    @State private var isSearchOpen: Bool = false

    // MapKit Camera Position centered over the Indian Subcontinent
    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 22.0, longitude: 79.5),
            distance: 3_800_000,
            heading: 0,
            pitch: 20
        )
    )

    // Filtered States
    private var filteredStates: [TravelRecord] {
        activeStates.filter { state in
            let matchesSearch = searchText.isEmpty ||
                state.name.localizedCaseInsensitiveContains(searchText) ||
                state.capital.localizedCaseInsensitiveContains(searchText) ||
                state.visitedCities.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                state.topAttractions.contains { $0.localizedCaseInsensitiveContains(searchText) }

            guard matchesSearch else { return false }

            switch selectedFilter {
            case .all:
                return true
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
                return !state.isVisited
            }
        }
    }

    private var visitedStatesCount: Int {
        activeStates.filter { $0.country == "India" && $0.zone != .unionTerritory && $0.isVisited }.count
    }

    private var visitedUTCount: Int {
        activeStates.filter { $0.country == "India" && $0.zone == .unionTerritory && $0.isVisited }.count
    }

    private var explorationPercentage: Double {
        (Double(visitedStatesCount) / 28.0) * 100.0
    }

    private var odysseyRank: String {
        if visitedStatesCount >= 20 {
            return "Grand Explorer 🇮🇳"
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
            // 1. Minimalist Top Bar
            minimalTopBar

            Divider().opacity(0.18)

            // 2. Full-Canvas Map & Overlays
            ZStack(alignment: .topLeading) {
                mapCanvasView

                // Top-Leading: Search Controls
                if isSearchOpen {
                    floatingSearchDrawer
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.96, anchor: .topLeading).combined(with: .opacity).combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .topLeading))
                        ))
                        .padding(14)
                } else {
                    floatingSearchTriggerPill
                        .padding(14)
                }

                // Bottom-Trailing: Floating State Inspector Card
                floatingInspectorOverlay
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            TravelSeeder.seedIfNeeded(context: modelContext)
            if selectedState == nil {
                selectedState = activeStates.first(where: { $0.name == "Gujarat" }) ?? activeStates.first
            }
        }
    }

    // MARK: - Map Canvas View

    private var mapCanvasView: some View {
        Map(position: $mapCameraPosition) {
            ForEach(activeStates) { state in
                stateMapContent(for: state)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .edgesIgnoringSafeArea(.all)
    }

    @MapContentBuilder
    private func stateMapContent(for state: TravelRecord) -> some MapContent {
        let isSelectedState = selectedState?.id == state.id

        // 1. High-Precision GeoJSON State Boundary
        if state.isVisited || isSelectedState {
            stateBoundaryContent(for: state, isSelected: isSelectedState)
        }

        // 2. Sovereign Map Marker Annotation
        Annotation("", coordinate: state.coordinate) {
            Button {
                selectState(state)
            } label: {
                minimalMapPin(state: state, isSelected: isSelectedState)
            }
            .buttonStyle(.plain)
        }
    }

    @MapContentBuilder
    private func stateBoundaryContent(for state: TravelRecord, isSelected: Bool) -> some MapContent {
        let outerRings = GeoJSONBoundaryLoader.shared.outerRings(for: state.stateCode)

        if !outerRings.isEmpty {
            ForEach(outerRings.indices, id: \.self) { ringIdx in
                MapPolygon(coordinates: outerRings[ringIdx])
                    .foregroundStyle(
                        isSelected
                            ? Color(red: 0.95, green: 0.60, blue: 0.15).opacity(0.30)
                            : Color(red: 0.15, green: 0.82, blue: 0.45).opacity(0.22)
                    )

                MapPolygon(coordinates: outerRings[ringIdx])
                    .foregroundStyle(Color.clear)
                    .stroke(
                        isSelected
                            ? Color(red: 0.95, green: 0.60, blue: 0.15)
                            : Color(red: 0.15, green: 0.82, blue: 0.45).opacity(0.85),
                        lineWidth: isSelected ? 2.5 : 1.4
                    )
            }
        } else {
            MapCircle(center: state.coordinate, radius: stateRadius(for: state))
                .foregroundStyle(
                    isSelected
                        ? Color(red: 0.95, green: 0.60, blue: 0.15).opacity(0.30)
                        : Color(red: 0.15, green: 0.82, blue: 0.45).opacity(0.22)
                )
        }
    }

    // MARK: - Floating Inspector Overlay

    @ViewBuilder
    private var floatingInspectorOverlay: some View {
        if let state = selectedState {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingStateInspector(state: state)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(18)
                }
            }
        }
    }

    // MARK: - Minimalist Top Bar

    private var minimalTopBar: some View {
        HStack(spacing: 12) {
            
            // Left: Title & Live Odyssey Telemetry
            HStack(spacing: 8) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.orange)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Travel Atlas & Odyssey")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text("\(visitedStatesCount) / 28 States · \(visitedUTCount) UTs · \(Int(explorationPercentage))% Explored · Status: \(odysseyRank)")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }

            Spacer()

            // Right: Dedicated On-Demand Search Trigger Button
            Button {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                    isSearchOpen.toggle()
                }
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isSearchOpen ? "Close Search" : "Search States")
                        .font(.system(size: 11.5, weight: .medium))

                    if !isSearchOpen {
                        Text("⌘F")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 3))
                    }
                }
                .foregroundStyle(isSearchOpen ? Color.orange : Color.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isSearchOpen ? Color.orange.opacity(0.18) : Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSearchOpen ? Color.orange.opacity(0.40) : Color.white.opacity(0.10), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlutoFastButtonStyle())
            .keyboardShortcut("f", modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: NSColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1.0)))
    }

    // MARK: - Floating Search Trigger Pill (When Drawer is Closed)

    private var floatingSearchTriggerPill: some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                isSearchOpen = true
            }
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Color.orange)

                Text("Search 28 States & 8 UTs...")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))

                Text("⌘F")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.94)),
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.40), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlutoFastButtonStyle())
    }

    // MARK: - Floating Search & Filter Drawer (When Open)

    private var floatingSearchDrawer: some View {
        VStack(spacing: 0) {
            searchHeaderView
            searchFilterPillsView
            Divider().opacity(0.15)
            searchResultsListView
        }
        .frame(width: 320)
        .background(
            Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.95)),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 8)
    }

    private var searchHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(Color.orange)

            TextField("Search states, capitals, attractions...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    isSearchOpen = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.10), lineWidth: 1))
        .padding([.horizontal, .top], 10)
    }

    private var searchFilterPillsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(TravelFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    Button {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            selectedFilter = filter
                        }
                        Haptics.impact(.light)
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.75))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(
                                isSelected ? Color(red: 0.95, green: 0.65, blue: 0.25) : Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 5)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlutoFastButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    private var searchResultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 3) {
                if filteredStates.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "globe.asia.australia")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.white.opacity(0.3))
                        Text("No states or territories found")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(.vertical, 24)
                } else {
                    ForEach(filteredStates) { state in
                        searchStateRow(for: state)
                    }
                }
            }
            .padding(6)
        }
        .frame(maxHeight: 380)
    }

    private func searchStateRow(for state: TravelRecord) -> some View {
        let isSelected = selectedState?.id == state.id

        return Button {
            selectState(state)
        } label: {
            HStack(spacing: 8) {
                Text(state.stateCode)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(state.isVisited ? Color.green : Color.white.opacity(0.7))
                    .frame(width: 22, height: 22)
                    .background(state.isVisited ? Color.green.opacity(0.18) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(state.name)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)

                        if state.isVisited {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 9.5))
                                .foregroundStyle(Color.green)
                        }
                    }

                    Text("Capital: \(state.capital)")
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer()

                Text(state.isVisited ? "Visited" : "Wishlist")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(state.isVisited ? Color.green : Color.white.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(state.isVisited ? Color.green.opacity(0.12) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                isSelected ? Color.orange.opacity(0.18) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlutoFastButtonStyle())
    }

    // MARK: - Minimal Map Pin

    private func minimalMapPin(state: TravelRecord, isSelected: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: state.isVisited ? "checkmark.circle.fill" : "mappin.circle.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(state.isVisited ? Color.green : Color.orange)

            Text(state.stateCode)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(
            isSelected
                ? Color.black.opacity(0.90)
                : (state.isVisited ? Color.black.opacity(0.70) : Color.black.opacity(0.50)),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(
                    isSelected
                        ? Color.orange
                        : (state.isVisited ? Color.green.opacity(0.60) : Color.white.opacity(0.18)),
                    lineWidth: isSelected ? 1.5 : 0.8
                )
        )
        .shadow(color: isSelected ? Color.orange.opacity(0.5) : Color.clear, radius: 6)
    }

    // MARK: - Floating State Inspector Card

    private func floatingStateInspector(state: TravelRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            inspectorHeader(for: state)
            Divider().opacity(0.15)
            inspectorMetrics(for: state)
            if !state.topAttractions.isEmpty {
                inspectorAttractions(for: state)
            }
            Divider().opacity(0.15)
            inspectorActionButton(for: state)
        }
        .padding(14)
        .frame(width: 320)
        .background(
            Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 0.96)),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
    }

    private func inspectorHeader(for state: TravelRecord) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(state.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text("(\(state.stateCode))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.orange)

                    if state.isVisited {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.green)
                    }
                }

                Text("Capital: \(state.capital) · \(state.zone.title)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    selectedState = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
    }

    private func inspectorMetrics(for state: TravelRecord) -> some View {
        HStack(spacing: 6) {
            metricPill(label: "BEST SEASON", value: state.bestSeason.isEmpty ? "Oct – Mar" : state.bestSeason, color: Color.orange)
            metricPill(label: "LANGUAGE", value: state.officialLanguage.isEmpty ? "Regional" : state.officialLanguage, color: Color.cyan)
        }
    }

    private func inspectorAttractions(for state: TravelRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ICONIC ATTRACTIONS")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.4))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(state.topAttractions.prefix(4), id: \.self) { attr in
                        Text(attr)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
    }

    private func inspectorActionButton(for state: TravelRecord) -> some View {
        Button {
            toggleVisited(state)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: state.isVisited ? "arrow.uturn.backward" : "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(state.isVisited ? "Mark as Wishlist" : "Mark as Explored 🏆")
                    .font(.system(size: 11.5, weight: .bold))
            }
            .foregroundStyle(state.isVisited ? Color.white : Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(
                state.isVisited
                    ? Color.white.opacity(0.12)
                    : Color(red: 0.95, green: 0.65, blue: 0.25),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlutoFastButtonStyle())
    }

    private func metricPill(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.4))
            Text(value)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 5))
    }

    // MARK: - Actions

    private func selectState(_ state: TravelRecord) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedState = state
            mapCameraPosition = .camera(
                MapCamera(
                    centerCoordinate: state.coordinate,
                    distance: 1_200_000,
                    heading: 0,
                    pitch: 25
                )
            )
        }
        Haptics.impact(.light)
    }

    private func toggleVisited(_ state: TravelRecord) {
        if state.isVisited {
            state.status = .wishlist
            state.dateVisited = nil
        } else {
            state.status = .visited
            state.dateVisited = Date()
        }
        try? modelContext.save()
        Haptics.notification(.success)
    }

    private func zoneColor(for zone: TravelZone) -> Color {
        switch zone {
        case .western:        return Color(red: 0.95, green: 0.55, blue: 0.15) // Warm Orange
        case .northern:       return Color(red: 0.90, green: 0.35, blue: 0.25) // Coral Red
        case .southern:       return Color(red: 0.15, green: 0.75, blue: 0.55) // Emerald Green
        case .eastern:        return Color(red: 0.85, green: 0.35, blue: 0.75) // Magenta Pink
        case .northEast:      return Color(red: 0.35, green: 0.65, blue: 0.95) // Sky Blue
        case .central:        return Color(red: 0.95, green: 0.75, blue: 0.20) // Golden Amber
        case .unionTerritory: return Color(red: 0.55, green: 0.45, blue: 0.95) // Lavender Purple
        case .subcontinent:   return Color(red: 0.25, green: 0.75, blue: 0.85) // Cyan
        }
    }

    private func stateRadius(for state: TravelRecord) -> Double {
        switch state.stateCode {
        case "RJ", "MP", "MH", "UP":
            return 210_000
        case "GJ", "KA", "AP", "TN", "OR", "TG", "CH", "WB", "BR", "AS":
            return 150_000
        case "KL", "PB", "HR", "UK", "HP", "JH", "AR", "MN", "MZ", "NL", "TR", "SK":
            return 90_000
        case "GA", "DL", "PY", "CH", "LD", "AN", "DN":
            return 35_000
        default:
            return 120_000
        }
    }
}
