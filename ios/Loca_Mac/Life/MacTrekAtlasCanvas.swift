import SwiftUI
import SwiftData
import MapKit
import UniformTypeIdentifiers

// MARK: - TrekFilter

enum TrekFilter: String, CaseIterable, Identifiable {
    case all          = "All Summits"
    case gujarat      = "Gujarat 🦁"
    case maharashtra  = "Maharashtra 🏰"
    case rajasthan    = "Rajasthan 🏜️"
    case himalayas    = "Himalayas 🏔️"
    case westernGhats = "Western Ghats 🌿"
    case conquered    = "Conquered 🏆"
    case wishlist     = "Wishlist 📍"
    case highest      = "8000ers & High Peaks ⛰️"

    var id: String { rawValue }
}

// MARK: - TrekAtlasLayoutVariant

enum TrekAtlasLayoutVariant: String, CaseIterable, Identifiable {
    case splitMapInspector = "Split Canvas"
    case editorialList     = "Editorial Cards"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .splitMapInspector: return "square.split.2x1.fill"
        case .editorialList:     return "doc.richtext.fill"
        }
    }
}

// MARK: - MacTrekAtlasCanvas

/// Full-screen interactive Trek & Mountain Atlas for Pluto.
/// Integrates 4 distinct layout design variants, 3D MapKit canvas,
/// GPX trail ridge engine, and elevation profile studio.
struct MacTrekAtlasCanvas: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrekRecord.elevationMeters, order: .reverse) private var allTreks: [TrekRecord]

    @AppStorage("mac_trek_layout_variant_v1") private var selectedLayout: TrekAtlasLayoutVariant = .splitMapInspector

    @State private var selectedTrek: TrekRecord? = nil
    @State private var searchText: String = ""
    @State private var selectedFilter: TrekFilter = .all
    @State private var isLogModalPresented: Bool = false
    @State private var isTrophyCabinetPresented: Bool = false
    @State private var isWatchSyncPresented: Bool = false
    @State private var passportTrek: TrekRecord? = nil
    @State private var quickLookTrek: TrekRecord? = nil
    @State private var quickLookPhotoIndex: Int = 0
    @State private var isFlyingTrail: Bool = false
    @State private var scrubCoordinate: CLLocationCoordinate2D? = nil

    // MARK: - Filtered Treks

    private var activeTreks: [TrekRecord] {
        allTreks.filter { !$0.isArchived }
    }

    private var filteredTreks: [TrekRecord] {
        activeTreks.filter { trek in
            // Search filter
            let matchesSearch = searchText.isEmpty
                || trek.name.localizedCaseInsensitiveContains(searchText)
                || trek.region.localizedCaseInsensitiveContains(searchText)
                || trek.country.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch selectedFilter {
            case .all:
                return true
            case .gujarat:
                return trek.region.localizedCaseInsensitiveContains("Gujarat") ||
                       trek.region.localizedCaseInsensitiveContains("Junagadh") ||
                       trek.region.localizedCaseInsensitiveContains("Kutch") ||
                       trek.region.localizedCaseInsensitiveContains("Dang") ||
                       trek.region.localizedCaseInsensitiveContains("Panchmahal") ||
                       trek.region.localizedCaseInsensitiveContains("Valsad") ||
                       trek.region.localizedCaseInsensitiveContains("Saurashtra") ||
                       trek.region.localizedCaseInsensitiveContains("Sabarkantha") ||
                       trek.region.localizedCaseInsensitiveContains("Banaskantha")
            case .maharashtra:
                return trek.region.localizedCaseInsensitiveContains("Maharashtra") ||
                       trek.region.localizedCaseInsensitiveContains("Sahyadri") ||
                       trek.region.localizedCaseInsensitiveContains("Pune") ||
                       trek.region.localizedCaseInsensitiveContains("Nashik") ||
                       trek.region.localizedCaseInsensitiveContains("Ahmednagar") ||
                       trek.region.localizedCaseInsensitiveContains("Satara") ||
                       trek.region.localizedCaseInsensitiveContains("Raigad") ||
                       trek.region.localizedCaseInsensitiveContains("Igatpuri") ||
                       trek.region.localizedCaseInsensitiveContains("Lonavala") ||
                       trek.region.localizedCaseInsensitiveContains("Panvel") ||
                       trek.region.localizedCaseInsensitiveContains("Baglan")
            case .rajasthan:
                return trek.region.localizedCaseInsensitiveContains("Rajasthan") ||
                       trek.region.localizedCaseInsensitiveContains("Aravalli") ||
                       trek.region.localizedCaseInsensitiveContains("Abu") ||
                       trek.region.localizedCaseInsensitiveContains("Jaipur") ||
                       trek.region.localizedCaseInsensitiveContains("Ajmer") ||
                       trek.region.localizedCaseInsensitiveContains("Udaipur") ||
                       trek.region.localizedCaseInsensitiveContains("Sirohi") ||
                       trek.region.localizedCaseInsensitiveContains("Chittorgarh") ||
                       trek.region.localizedCaseInsensitiveContains("Sikar")
            case .himalayas:
                return trek.country.localizedCaseInsensitiveContains("India") && (
                    trek.region.localizedCaseInsensitiveContains("Himalaya") ||
                    trek.region.localizedCaseInsensitiveContains("Uttarakhand") ||
                    trek.region.localizedCaseInsensitiveContains("Ladakh") ||
                    trek.region.localizedCaseInsensitiveContains("Sikkim") ||
                    trek.region.localizedCaseInsensitiveContains("Himachal") ||
                    trek.region.localizedCaseInsensitiveContains("Garhwal") ||
                    trek.region.localizedCaseInsensitiveContains("Zanskar") ||
                    trek.region.localizedCaseInsensitiveContains("Singalila") ||
                    trek.elevationMeters >= 3000
                )
            case .westernGhats:
                return trek.country.localizedCaseInsensitiveContains("India") && (
                    trek.region.localizedCaseInsensitiveContains("Western Ghats") ||
                    trek.region.localizedCaseInsensitiveContains("Maharashtra") ||
                    trek.region.localizedCaseInsensitiveContains("Sahyadri") ||
                    trek.region.localizedCaseInsensitiveContains("Karnataka") ||
                    trek.region.localizedCaseInsensitiveContains("Kerala") ||
                    trek.region.localizedCaseInsensitiveContains("Nilgiri") ||
                    trek.region.localizedCaseInsensitiveContains("Coorg") ||
                    trek.region.localizedCaseInsensitiveContains("Wayanad") ||
                    trek.region.localizedCaseInsensitiveContains("Munnar") ||
                    trek.region.localizedCaseInsensitiveContains("Chikkamagaluru")
                )
            case .conquered:
                return trek.status == .conquered
            case .wishlist:
                return trek.status == .wishlist
            case .highest:
                return trek.elevationMeters >= 3000
            }
        }
    }

    // Telemetry aggregations
    private var conqueredTreks: [TrekRecord] {
        activeTreks.filter { $0.status == .conquered }
    }

    private var totalConqueredCount: Int {
        conqueredTreks.count
    }

    private var highestConqueredElevation: Double {
        conqueredTreks.map(\.elevationMeters).max() ?? 0.0
    }

    private var highestConqueredName: String {
        conqueredTreks.max(by: { $0.elevationMeters < $1.elevationMeters })?.name ?? "None yet"
    }

    private var totalVerticalGain: Double {
        conqueredTreks.compactMap(\.elevationGainMeters).reduce(0, +)
    }

    private var totalDistanceKm: Double {
        conqueredTreks.compactMap(\.trailDistanceKm).reduce(0, +)
    }

    private var currentRank: ExplorerRank {
        MountaineerRankEngine.currentRank(conqueredTreks: conqueredTreks)
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Expedition Stats Banner with Layout Switcher
            expeditionTelemetryBanner

            Divider()

            // MARK: - Selected Layout View Canvas
            GeometryReader { geo in
                layoutBody(geo: geo)
            }
        }
        .overlay {
            if let qTrek = quickLookTrek {
                SummitPhotoQuickLookModal(
                    trek: qTrek,
                    currentPhotoIndex: $quickLookPhotoIndex,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            quickLookTrek = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .sheet(isPresented: $isLogModalPresented) {
            LogTrekModal { newTrek in
                modelContext.insert(newTrek)
                try? modelContext.save()
                withAnimation {
                    selectedTrek = newTrek
                }
                Haptics.notification(.success)
            }
        }
        .sheet(isPresented: $isTrophyCabinetPresented) {
            MountaineerTrophyCabinetModal(
                conqueredTreks: conqueredTreks,
                allTreks: activeTreks,
                onDismiss: {
                    isTrophyCabinetPresented = false
                }
            )
        }
        .sheet(item: $passportTrek) { trek in
            ExpeditionPassportModal(trek: trek) {
                passportTrek = nil
            }
        }
        .sheet(isPresented: $isWatchSyncPresented) {
            AppleWatchTrekSyncModal(allTreks: activeTreks) {
                isWatchSyncPresented = false
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                TrekSeeder.seedIfNeeded(context: modelContext)
                if selectedTrek == nil {
                    selectedTrek = filteredTreks.first
                }
            }
        }
    }

    @ViewBuilder
    private func layoutBody(geo: GeometryProxy) -> some View {
        switch selectedLayout {
        case .splitMapInspector:
            splitMapLayout(geo: geo)
        case .editorialList:
            editorialCardsLayout(geo: geo)
        }
    }

    // MARK: - Subviews

    // MARK: - Expedition Stats Banner with Layout Switcher

    private var expeditionTelemetryBanner: some View {
        HStack(spacing: DS.Space.lg) {

            // Stat 1: Summits Conquered
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.cyan)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(totalConqueredCount) SUMMITS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Conquered Milestones")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 20)

            // Stat 2: Highest Peak
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.orange)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(highestConqueredElevation > 0 ? "\(Int(highestConqueredElevation).formatted()) m" : "—")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(highestConqueredName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Divider().frame(height: 20)

            // Stat 3: Total Vertical Gain
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.purple)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(totalVerticalGain > 0 ? "+\(Int(totalVerticalGain).formatted()) m" : "—")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Vertical Ascended")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 20)

            // Stat 4: Explorer Mountaineer Rank & Trophy Cabinet Button
            Button {
                isTrophyCabinetPresented = true
                Haptics.impact(.medium)
            } label: {
                HStack(spacing: DS.Space.sm) {
                    ZStack {
                        Circle()
                            .fill(currentRank.accentColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: currentRank.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(currentRank.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 3) {
                            Text(currentRank.title.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        Text("Rank \(currentRank.rawValue) · Trophy Cabinet")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(currentRank.accentColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Open Trophy Cabinet")

            Divider().frame(height: 20)

            // Apple Watch Sync Button
            Button {
                isWatchSyncPresented = true
                Haptics.impact(.medium)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.orange)
                    Text("Watch Sync")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Sync routes & summit waypoints with Apple Watch")

            Spacer()

            // MARK: - Layout Switcher Segmented Control
            HStack(spacing: 2) {
                ForEach(TrekAtlasLayoutVariant.allCases) { layout in
                    let isSelected = selectedLayout == layout
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedLayout = layout
                        }
                        Haptics.impact(.light)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: layout.icon)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            Text(layout.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundStyle(isSelected ? Color.white : DS.Color.textSecondary)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(
                            isSelected
                                ? LinearGradient(colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .frame(height: 32)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 8))

            Divider().frame(height: 20)

            // Primary Action: + Log Trek
            Button {
                isLogModalPresented = true
                Haptics.impact(.medium)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Log Trek / Peak")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.6, blue: 0.9), Color(red: 0.38, green: 0.45, blue: 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, 10)
        .background(DS.Color.surface)
    }

    // MARK: - Layout 1: Split Map + Peak Directory
    private func splitMapLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left Side: Peak Directory Column (380px)
            VStack(spacing: 0) {
                searchAndFilterHeader
                Divider()
                trekListScrollView
            }
            .frame(width: min(380, geo.size.width * 0.38))
            .background(DS.Color.surface)

            Divider()

            // Right Side: Native Map Canvas with Detail Inspector Overlay
            ZStack(alignment: .bottomTrailing) {
                MacTrekMapView(
                    treks: filteredTreks,
                    selectedTrek: selectedTrek,
                    scrubCoordinate: scrubCoordinate,
                    isFlyingTrail: isFlyingTrail,
                    onFinishFlyTrail: {
                        isFlyingTrail = false
                    },
                    onSelectTrek: { trek in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTrek = trek
                        }
                        Haptics.impact(.light)
                    }
                )
                .edgesIgnoringSafeArea(.all)

                // Top-Left Floating Range Quick Jump Bar
                VStack(alignment: .leading, spacing: 6) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            rangeJumpButton(title: "All Summits 🇮🇳", trek: nil)
                            rangeJumpButton(title: "Girnar 🦁", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Girnar") }))
                            rangeJumpButton(title: "Pavagadh 🪷", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Pavagadh") }))
                            rangeJumpButton(title: "Kalsubai 🏰", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Kalsubai") }))
                            rangeJumpButton(title: "Harishchandragad ⚔️", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Harishchandragad") }))
                            rangeJumpButton(title: "Mount Abu 🏜️", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Guru Shikhar") || $0.name.localizedCaseInsensitiveContains("Abu") }))
                            rangeJumpButton(title: "Kedarkantha 🕉️", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Kedarkantha") }))
                            rangeJumpButton(title: "Stok Kangri ❄️", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Stok Kangri") }))
                            rangeJumpButton(title: "Kangchenjunga 🏔️", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Kangchenjunga") || $0.name.localizedCaseInsensitiveContains("Goechala") }))
                            rangeJumpButton(title: "Anamudi 🌴", trek: allTreks.first(where: { $0.name.localizedCaseInsensitiveContains("Anamudi") || $0.name.localizedCaseInsensitiveContains("Chembra") }))
                        }
                        .padding(4)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Floating Detail Inspector Card
                if let selectedTrek {
                    TrekDetailOverlay(
                        trek: selectedTrek,
                        onToggleStatus: {
                            toggleTrekStatus(selectedTrek)
                        },
                        onOpenPassport: {
                            passportTrek = selectedTrek
                        },
                        onOpenQuickLook: { fileName, index in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                quickLookTrek = selectedTrek
                                quickLookPhotoIndex = index
                            }
                        },
                        onScrubCoordinate: { coord in
                            self.scrubCoordinate = coord
                        },
                        onFlyTrail: {
                            withAnimation {
                                isFlyingTrail = true
                            }
                            Haptics.impact(.medium)
                        },
                        onClose: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                self.selectedTrek = nil
                                self.scrubCoordinate = nil
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(DS.Space.lg)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Layout 2: Editorial Expedition Cards (50/50 Split Magazine Style)
    private func editorialCardsLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left 50%: Vertical Editorial Cards
            VStack(spacing: 0) {
                searchAndFilterHeader
                Divider()
                ScrollView {
                    LazyVStack(spacing: DS.Space.md) {
                        ForEach(filteredTreks) { trek in
                            TrekEditorialCard(
                                trek: trek,
                                isSelected: selectedTrek?.id == trek.id,
                                onSelect: {
                                    selectedTrek = trek
                                    Haptics.impact(.light)
                                },
                                onToggleStatus: {
                                    toggleTrekStatus(trek)
                                },
                                onOpenPassport: {
                                    passportTrek = trek
                                },
                                onOpenQuickLook: { _, idx in
                                    quickLookTrek = trek
                                    quickLookPhotoIndex = idx
                                }
                            )
                        }
                    }
                    .padding(DS.Space.md)
                }
            }
            .frame(width: geo.size.width * 0.5)
            .background(DS.Color.surface)

            Divider()

            // Right 50%: Focused Route & Elevation Inspection Canvas
            VStack(spacing: 0) {
                if let trek = selectedTrek {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DS.Space.lg) {
                            // Topo Map Preview
                            MacTrekMapView(
                                treks: [trek],
                                selectedTrek: trek,
                                scrubCoordinate: scrubCoordinate,
                                isFlyingTrail: isFlyingTrail,
                                onFinishFlyTrail: { isFlyingTrail = false },
                                onSelectTrek: { _ in }
                            )
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(Color.white.opacity(0.1), lineWidth: 1))

                            // Elevation Profile Chart
                            TrekElevationProfileChart(
                                trek: trek,
                                onScrubCoordinate: { coord in
                                    self.scrubCoordinate = coord
                                },
                                onFlyTrail: {
                                    isFlyingTrail = true
                                }
                            )

                            // Apple Journal Linking & Notes
                            TrekJournalLinkSection(trek: trek)
                        }
                        .padding(DS.Space.xl)
                    }
                } else {
                    VStack(spacing: DS.Space.md) {
                        Image(systemName: "mountain.2")
                            .font(.system(size: 40))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("Select an expedition card to read field notes & inspect trail")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: geo.size.width * 0.5)
            .background(DS.Color.surfaceRecessed)
        }
    }

    private var searchAndFilterHeader: some View {
        VStack(spacing: DS.Space.sm) {

            // Search Field
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.textTertiary)

                TextField("Search mountains, summits, regions...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
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

            // Filter Tabs with Standardized Box Size & Single-Line Font
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TrekFilter.allCases) { filter in
                        let isSelected = selectedFilter == filter
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
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
                                            colors: [Color(red: 0.28, green: 0.45, blue: 0.98), Color(red: 0.48, green: 0.38, blue: 0.98)],
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
                                        .stroke(isSelected ? Color.blue.opacity(0.5) : DS.Color.border.opacity(0.4), lineWidth: 1)
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

    private var trekListScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                if filteredTreks.isEmpty {
                    VStack(spacing: DS.Space.md) {
                        Image(systemName: "mountain.2")
                            .font(.system(size: 32))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("No mountain peaks found")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(filteredTreks) { trek in
                        TrekListCard(
                            trek: trek,
                            isSelected: selectedTrek?.id == trek.id,
                            onSelect: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedTrek = trek
                                }
                                Haptics.impact(.light)
                            },
                            onToggleStatus: {
                                toggleTrekStatus(trek)
                            },
                            onDelete: {
                                modelContext.delete(trek)
                                try? modelContext.save()
                                if selectedTrek?.id == trek.id {
                                    selectedTrek = filteredTreks.first(where: { $0.id != trek.id })
                                }
                            }
                        )
                    }
                }
            }
            .padding(DS.Space.sm)
        }
    }

    // MARK: - Actions

    private func rangeJumpButton(title: String, trek: TrekRecord?) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if let trek {
                    selectedTrek = trek
                } else {
                    selectedTrek = nil
                }
            }
            Haptics.selection()
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(
                    selectedTrek?.id == trek?.id && trek != nil
                        ? Color.orange
                        : Color.white.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
    }

    private func toggleTrekStatus(_ trek: TrekRecord) {
        if trek.status == .conquered {
            trek.status = .wishlist
            trek.dateConquered = nil
        } else {
            trek.status = .conquered
            trek.dateConquered = Date()
        }
        try? modelContext.save()
        Haptics.notification(.success)
    }
}

// MARK: - TrekListCard

struct TrekListCard: View {
    let trek: TrekRecord
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleStatus: () -> Void
    let onDelete: () -> Void

    @State private var isHovered: Bool = false

    private var isConquered: Bool { trek.status == .conquered }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DS.Space.md) {

                // Status Icon Badge
                Button(action: onToggleStatus) {
                    ZStack {
                        Circle()
                            .fill(isConquered ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
                            .frame(width: 32, height: 32)

                        Image(systemName: isConquered ? "trophy.fill" : "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isConquered ? Color.cyan : DS.Color.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .help(isConquered ? "Mark as Wishlist" : "Mark as Conquered")

                // Main Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(trek.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        // Altitude Badge
                        Text("\(Int(trek.elevationMeters).formatted()) m")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(isConquered ? Color.cyan : DS.Color.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                isConquered ? Color.cyan.opacity(0.12) : DS.Color.surfaceRecessed,
                                in: RoundedRectangle(cornerRadius: 4)
                            )
                    }

                    HStack(spacing: 8) {
                        Text("\(trek.region), \(trek.country)")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineLimit(1)

                        if let gain = trek.formattedGain {
                            Text("· \(gain)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.purple.opacity(0.8))
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.sm)
            .background(
                isSelected ? Color(red: 0.38, green: 0.45, blue: 0.98).opacity(0.18) : (isHovered ? DS.Color.surfaceRecessed.opacity(0.6) : Color.clear),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(red: 0.38, green: 0.45, blue: 0.98).opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(isConquered ? "Mark as Wishlist 📍" : "Mark as Conquered 🏆") {
                onToggleStatus()
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Trek", systemImage: "trash")
            }
        }
    }
}

// MARK: - TrekDetailOverlay

struct TrekDetailOverlay: View {
    let trek: TrekRecord
    let onToggleStatus: () -> Void
    var onOpenPassport: () -> Void = {}
    var onOpenQuickLook: (String, Int) -> Void = { _, _ in }
    var onScrubCoordinate: (CLLocationCoordinate2D?) -> Void = { _ in }
    var onFlyTrail: () -> Void = {}
    let onClose: () -> Void

    private var isConquered: Bool { trek.status == .conquered }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top Header (Pinned)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(trek.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        if isConquered {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.cyan)
                        }
                    }

                    Text("\(trek.region), \(trek.country)")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, DS.Space.sm)

            // Scrollable Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: DS.Space.md) {

                    // Metric Pills Grid
                    HStack(spacing: DS.Space.sm) {
                        // Elevation
                        VStack(alignment: .leading, spacing: 1) {
                            Text("ELEVATION")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                            Text(trek.formattedElevation)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(DS.Color.textPrimary)
                        }
                        .padding(8)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))

                        // Trail Distance
                        if let dist = trek.formattedDistance {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DISTANCE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)
                                Text(dist)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                            .padding(8)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }

                        // Vertical Gain
                        if let gain = trek.formattedGain {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("VERT GAIN")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)
                                Text(gain)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.purple)
                            }
                            .padding(8)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }

                        // Difficulty
                        VStack(alignment: .leading, spacing: 1) {
                            Text("DIFFICULTY")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                            Text(trek.difficulty.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: trek.difficulty.badgeColorHex) ?? DS.Color.textPrimary)
                        }
                        .padding(8)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    }

                    // Apple Watch Biometrics Telemetry Capsule
                    if let avgHR = trek.avgHeartRate {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "applewatch")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.orange)
                                Text("APPLE WATCH")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.orange)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.12), in: Capsule())

                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.red)
                                Text("\(Int(avgHR)) bpm avg")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }

                            if let cal = trek.activeCalories {
                                HStack(spacing: 3) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.orange)
                                    Text("\(Int(cal).formatted()) kcal")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(DS.Color.textPrimary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                    }

                    // Alpine Elevation Profile Chart (4.3 aa2 + aa3 + aa4)
                    TrekElevationProfileChart(
                        trek: trek,
                        points: TrekElevationProfileEngine.generateProfile(for: trek),
                        onScrubPoint: { pt in
                            onScrubCoordinate(pt?.coordinate)
                        }
                    )

                    // Notes Section
                    if !trek.personalNotes.isEmpty {
                        Text(trek.personalNotes)
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Color.textSecondary)
                            .padding(8)
                            .background(DS.Color.surfaceRecessed.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                    }

                    // Summit Photo Memories (4.1)
                    if !trek.photoFileNames.isEmpty {
                        SummitPhotoStripView(trek: trek) { fileName, index in
                            onOpenQuickLook(fileName, index)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("SUMMIT MEMORIES")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)

                                Spacer()

                                Button {
                                    Task {
                                        let fileNames = await TrekPhotoPickerHelper.pickSummitPhotos()
                                        guard !fileNames.isEmpty else { return }
                                        trek.attachPhotos(fileNames: fileNames)
                                        Haptics.notification(.success)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 10, weight: .semibold))
                                        Text("Add Photos")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundStyle(Color.cyan)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Color.textTertiary)
                                Text("Drag & drop photos here or click Add Photos")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Color.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(DS.Color.surfaceRecessed.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .foregroundStyle(DS.Color.textTertiary.opacity(0.5))
                            )
                        }
                    }

                    // GPX Trail Ridge Track (4.2)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.cyan)
                                Text(trek.hasGPXTrack ? "GPS RIDGE TRAIL" : "GPX TRAIL TRACK")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }

                            Spacer()

                            if trek.hasGPXTrack {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        trek.removeGPXTrack()
                                    }
                                    Haptics.impact(.medium)
                                } label: {
                                    Text("Remove")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Color.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    Task {
                                        if let result = await TrekGPXPickerHelper.pickGPXFile() {
                                            trek.attachGPXTrack(result: result)
                                            Haptics.notification(.success)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 9, weight: .bold))
                                        Text("Import GPX")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundStyle(Color.cyan)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if trek.hasGPXTrack {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.cyan)
                                Text("\(trek.decodedTrackPoints.count.formatted()) GPS Trackpoints")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(DS.Color.textPrimary)

                                Spacer()

                                Button {
                                    onFlyTrail()
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 8))
                                        Text("Fly Trail")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundStyle(Color.cyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.cyan.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // Apple Journal Cross-Link Drawer (4.1)
                    TrekJournalLinkSection(trek: trek)
                }
                .padding(.vertical, DS.Space.xs)
            }
            .frame(maxHeight: 460)

            Divider().padding(.vertical, DS.Space.xs)

            // Bottom Action Bar: Passport + Status Toggle
            HStack(spacing: 8) {
                Button {
                    onOpenPassport()
                    Haptics.impact(.medium)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 11))
                        Text("Passport")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.30))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onToggleStatus) {
                    HStack(spacing: 4) {
                        Image(systemName: isConquered ? "arrow.uturn.backward" : "trophy.fill")
                        Text(isConquered ? "Wishlist" : "Conquer 🏆")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isConquered ? DS.Color.textPrimary : Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isConquered ? DS.Color.surfaceRecessed : Color.cyan,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.md)
        .frame(width: 370)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                // Check if dropped file is a GPX track
                if let gpxResult = await TrekGPXPickerHelper.processDroppedGPXProviders(providers) {
                    trek.attachGPXTrack(result: gpxResult)
                    Haptics.notification(.success)
                    return
                }

                // Otherwise process as photo attachments
                let fileNames = await TrekPhotoPickerHelper.processDroppedProviders(providers)
                guard !fileNames.isEmpty else { return }
                trek.attachPhotos(fileNames: fileNames)
                Haptics.notification(.success)
            }
            return true
        }
    }
}

// MARK: - LogTrekModal

struct LogTrekModal: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (TrekRecord) -> Void

    @State private var name: String = ""
    @State private var region: String = ""
    @State private var country: String = ""
    @State private var elevationMeters: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var trailDistanceKm: String = ""
    @State private var elevationGainMeters: String = ""
    @State private var status: TrekStatus = .conquered
    @State private var difficulty: TrekDifficulty = .moderate
    @State private var personalNotes: String = ""
    @State private var photoFileNames: [String] = []
    @State private var importedGPXResult: GPXParseResult? = nil

    @State private var searchQuery: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(elevationMeters) ?? 0) > 0 &&
        Double(latitude) != nil &&
        Double(longitude) != nil
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Log Mountain Peak or Trail")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Search Apple Maps, import a GPX file, or enter details manually")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.lg)

            Divider()

            // Form Content
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.md) {

                    // GPX Auto-Fill Shortcut Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                                    .foregroundStyle(Color.cyan)
                                Text("Import GPX Track")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                            Text(importedGPXResult != nil ? "✓ GPX Loaded (\(importedGPXResult!.trackPoints.count) trackpoints)" : "Auto-fill distance, vert gain, altitude & GPS coordinates")
                                .font(.system(size: 10))
                                .foregroundStyle(importedGPXResult != nil ? Color.cyan : DS.Color.textSecondary)
                        }

                        Spacer()

                        Button {
                            Task {
                                if let result = await TrekGPXPickerHelper.pickGPXFile() {
                                    applyGPXResult(result)
                                    Haptics.notification(.success)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                Text(importedGPXResult != nil ? "Replace GPX" : "Choose GPX File")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.cyan.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                    )

                    // Apple Maps Search Autocomplete Bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Apple Maps for Peak / Trail")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.cyan)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(DS.Color.textTertiary)
                            TextField("e.g. Mount Rainier, Matterhorn, Yosemite Half Dome...", text: $searchQuery)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .onChange(of: searchQuery) { _, query in
                                    performLocalSearch(query: query)
                                }

                            if isSearching {
                                ProgressView().controlSize(.small)
                            }
                        }
                        .padding(8)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))

                        // Autocomplete Results Dropdown
                        if !searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(searchResults.prefix(4), id: \.self) { item in
                                    Button {
                                        selectMapItem(item)
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(Color.cyan)
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(item.name ?? "Unknown Peak")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(DS.Color.textPrimary)
                                                if let sub = item.placemark.title {
                                                    Text(sub)
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(DS.Color.textSecondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                            Text("Select")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(Color.cyan)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 5))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    Divider()

                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Peak / Trail Name *").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                        TextField("e.g. Mount Rainier, Kalsubai Peak", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Region & Country
                    HStack(spacing: DS.Space.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Region / State").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            TextField("e.g. Washington, Maharashtra", text: $region)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Country").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            TextField("e.g. USA, India, Japan", text: $country)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Elevation & Distance
                    HStack(spacing: DS.Space.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Elevation (Meters) *").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            TextField("e.g. 4392", text: $elevationMeters)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trail Distance (Km)").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            TextField("e.g. 14.5", text: $trailDistanceKm)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vert Gain (Meters)").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            TextField("e.g. 1200", text: $elevationGainMeters)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Coordinates
                    HStack(spacing: DS.Space.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latitude *").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            TextField("e.g. 46.8523", text: $latitude)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Longitude *").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            TextField("e.g. -121.7603", text: $longitude)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Status & Difficulty Pickers
                    HStack(spacing: DS.Space.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            Picker("", selection: $status) {
                                Text("🏆 Conquered").tag(TrekStatus.conquered)
                                Text("📍 Wishlist").tag(TrekStatus.wishlist)
                                Text("🏃 In Progress").tag(TrekStatus.inProgress)
                            }
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Difficulty").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            Picker("", selection: $difficulty) {
                                ForEach(TrekDifficulty.allCases, id: \.self) { diff in
                                    Text(diff.title).tag(diff)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    // Attach Summit Photos
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Summit Photos").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                            Spacer()
                            Button {
                                Task {
                                    let files = await TrekPhotoPickerHelper.pickSummitPhotos()
                                    photoFileNames.append(contentsOf: files)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.badge.plus")
                                    Text("Add Photos (\(photoFileNames.count))")
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.cyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Personal Reflections / Notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summit Reflections & Memories").font(.system(size: 11, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
                        TextEditor(text: $personalNotes)
                            .frame(height: 70)
                            .font(.system(size: 12))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                    }
                }
                .padding(DS.Space.xl)
            }

            Divider()

            // Save Action
            HStack {
                Spacer()
                Button("Save Trek to Atlas") {
                    let elevation = Double(elevationMeters) ?? 0
                    let lat = Double(latitude) ?? 0
                    let lon = Double(longitude) ?? 0
                    let dist = Double(trailDistanceKm)
                    let gain = Double(elevationGainMeters)

                    let newTrek = TrekRecord(
                        name: name.trimmingCharacters(in: .whitespaces),
                        region: region.trimmingCharacters(in: .whitespaces),
                        country: country.trimmingCharacters(in: .whitespaces),
                        latitude: lat,
                        longitude: lon,
                        elevationMeters: elevation,
                        trailDistanceKm: dist,
                        elevationGainMeters: gain,
                        status: status,
                        difficulty: difficulty,
                        dateConquered: status == .conquered ? Date() : nil,
                        personalNotes: personalNotes,
                        photoFileNames: photoFileNames
                    )

                    if let gpx = importedGPXResult {
                        newTrek.attachGPXTrack(result: gpx)
                    }

                    onSave(newTrek)
                    dismiss()
                }
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.md)
            .background(DS.Color.surface)
        }
        .frame(width: 500, height: 600)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                if let result = await TrekGPXPickerHelper.processDroppedGPXProviders(providers) {
                    applyGPXResult(result)
                    Haptics.notification(.success)
                    return
                }

                let files = await TrekPhotoPickerHelper.processDroppedProviders(providers)
                guard !files.isEmpty else { return }
                photoFileNames.append(contentsOf: files)
                Haptics.notification(.success)
            }
            return true
        }
    }

    private func applyGPXResult(_ result: GPXParseResult) {
        self.importedGPXResult = result
        if let tName = result.trackName, !tName.isEmpty, self.name.isEmpty {
            self.name = tName
        }
        if result.totalDistanceKm > 0 {
            self.trailDistanceKm = String(format: "%.1f", result.totalDistanceKm)
        }
        if result.elevationGainMeters > 0 {
            self.elevationGainMeters = String(format: "%.0f", result.elevationGainMeters)
        }
        if result.maxAltitudeMeters > 0 {
            self.elevationMeters = String(format: "%.0f", result.maxAltitudeMeters)
        }
        if let summit = result.summitCoordinate {
            self.latitude = String(format: "%.5f", summit.latitude)
            self.longitude = String(format: "%.5f", summit.longitude)
        }
    }

    private func performLocalSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = [.pointOfInterest, .address]

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                guard let response = response, error == nil else {
                    self.searchResults = []
                    return
                }
                self.searchResults = response.mapItems
            }
        }
    }

    private func selectMapItem(_ item: MKMapItem) {
        if let placeName = item.name {
            self.name = placeName
        }
        if let state = item.placemark.administrativeArea {
            self.region = state
        }
        if let c = item.placemark.country {
            self.country = c
        }
        self.latitude = String(format: "%.5f", item.placemark.coordinate.latitude)
        self.longitude = String(format: "%.5f", item.placemark.coordinate.longitude)
        self.searchResults = []
        self.searchQuery = ""
    }
}
