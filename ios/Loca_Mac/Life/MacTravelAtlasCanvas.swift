import SwiftUI
import SwiftData
import MapKit

// MARK: - TravelFilter

enum TravelFilter: String, CaseIterable, Identifiable {
    case all             = "All"
    case visited         = "Visited 🏆"
    case wishlist        = "Wishlist 📍"
    case northern        = "North"
    case western         = "West"
    case southern        = "South"
    case eastern         = "East"
    case unionTerritory  = "UTs"

    var id: String { rawValue }
}

// MARK: - MacTravelAtlasCanvas (Fast, High-Contrast Sovereign Travel Atlas)

struct MacTravelAtlasCanvas: View {

    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<TravelRecord> { $0.archivedAt == nil }, sort: \TravelRecord.name)
    private var activeStates: [TravelRecord]

    // Navigation & Selection States
    @State private var selectedState: TravelRecord? = nil
    @State private var selectedFilter: TravelFilter = .all
    @State private var searchText: String = ""
    @State private var isSearchOpen: Bool = false

    // MapKit Camera Position
    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 22.5, longitude: 80.0),
            distance: 3_600_000,
            heading: 0,
            pitch: 0
        )
    )

    // Filtered States
    private var filteredStates: [TravelRecord] {
        activeStates.filter { state in
            let matchesSearch = searchText.isEmpty ||
                state.name.localizedCaseInsensitiveContains(searchText) ||
                state.capital.localizedCaseInsensitiveContains(searchText) ||
                state.stateCode.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch selectedFilter {
            case .all:            return true
            case .visited:        return state.isVisited
            case .wishlist:       return !state.isVisited
            case .northern:       return state.zone == .northern
            case .western:        return state.zone == .western
            case .southern:       return state.zone == .southern
            case .eastern:        return state.zone == .eastern || state.zone == .northEast
            case .unionTerritory: return state.zone == .unionTerritory
            }
        }
    }

    private var visitedStatesCount: Int {
        activeStates.filter { $0.isVisited }.count
    }

    private var explorationPercentage: Double {
        activeStates.isEmpty ? 0 : (Double(visitedStatesCount) / Double(activeStates.count)) * 100.0
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1. Minimal Top Bar
            topBar

            Divider().opacity(0.12)

            // 2. Map Canvas & Floating Overlays
            ZStack(alignment: .topLeading) {
                mapView

                // Left: Search & Filter Drawer (When Open)
                if isSearchOpen {
                    floatingSearchDrawer
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .padding(14)
                }

                // Bottom-Trailing: Floating State Inspector
                if let state = selectedState {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            cleanStateInspector(state: state)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(16)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            TravelSeeder.seedIfNeeded(context: modelContext)
            if selectedState == nil {
                selectedState = activeStates.first(where: { $0.name == "Rajasthan" }) ?? activeStates.first
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DS.Theme.cyan)

            VStack(alignment: .leading, spacing: 1) {
                Text("Travel Atlas")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("\(visitedStatesCount) / \(activeStates.count) Explored · \(Int(explorationPercentage))% Complete")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(DS.Theme.textSecondary)
            }

            Spacer()

            // Search Toggle Button
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isSearchOpen.toggle()
                }
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                    Text(isSearchOpen ? "Close List" : "Search & Filter")
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundStyle(isSearchOpen ? DS.Theme.cyan : Color.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSearchOpen ? DS.Theme.cyan.opacity(0.15) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSearchOpen ? DS.Theme.cyan.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DS.Theme.surface)
    }

    // MARK: - High-Performance Map View

    private var mapView: some View {
        Map(position: $mapCameraPosition) {
            // Selected State High-Contrast Highlight Boundary (Fast single polygon)
            if let selected = selectedState {
                let rings = GeoJSONBoundaryLoader.shared.outerRings(for: selected.stateCode)
                ForEach(rings.indices, id: \.self) { ringIdx in
                    MapPolygon(coordinates: rings[ringIdx])
                        .foregroundStyle(DS.Theme.cyan.opacity(0.25))

                    MapPolygon(coordinates: rings[ringIdx])
                        .foregroundStyle(Color.clear)
                        .stroke(DS.Theme.cyan, lineWidth: 2.5)
                }
            }

            // High-Contrast Pins (Distinct colors that stand out from any map terrain)
            ForEach(activeStates) { state in
                let isSelected = selectedState?.id == state.id
                Annotation("", coordinate: state.coordinate) {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedState = state
                        }
                        Haptics.impact(.light)
                    } label: {
                        highContrastPin(state: state, isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - High-Contrast Map Pin (Laser Cyan / Vivid Coral / Solid White)

    private func highContrastPin(state: TravelRecord, isSelected: Bool) -> some View {
        HStack(spacing: 3.5) {
            Circle()
                .fill(
                    isSelected
                        ? DS.Theme.cyan
                        : (state.isVisited ? DS.Theme.amber : Color.white.opacity(0.6))
                )
                .frame(width: 6, height: 6)

            Text(state.stateCode)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    isSelected
                        ? DS.Theme.cyan
                        : (state.isVisited ? Color.white : Color.white.opacity(0.8))
                )
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    isSelected
                        ? Color(red: 0.04, green: 0.16, blue: 0.22)
                        : (state.isVisited ? Color(red: 0.18, green: 0.12, blue: 0.04) : Color(red: 0.08, green: 0.09, blue: 0.10))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(
                    isSelected
                        ? DS.Theme.cyan
                        : (state.isVisited ? DS.Theme.amber.opacity(0.8) : Color.white.opacity(0.20)),
                    lineWidth: isSelected ? 1.8 : 1.0
                )
        )
        .shadow(
            color: isSelected ? DS.Theme.cyan.opacity(0.6) : (state.isVisited ? DS.Theme.amber.opacity(0.3) : Color.black.opacity(0.5)),
            radius: isSelected ? 8 : 4
        )
    }

    // MARK: - Floating Search & Filter Drawer

    private var floatingSearchDrawer: some View {
        VStack(spacing: 8) {
            // Search Input
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Theme.textTertiary)

                TextField("Search states, capitals...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Theme.border, lineWidth: 1))

            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(TravelFilter.allCases) { filter in
                        let isSelected = selectedFilter == filter
                        Button {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.black : DS.Theme.textSecondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    isSelected ? DS.Theme.cyan : Color.white.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().opacity(0.12)

            // Results List
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(filteredStates) { state in
                        let isSelected = selectedState?.id == state.id
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedState = state
                            }
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(state.isVisited ? DS.Theme.amber : Color.white.opacity(0.2))
                                    .frame(width: 6, height: 6)

                                Text(state.name)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(Color.white)

                                Spacer()

                                Text(state.capital)
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Theme.textSecondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5.5)
                            .background(
                                isSelected ? DS.Theme.cyan.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 280)
        }
        .padding(10)
        .frame(width: 270)
        .machinedCard(cornerRadius: 10)
    }

    // MARK: - Clean Floating State Inspector Card

    private func cleanStateInspector(state: TravelRecord) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            // Header: Name + Code + Visited Status + Close
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(state.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)

                        Text("(\(state.stateCode))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Theme.cyan)

                        if state.isVisited {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Theme.amber)
                        }
                    }

                    Text("Capital: \(state.capital) · \(state.zone.title)")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Theme.textSecondary)
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.12)) {
                        selectedState = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.12)

            // Best Season & Language
            HStack(spacing: 6) {
                if !state.bestSeason.isEmpty {
                    infoBox(label: "BEST SEASON", value: state.bestSeason, accent: DS.Theme.amber)
                }
                if !state.primaryLanguage.isEmpty {
                    infoBox(label: "LANGUAGE", value: state.primaryLanguage, accent: DS.Theme.cyan)
                }
            }

            // Top Attractions Pills
            if !state.topAttractions.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TOP ATTRACTIONS")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(DS.Theme.textTertiary)

                    Text(state.topAttractions.prefix(3).joined(separator: " • "))
                        .font(.system(size: 10.5))
                        .foregroundStyle(DS.Theme.textSecondary)
                        .lineLimit(2)
                }
            }

            Divider().opacity(0.12)

            // Toggle Visited Button
            Button {
                toggleVisited(state)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: state.isVisited ? "arrow.uturn.backward" : "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(state.isVisited ? "Mark as Wishlist" : "Mark as Visited 🏆")
                        .font(.system(size: 11.5, weight: .bold))
                }
                .foregroundStyle(state.isVisited ? Color.white : Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    state.isVisited ? Color.white.opacity(0.10) : DS.Theme.amber,
                    in: RoundedRectangle(cornerRadius: 6)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 290)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DS.Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DS.Theme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: 6)
    }

    private func infoBox(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundStyle(DS.Theme.textTertiary)
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accent)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(5)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 4))
    }

    private func toggleVisited(_ state: TravelRecord) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            state.isVisited.toggle()
            state.visitedAt = state.isVisited ? Date.now : nil
            if state.isVisited {
                Haptics.notify(.success)
            }
            try? modelContext.save()
        }
    }
}
