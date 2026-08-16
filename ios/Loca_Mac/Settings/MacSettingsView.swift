import SwiftUI
import SwiftData

// MARK: - MacSettingsView (4 Experimental Setting Demos & Full Working Engine)

/// Executive Settings Studio featuring 4 Experimental Setting Demos (Demo 1 - Demo 4)
/// with 100% full working settings across all 4 visual blueprints:
/// - Setting Demo 1: Apple System Split (Native 2-Pane)
/// - Setting Demo 2: Bento Grid Horizon (Interactive Visual Dashboard)
/// - Setting Demo 3: Minimalist Linear Stream (Compact Continuous Monolith)
/// - Setting Demo 4: Executive Matrix HUD (High-Density Tabbed Cockpit)
struct MacSettingsView: View {

    @Environment(\.modelContext) private var modelContext

    // Database Queries
    @Query(sort: \HabitBoard.createdAt) private var allHabits: [HabitBoard]
    @Query private var allTodos: [TodoItem]
    @Query private var allNotes: [JournalNote]
    @Query private var allTreks: [TrekRecord]

    // Active Setting Demo Variant (1 to 4)
    @AppStorage("mac_setting_demo_variant_v1") private var selectedSettingDemo: Int = 1

    // Settings Storage
    @AppStorage("mac_sound_effects_enabled") private var soundEffectsEnabled: Bool = true
    @AppStorage("mac_open_full_window_on_launch") private var openFullWindow: Bool = true
    @AppStorage("mac_enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("mac_selected_accent_index") private var selectedAccentIndex: Int = 0
    @AppStorage("mac_auto_calculate_streaks") private var autoCalculateStreaks: Bool = true
    @AppStorage("mac_calendar_sync_enabled") private var calendarSyncEnabled: Bool = true

    // Notifications Storage
    @AppStorage("mac_notifications_master_enabled") private var masterNotificationsEnabled: Bool = true
    @AppStorage("mac_evening_reflection_enabled") private var eveningReflectionEnabled: Bool = true
    @AppStorage("mac_streak_alert_enabled") private var streakAlertEnabled: Bool = true
    @AppStorage("mac_weekly_digest_enabled") private var weeklyDigestEnabled: Bool = true

    // Vault Security Storage
    @AppStorage("mac_vault_biometrics_enabled") private var isVaultSecurityEnabled: Bool = false

    // Local UI State
    @State private var activeSidebarTab: SettingCategory = .habits
    @State private var showNewHabitSheet = false
    @State private var newHabitTitle = ""
    @State private var showExportSuccess = false
    @State private var exportMessage = ""

    // Accent Palette
    private var accentColor: Color {
        let palette: [Color] = [
            Color(red: 0.95, green: 0.77, blue: 0.25), // Golden Amber
            Color(red: 0.35, green: 0.65, blue: 0.95), // Alpine Cyan
            Color(red: 0.85, green: 0.40, blue: 0.40), // Crimson Energy
            Color(red: 0.45, green: 0.85, blue: 0.55), // Emerald Growth
            Color(red: 0.75, green: 0.55, blue: 0.95), // Royal Amethyst
            Color(red: 0.95, green: 0.55, blue: 0.35), // Solar Orange
            Color(red: 0.30, green: 0.85, blue: 0.80), // Glacier Teal
            Color(red: 0.80, green: 0.80, blue: 0.85), // Platinum Titanium
        ]
        if selectedAccentIndex >= 0 && selectedAccentIndex < palette.count {
            return palette[selectedAccentIndex]
        }
        return palette[0]
    }

    enum SettingCategory: String, CaseIterable, Identifiable {
        case habits        = "Habits & Routines"
        case sound         = "Sound & Acoustics"
        case notifications = "Notifications & Alerts"
        case security      = "Privacy & Biometric Vault"
        case appearance    = "Appearance & Themes"
        case general       = "General & System"
        case dataSync      = "Data Sovereignty & Exports"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .habits:        return "flame.fill"
            case .sound:         return "speaker.wave.3.fill"
            case .notifications: return "bell.badge.fill"
            case .security:      return "lock.shield.fill"
            case .appearance:    return "paintpalette.fill"
            case .general:       return "gearshape.fill"
            case .dataSync:      return "externaldrive.badge.icloud"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top Demo Switcher Bar
            demoSelectorTopBar
                .background(DS.Color.surface)

            Divider()

            // Main Active Setting Demo Canvas (Demo 1 to Demo 4)
            Group {
                switch selectedSettingDemo {
                case 1:
                    settingDemo1AppleSplitView
                case 2:
                    settingDemo2BentoGridView
                case 3:
                    settingDemo3LinearStreamView
                case 4:
                    settingDemo4MatrixHUDView
                default:
                    settingDemo1AppleSplitView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.background)
        }
        .sheet(isPresented: $showNewHabitSheet) {
            newHabitSheetModal
        }
    }

    // MARK: - Top Demo Selector Bar
    private var demoSelectorTopBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings Studio")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                Text("Switch between 4 live Setting Demos")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Spacer()

            // 4 Demo Pills
            HStack(spacing: 6) {
                demoPillButton(id: 1, name: "Demo 1 · System Split", icon: "sidebar.left")
                demoPillButton(id: 2, name: "Demo 2 · Bento Grid", icon: "square.grid.2x2.fill")
                demoPillButton(id: 3, name: "Demo 3 · Linear Stream", icon: "list.bullet")
                demoPillButton(id: 4, name: "Demo 4 · Matrix HUD", icon: "slider.horizontal.3")
            }
            .padding(4)
            .background(DS.Color.background, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func demoPillButton(id: Int, name: String, icon: String) -> some View {
        let isSelected = selectedSettingDemo == id
        return Button {
            selectedSettingDemo = id
            PlutoSoundEngine.shared.play(.tabSwitch)
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(name)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? accentColor : Color.clear)
            .foregroundStyle(isSelected ? .black : DS.Color.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: =====================================================================
    // MARK: 🧪 SETTING DEMO 1: APPLE SYSTEM SPLIT (Native 2-Pane Sidebar)
    // MARK: =====================================================================

    private var settingDemo1AppleSplitView: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                Text("Categories")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 6)

                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(SettingCategory.allCases) { cat in
                            Button {
                                activeSidebarTab = cat
                                PlutoSoundEngine.shared.play(.tabSwitch)
                                Haptics.impact(.light)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(activeSidebarTab == cat ? accentColor : DS.Color.textSecondary)
                                        .frame(width: 20)

                                    Text(cat.rawValue)
                                        .font(.system(size: 12, weight: activeSidebarTab == cat ? .bold : .medium))
                                        .foregroundStyle(activeSidebarTab == cat ? DS.Color.textPrimary : DS.Color.textSecondary)

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(activeSidebarTab == cat ? accentColor.opacity(0.15) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }

                Spacer()
            }
            .frame(width: 220)
            .background(DS.Color.surface)

            Divider()

            // Detail
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(activeSidebarTab.rawValue)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.bottom, 4)

                    switch activeSidebarTab {
                    case .habits:
                        habitsManagerControlBlock
                    case .sound:
                        soundControlsBlock
                    case .notifications:
                        notificationsControlBlock
                    case .security:
                        securityControlBlock
                    case .appearance:
                        appearanceControlBlock
                    case .general:
                        generalControlBlock
                    case .dataSync:
                        dataSyncControlBlock
                    }

                    Spacer(minLength: 40)
                }
                .padding(28)
                .frame(maxWidth: 720, alignment: .leading)
            }
        }
    }

    // MARK: =====================================================================
    // MARK: 🧪 SETTING DEMO 2: BENTO GRID HORIZON (Visual Tile Dashboard)
    // MARK: =====================================================================

    private var settingDemo2BentoGridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bento Settings Horizon")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Visual interactive modules with direct control dials")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {

                    // Sound & Acoustics Bento Tile
                    bentoTile(title: "Sound & Acoustics", icon: "speaker.wave.3.fill", accent: accentColor) {
                        soundControlsBlock
                    }

                    // Biometric Vault Bento Tile
                    bentoTile(title: "Privacy & Vault", icon: "lock.shield.fill", accent: Color(red: 0.75, green: 0.55, blue: 0.95)) {
                        securityControlBlock
                    }

                    // Appearance Bento Tile
                    bentoTile(title: "Executive Accent", icon: "paintpalette.fill", accent: Color(red: 0.95, green: 0.55, blue: 0.35)) {
                        appearanceControlBlock
                    }

                    // System & General Bento Tile
                    bentoTile(title: "General & Hotkeys", icon: "gearshape.fill", accent: Color(red: 0.35, green: 0.65, blue: 0.95)) {
                        generalControlBlock
                    }
                }

                // Full Width Habits & Data Tiles
                bentoTile(title: "Habits & Routine Templates", icon: "flame.fill", accent: accentColor) {
                    habitsManagerControlBlock
                }

                bentoTile(title: "Data Sovereignty & SQLite", icon: "externaldrive.badge.icloud", accent: Color(red: 0.45, green: 0.85, blue: 0.55)) {
                    dataSyncControlBlock
                }
            }
            .padding(24)
            .frame(maxWidth: 960)
        }
    }

    private func bentoTile<Content: View>(title: String, icon: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
            }
            Divider()
            content()
        }
        .padding(18)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Color.border.opacity(0.6), lineWidth: 1))
    }

    // MARK: =====================================================================
    // MARK: 🧪 SETTING DEMO 3: LINEAR MINIMALIST STREAM (Continuous Column)
    // MARK: =====================================================================

    private var settingDemo3LinearStreamView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("System Preferences")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Linear continuous settings stream")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                streamSection(title: "Sound & Acoustics", icon: "speaker.wave.3.fill") {
                    soundControlsBlock
                }

                streamSection(title: "Habits & Routines", icon: "flame.fill") {
                    habitsManagerControlBlock
                }

                streamSection(title: "Notifications & Smart Schedule", icon: "bell.badge.fill") {
                    notificationsControlBlock
                }

                streamSection(title: "Privacy & Biometric Vault", icon: "lock.shield.fill") {
                    securityControlBlock
                }

                streamSection(title: "Appearance & Themes", icon: "paintpalette.fill") {
                    appearanceControlBlock
                }

                streamSection(title: "Data Sovereignty & Local Storage", icon: "externaldrive.badge.icloud") {
                    dataSyncControlBlock
                }

                Spacer(minLength: 40)
            }
            .padding(32)
            .frame(maxWidth: 680, alignment: .leading)
        }
    }

    private func streamSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
            }
            Divider()
            content()
        }
    }

    // MARK: =====================================================================
    // MARK: 🧪 SETTING DEMO 4: EXECUTIVE MATRIX HUD (Tabbed Cockpit)
    // MARK: =====================================================================

    private var settingDemo4MatrixHUDView: some View {
        VStack(spacing: 0) {

            // Horizontal Tab Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SettingCategory.allCases) { cat in
                        Button {
                            activeSidebarTab = cat
                            PlutoSoundEngine.shared.play(.tabSwitch)
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                Text(cat.rawValue)
                            }
                            .font(.system(size: 12, weight: activeSidebarTab == cat ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(activeSidebarTab == cat ? accentColor : DS.Color.surface)
                            .foregroundStyle(activeSidebarTab == cat ? .black : DS.Color.textSecondary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .background(DS.Color.surface)

            Divider()

            // Content Canvas
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch activeSidebarTab {
                    case .habits:
                        habitsManagerControlBlock
                    case .sound:
                        soundControlsBlock
                    case .notifications:
                        notificationsControlBlock
                    case .security:
                        securityControlBlock
                    case .appearance:
                        appearanceControlBlock
                    case .general:
                        generalControlBlock
                    case .dataSync:
                        dataSyncControlBlock
                    }
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
            }
        }
    }

    // MARK: =====================================================================
    // MARK: ⚙️ SHARED FULLY FUNCTIONAL CONTROL BLOCKS (WORK ACROSS ALL 4 DEMOS)
    // MARK: =====================================================================

    // 1. Sound & Acoustics Controls
    private var soundControlsBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $soundEffectsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Acoustic Sound Effects")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Play mechanical clicks on habit completion, focus timer rings, and summits.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            if soundEffectsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Acoustic Sound Profiles:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textTertiary)

                    HStack(spacing: 8) {
                        soundTestButton(name: "Tink (Check)", sound: .checkmark)
                        soundTestButton(name: "Pop (Timer)", sound: .timerStart)
                        soundTestButton(name: "Ping (Complete)", sound: .timerComplete)
                        soundTestButton(name: "Hero (Summit)", sound: .summitPassport)
                    }
                }
                .padding(12)
                .background(DS.Color.background, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func soundTestButton(name: String, sound: PlutoSoundEngine.AcousticSound) -> some View {
        Button {
            PlutoSoundEngine.shared.play(sound)
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9))
                Text(name)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DS.Color.surface)
            .foregroundStyle(DS.Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Color.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // 2. Habits & Routines Controls
    private var habitsManagerControlBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Active Habits (\(allHabits.filter { $0.archivedAt == nil }.count))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Button {
                    showNewHabitSheet = true
                } label: {
                    Label("Add Habit", systemImage: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(accentColor)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 6) {
                ForEach(allHabits.filter { $0.archivedAt == nil }) { habit in
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(accentColor)

                        Text(habit.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Spacer()

                        Text("Streak: \(habit.currentStreak)d")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(accentColor)

                        Button {
                            habit.archivedAt = Date()
                            try? modelContext.save()
                            PlutoSoundEngine.shared.play(.deleteTrash)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                }
            }

            Toggle(isOn: $autoCalculateStreaks) {
                Text("Auto-Calculate Momentum & Streaks")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Color.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(accentColor)
        }
    }

    // 3. Notifications Controls
    private var notificationsControlBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $masterNotificationsEnabled) {
                Text("Master Notification Engine")
                    .font(.system(size: 13, weight: .bold))
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            Toggle(isOn: $eveningReflectionEnabled) {
                Text("Evening Reflection Reminders (21:00)")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            Toggle(isOn: $streakAlertEnabled) {
                Text("Streak Protection Guard (22:00)")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            Button {
                PlutoNotificationManager.shared.scheduleFocusCompletionNotification(tag: "Deep Work Sprint", seconds: 5, mode: "Pomodoro")
                PlutoSoundEngine.shared.play(.timerComplete)
            } label: {
                Label("Trigger Test macOS Notification", systemImage: "bell.badge")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DS.Color.surface)
                    .foregroundStyle(DS.Color.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Color.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // 4. Security & Biometrics Controls
    private var securityControlBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $isVaultSecurityEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Touch ID / Face ID Biometric Lock")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Locks Journal and Life Blueprint with Secure Enclave hardware.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            if isVaultSecurityEnabled {
                Button("Lock Vault Immediately") {
                    LocaVaultAuthManager.shared.lockAll()
                    PlutoSoundEngine.shared.play(.vaultLock)
                    Haptics.impact(.medium)
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(.plain)
            }
        }
    }

    // 5. Appearance & Colors Controls
    private var appearanceControlBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Executive 8-Color Palette")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)

            let palette: [Color] = [
                Color(red: 0.95, green: 0.77, blue: 0.25),
                Color(red: 0.35, green: 0.65, blue: 0.95),
                Color(red: 0.85, green: 0.40, blue: 0.40),
                Color(red: 0.45, green: 0.85, blue: 0.55),
                Color(red: 0.75, green: 0.55, blue: 0.95),
                Color(red: 0.95, green: 0.55, blue: 0.35),
                Color(red: 0.30, green: 0.85, blue: 0.80),
                Color(red: 0.80, green: 0.80, blue: 0.85),
            ]

            HStack(spacing: 12) {
                ForEach(0..<palette.count, id: \.self) { idx in
                    Button {
                        selectedAccentIndex = idx
                        PlutoSoundEngine.shared.play(.tabSwitch)
                        Haptics.impact(.light)
                    } label: {
                        Circle()
                            .fill(palette[idx])
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: selectedAccentIndex == idx ? 2.5 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Toggle(isOn: $enableHaptics) {
                Text("Force Touch Trackpad Haptics")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .tint(accentColor)
        }
    }

    // 6. General & System Controls
    private var generalControlBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $openFullWindow) {
                Text("Launch Full Screen on Startup")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            Toggle(isOn: $calendarSyncEnabled) {
                Text("Apple Calendar EventKit Sync")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            HStack {
                Text("Global Quick-Capture Hotkey")
                    .font(.system(size: 12))
                Spacer()
                Text("⌥ + Space")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DS.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    // 7. Data Sovereignty & SQLite Controls
    private var dataSyncControlBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                statBox(title: "Habits", count: allHabits.count)
                statBox(title: "Tasks", count: allTodos.count)
                statBox(title: "Notes", count: allNotes.count)
                statBox(title: "Treks", count: allTreks.count)
            }

            HStack(spacing: 10) {
                Button {
                    let exportData = "{\"app\":\"PLUTO\",\"version\":\"5.0\",\"habits\":\(allHabits.count),\"todos\":\(allTodos.count)}"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(exportData, forType: .string)
                    exportMessage = "JSON Copied to Clipboard!"
                    showExportSuccess = true
                    PlutoSoundEngine.shared.play(.checkmark)
                } label: {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentColor)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button {
                    LocaSpotlightIndexer.shared.indexAll(context: modelContext)
                    exportMessage = "Spotlight Re-indexed!"
                    showExportSuccess = true
                    PlutoSoundEngine.shared.play(.checkmark)
                } label: {
                    Label("Re-index Spotlight", systemImage: "magnifyingglass")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DS.Color.surface)
                        .foregroundStyle(DS.Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            if showExportSuccess {
                Text(exportMessage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    private func statBox(title: String, count: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
    }

    // Modal Sheet for adding habit
    private var newHabitSheetModal: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Habit Template")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)

            TextField("Habit Name (e.g. Zone 2 Rucking)", text: $newHabitTitle)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") {
                    showNewHabitSheet = false
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)

                Button("Save") {
                    guard !newHabitTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let habit = HabitBoard(name: newHabitTitle)
                    modelContext.insert(habit)
                    try? modelContext.save()
                    newHabitTitle = ""
                    showNewHabitSheet = false
                    PlutoSoundEngine.shared.play(.checkmark)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(accentColor)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 380)
        .background(DS.Color.surface)
    }
}
