import SwiftUI
import SwiftData
import MapKit

// MARK: - TrekFilter

enum TrekFilter: String, CaseIterable, Identifiable {
    case all       = "All Summits"
    case conquered = "Conquered 🏆"
    case wishlist  = "Wishlist 📍"
    case highest   = "Highest Peaks ⛰️"

    var id: String { rawValue }
}

// MARK: - MacTrekAtlasCanvas

/// Full-screen interactive Trek & Mountain Atlas for Pluto.
/// Integrates a responsive mountain explorer list, native MapKit canvas,
/// expedition telemetry banner, and 1-click summit milestone toggling.
struct MacTrekAtlasCanvas: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrekRecord.elevationMeters, order: .reverse) private var allTreks: [TrekRecord]

    @State private var selectedTrek: TrekRecord? = nil
    @State private var searchText: String = ""
    @State private var selectedFilter: TrekFilter = .all
    @State private var isLogModalPresented: Bool = false

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

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Expedition Stats Banner
            expeditionTelemetryBanner

            Divider()

            // MARK: - Main Split Explorer View
            GeometryReader { geo in
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
                            onSelectTrek: { trek in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedTrek = trek
                                }
                                Haptics.impact(.light)
                            }
                        )
                        .edgesIgnoringSafeArea(.all)

                        // Floating Detail Inspector Card
                        if let selectedTrek {
                            TrekDetailOverlay(
                                trek: selectedTrek,
                                onToggleStatus: {
                                    toggleTrekStatus(selectedTrek)
                                },
                                onClose: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        self.selectedTrek = nil
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
        .onAppear {
            TrekSeeder.seedIfNeeded(context: modelContext)
            if selectedTrek == nil {
                selectedTrek = filteredTreks.first
            }
        }
    }

    // MARK: - Subviews

    private var expeditionTelemetryBanner: some View {
        HStack(spacing: DS.Space.xl) {

            // Stat 1: Summits Conquered
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.cyan)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(totalConqueredCount) SUMMITS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Conquered Milestones")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 24)

            // Stat 2: Highest Peak
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.orange)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(highestConqueredElevation > 0 ? "\(Int(highestConqueredElevation).formatted()) m" : "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(highestConqueredName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Divider().frame(height: 24)

            // Stat 3: Total Vertical Gain
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.purple)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(totalVerticalGain > 0 ? "+\(Int(totalVerticalGain).formatted()) m" : "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Total Vertical Ascended")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 24)

            // Stat 4: Total Trail Distance
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.green)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(totalDistanceKm > 0 ? String(format: "%.1f km", totalDistanceKm) : "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Total Trail Distance")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Spacer()

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
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.6, blue: 0.9), Color(red: 0.38, green: 0.45, blue: 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 7)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface)
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

            // Filter Tabs
            HStack(spacing: 4) {
                ForEach(TrekFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    Button {
                        selectedFilter = filter
                        Haptics.impact(.light)
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : DS.Color.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                isSelected ? Color(red: 0.38, green: 0.45, blue: 0.98) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
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
                            .font(DS.Text.subheadline)
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
    let onClose: () -> Void

    private var isConquered: Bool { trek.status == .conquered }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {

            // Top Header
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

            // Notes Section
            if !trek.personalNotes.isEmpty {
                Text(trek.personalNotes)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(8)
                    .background(DS.Color.surfaceRecessed.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            }

            // Photos / Media Section Header
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

            // Dotted Dropzone or Photo Count Pill
            if trek.photoFileNames.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Drag & drop summit photos here or click Add Photos")
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

            // Bottom Action Toggle
            Button(action: onToggleStatus) {
                HStack {
                    Image(systemName: isConquered ? "arrow.uturn.backward" : "trophy.fill")
                    Text(isConquered ? "Mark as Wishlist 📍" : "Mark as Conquered 🏆")
                }
                .font(.system(size: 12, weight: .bold))
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
        .padding(DS.Space.md)
        .frame(width: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
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
                    Text("Search Apple Maps or enter coordinates manually")
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
        .frame(width: 480, height: 560)
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
