import SwiftUI
import SwiftData
import MapKit
import UniformTypeIdentifiers

// MARK: - TrekFilter

enum TrekFilter: String, CaseIterable, Identifiable {
    case all          = "All"
    case himalayas    = "Himalayas 🏔️"
    case westernGhats = "Western Ghats 🌿"
    case gujarat      = "Gujarat 🦁"
    case maharashtra  = "Maharashtra 🏰"
    case rajasthan    = "Rajasthan 🏜️"
    case conquered    = "Conquered 🏆"
    case wishlist     = "Wishlist 📍"

    var id: String { rawValue }
}

// MARK: - MacTrekAtlasCanvas (Minimalist Sovereign Expedition & Mountain Atlas)

struct MacTrekAtlasCanvas: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrekRecord.elevationMeters, order: .reverse) private var allTreks: [TrekRecord]

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
            let matchesSearch = searchText.isEmpty
                || trek.name.localizedCaseInsensitiveContains(searchText)
                || trek.region.localizedCaseInsensitiveContains(searchText)
                || trek.country.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch selectedFilter {
            case .all:
                return true
            case .himalayas:
                return trek.region.localizedCaseInsensitiveContains("Himalaya") ||
                       trek.region.localizedCaseInsensitiveContains("Uttarakhand") ||
                       trek.region.localizedCaseInsensitiveContains("Ladakh") ||
                       trek.region.localizedCaseInsensitiveContains("Sikkim") ||
                       trek.region.localizedCaseInsensitiveContains("Himachal") ||
                       trek.region.localizedCaseInsensitiveContains("Nepal") ||
                       trek.elevationMeters >= 3000
            case .westernGhats:
                return trek.region.localizedCaseInsensitiveContains("Western Ghats") ||
                       trek.region.localizedCaseInsensitiveContains("Maharashtra") ||
                       trek.region.localizedCaseInsensitiveContains("Sahyadri") ||
                       trek.region.localizedCaseInsensitiveContains("Karnataka") ||
                       trek.region.localizedCaseInsensitiveContains("Kerala")
            case .gujarat:
                return trek.region.localizedCaseInsensitiveContains("Gujarat") ||
                       trek.region.localizedCaseInsensitiveContains("Junagadh") ||
                       trek.region.localizedCaseInsensitiveContains("Pavagadh") ||
                       trek.region.localizedCaseInsensitiveContains("Girnar")
            case .maharashtra:
                return trek.region.localizedCaseInsensitiveContains("Maharashtra") ||
                       trek.region.localizedCaseInsensitiveContains("Sahyadri") ||
                       trek.region.localizedCaseInsensitiveContains("Kalsubai") ||
                       trek.region.localizedCaseInsensitiveContains("Harishchandragad")
            case .rajasthan:
                return trek.region.localizedCaseInsensitiveContains("Rajasthan") ||
                       trek.region.localizedCaseInsensitiveContains("Aravalli") ||
                       trek.region.localizedCaseInsensitiveContains("Abu")
            case .conquered:
                return trek.status == .conquered
            case .wishlist:
                return trek.status == .wishlist
            }
        }
    }

    private var conqueredTreks: [TrekRecord] {
        activeTreks.filter { $0.status == .conquered }
    }

    private var currentRank: ExplorerRank {
        MountaineerRankEngine.currentRank(conqueredTreks: conqueredTreks)
    }

    var body: some View {
        VStack(spacing: 0) {

            // 1. MINIMALIST EXPEDITION TOP HEADER
            minimalTopBar

            Divider().opacity(0.18)

            // 2. MAIN 2-PANE SPATIAL MAP WORKSPACE
            HSplitView {
                // Left Column: Peak Directory (320–380pt)
                VStack(spacing: 0) {
                    peakSearchAndFilterHeader
                    Divider().opacity(0.15)
                    peakListScrollView
                }
                .frame(minWidth: 300, idealWidth: 330, maxWidth: 400)
                .background(Color(nsColor: NSColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)))

                // Right Column: Full-Canvas Topo Map & Floating Peak Inspector
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
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                selectedTrek = trek
                            }
                            Haptics.impact(.light)
                        }
                    )
                    .edgesIgnoringSafeArea(.all)

                    // Floating Glassmorphic Peak Inspector Card
                    if let trek = selectedTrek {
                        floatingPeakInspector(trek: trek)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(18)
                    }
                }
                .frame(minWidth: 460, maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Minimalist Top Bar

    private var minimalTopBar: some View {
        HStack(spacing: 12) {
            
            // Left: Title & Live Elevation Telemetry
            HStack(spacing: 8) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.cyan)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Expeditions & Mountain Atlas")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text("\(conqueredTreks.count) Conquered · Rank: \(currentRank.title) · \(Int(conqueredTreks.compactMap(\.elevationGainMeters).reduce(0, +)).formatted()) m Vertical Ascended")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }

            Spacer()

            // Right Actions: Trophy Cabinet | Watch Sync | + Log Peak
            HStack(spacing: 8) {
                
                // Trophy Cabinet
                Button {
                    isTrophyCabinetPresented = true
                    Haptics.impact(.medium)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.yellow)
                        Text("Trophies")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
                .help("Open Trophy Cabinet & Summit Badges")

                // Apple Watch Sync
                Button {
                    isWatchSyncPresented = true
                    Haptics.impact(.medium)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundStyle(Color.orange)
                        Text("Watch Sync")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
                .help("Sync summit routes with Apple Watch")

                // + Log Peak
                Button {
                    isLogModalPresented = true
                    Haptics.impact(.medium)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Log Peak")
                            .font(.system(size: 11.5, weight: .bold))
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.95, green: 0.75, blue: 0.25), in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: NSColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1.0)))
    }

    // MARK: - Search & Filter Header

    private var peakSearchAndFilterHeader: some View {
        VStack(spacing: 8) {
            
            // Search Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.4))

                TextField("Search mountains, regions...", text: $searchText)
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
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // Minimal Horizontal Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(TrekFilter.allCases) { filter in
                        let isSelected = selectedFilter == filter
                        Button {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                selectedFilter = filter
                            }
                            Haptics.impact(.light)
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.7))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(
                                    isSelected ? Color(red: 0.95, green: 0.75, blue: 0.25) : Color.white.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 5)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlutoFastButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
    }

    // MARK: - Peak Directory ScrollView

    private var peakListScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                if filteredTreks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "mountain.2")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.white.opacity(0.3))
                        Text("No mountain peaks found")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(filteredTreks) { trek in
                        let isSelected = selectedTrek?.id == trek.id
                        let isConquered = trek.status == .conquered

                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedTrek = trek
                            }
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 10) {
                                
                                // Status Icon
                                Image(systemName: isConquered ? "trophy.fill" : "mappin.and.ellipse")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isConquered ? Color.yellow : Color.white.opacity(0.4))
                                    .frame(width: 24, height: 24)
                                    .background(isConquered ? Color.yellow.opacity(0.15) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))

                                // Name & Region
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trek.name)
                                        .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(Color.white)
                                        .lineLimit(1)

                                    Text("\(trek.region), \(trek.country)")
                                        .font(.system(size: 10.5))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                        .lineLimit(1)
                                }

                                Spacer()

                                // Elevation Badge
                                Text("\(Int(trek.elevationMeters).formatted()) m")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isConquered ? Color.cyan : Color.white.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                isSelected
                                    ? Color.accentColor.opacity(0.18)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 7)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlutoFastButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Floating Peak Inspector Card (Apple Maps Glassmorphic Style)

    private func floatingPeakInspector(trek: TrekRecord) -> some View {
        let isConquered = trek.status == .conquered

        return VStack(alignment: .leading, spacing: 10) {
            
            // Header: Title, Region, Close Button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(trek.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)

                        if isConquered {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.yellow)
                        }
                    }

                    Text("\(trek.region), \(trek.country)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.55))
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedTrek = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.15)

            // Metrics Grid
            HStack(spacing: 6) {
                metricPill(label: "ELEVATION", value: "\(Int(trek.elevationMeters).formatted()) m", color: Color.cyan)
                if let gain = trek.formattedGain {
                    metricPill(label: "VERT GAIN", value: gain, color: Color.purple)
                }
                metricPill(label: "DIFFICULTY", value: trek.difficulty.title, color: Color(hex: trek.difficulty.badgeColorHex) ?? Color.orange)
            }

            // Elevation Profile Mini-Chart
            TrekElevationProfileChart(
                trek: trek,
                points: TrekElevationProfileEngine.generateProfile(for: trek),
                onScrubPoint: { pt in
                    self.scrubCoordinate = pt?.coordinate
                }
            )
            .frame(height: 70)

            Divider().opacity(0.15)

            // Action Buttons
            HStack(spacing: 8) {
                
                // Passport Modal Trigger
                Button {
                    passportTrek = trek
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 11))
                        Text("Passport")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())

                // Status Toggle (Conquer / Wishlist)
                Button {
                    toggleTrekStatus(trek)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isConquered ? "arrow.uturn.backward" : "trophy.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(isConquered ? "Mark Wishlist" : "Conquer 🏆")
                            .font(.system(size: 11.5, weight: .bold))
                    }
                    .foregroundStyle(isConquered ? Color.white : Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(
                        isConquered
                            ? Color.white.opacity(0.12)
                            : Color(red: 0.95, green: 0.75, blue: 0.25),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
            }
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

    private func metricPill(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.4))
            Text(value)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 5))
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

// MARK: - LogTrekModal

struct LogTrekModal: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (TrekRecord) -> Void

    @State private var name: String = ""
    @State private var region: String = "Himalayas"
    @State private var country: String = "India"
    @State private var elevationText: String = ""
    @State private var vertGainText: String = ""
    @State private var status: TrekStatus = .conquered
    @State private var difficulty: TrekDifficulty = .moderate
    @State private var notes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            
            // Header
            HStack {
                Text("Log Mountain Peak")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.15)

            // Form Content
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    
                    // Peak Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PEAK / MOUNTAIN NAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.5))
                        TextField("e.g. Mount Everest, Kalsubai", text: $name)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                    }

                    // Region & Country
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("REGION / RANGE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            TextField("e.g. Himalayas, Sahyadri", text: $region)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("COUNTRY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            TextField("e.g. India, Nepal", text: $country)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // Elevation & Vertical Gain
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ALTITUDE (METERS)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            TextField("e.g. 8848", text: $elevationText)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("VERTICAL GAIN (M)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            TextField("e.g. 1200", text: $vertGainText)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // Status & Difficulty
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Picker("", selection: $status) {
                                ForEach(TrekStatus.allCases, id: \.self) { s in
                                    Text(s.title).tag(s)
                                }
                            }
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("DIFFICULTY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Picker("", selection: $difficulty) {
                                ForEach(TrekDifficulty.allCases, id: \.self) { d in
                                    Text(d.title).tag(d)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EXPEDITION NOTES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.5))
                        TextEditor(text: $notes)
                            .font(.system(size: 12))
                            .frame(height: 60)
                            .padding(4)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(20)
            }

            Divider().opacity(0.15)

            // Bottom Actions
            HStack {
                Spacer()
                Button {
                    let elevation = Double(elevationText) ?? 1000.0
                    let vertGain = Double(vertGainText)
                    let newTrek = TrekRecord(
                        name: name.isEmpty ? "Untitled Peak" : name,
                        region: region.isEmpty ? "Himalayas" : region,
                        country: country.isEmpty ? "India" : country,
                        latitude: 28.0,
                        longitude: 84.0,
                        elevationMeters: elevation,
                        elevationGainMeters: vertGain,
                        status: status,
                        difficulty: difficulty,
                        personalNotes: notes
                    )
                    onSave(newTrek)
                    dismiss()
                } label: {
                    Text("Save Peak")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.95, green: 0.75, blue: 0.25), in: RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 440, height: 460)
        .background(Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)))
    }
}
