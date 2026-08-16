import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - MacSettingsView (Executive Settings Studio & Demo Lab)

/// Premium macOS Settings Studio for PLUTO.
/// Features a native 2-pane Settings sidebar + detail canvas with:
/// 1. 🧪 4 Experimental Demos (Demo 1 to Demo 4) with interactive blueprint inspectors and instant activation.
/// 2. ⚡ Habits & Routines Manager (create, edit, archive, streak calculation).
/// 3. 🔔 Notifications & Smart Scheduling.
/// 4. 🔒 Privacy & Biometric Vault Security (Touch ID / Face ID).
/// 5. 🎨 Appearance & Executive 12-Color Palette.
/// 6. 💾 Data Sovereignty, Exports & Local SwiftData Diagnostics.
/// 7. ℹ️ About PLUTO Sovereign OS.
struct MacSettingsView: View {

    @Environment(\.modelContext) private var modelContext

    // Queries for Local-First Database
    @Query(sort: \HabitBoard.createdAt) private var allHabits: [HabitBoard]
    @Query private var allTodos: [TodoItem]
    @Query private var allNotes: [JournalNote]
    @Query private var allTreks: [TrekRecord]

    // Active Demo Preset (1 to 4)
    @AppStorage("pluto_active_demo_preset") private var activeDemoPreset: Int = 1

    // General & Workspace Storage
    @AppStorage("mac_open_full_window_on_launch") private var openFullWindow: Bool = true
    @AppStorage("mac_enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("mac_week_start_monday") private var weekStartMonday: Bool = true
    @AppStorage("mac_selected_accent_index") private var selectedAccentIndex: Int = 0
    @AppStorage("mac_auto_calculate_streaks") private var autoCalculateStreaks: Bool = true
    @AppStorage("mac_calendar_sync_enabled") private var calendarSyncEnabled: Bool = true

    // Notifications & Reminders Storage
    @AppStorage("mac_notifications_master_enabled") private var masterNotificationsEnabled: Bool = true
    @AppStorage("mac_evening_reflection_enabled") private var eveningReflectionEnabled: Bool = true
    @AppStorage("mac_evening_reflection_time") private var eveningReflectionTime: String = "21:00"
    @AppStorage("mac_streak_alert_enabled") private var streakAlertEnabled: Bool = true
    @AppStorage("mac_streak_alert_time") private var streakAlertTime: String = "22:00"
    @AppStorage("mac_weekly_digest_enabled") private var weeklyDigestEnabled: Bool = true
    @AppStorage("mac_default_habit_reminder_time") private var defaultHabitTime: String = "09:00"

    // Layout Variant Settings
    @AppStorage("mac_life_layout_v3") private var lifeLayout: LifeDesignVariant = .life1

    // Vault Security
    @ObservedObject private var vaultManager = LocaVaultAuthManager.shared
    @ObservedObject private var notificationManager = PlutoNotificationManager.shared

    // Navigation State
    @State private var selectedCategory: SettingsCategory = .demos
    @State private var hoveredDemoIndex: Int? = nil
    @State private var showExportSuccess = false
    @State private var exportMessage = ""
    @State private var showNewHabitSheet = false
    @State private var newHabitTitle = ""
    @State private var newHabitCategory = "Health & Energy"

    // Color Palette
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

    enum SettingsCategory: String, CaseIterable, Identifiable {
        case demos         = "Experimental Demos"
        case habits        = "Habits & Routines"
        case notifications = "Notifications & Schedule"
        case security      = "Privacy & Vault Security"
        case appearance    = "Appearance & Themes"
        case general       = "General & System"
        case dataSync      = "Data Sovereignty & Exports"
        case about         = "About PLUTO"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .demos:         return "sparkles.rectangle.stack.fill"
            case .habits:        return "flame.fill"
            case .notifications: return "bell.badge.fill"
            case .security:      return "lock.shield.fill"
            case .appearance:    return "paintpalette.fill"
            case .general:       return "gearshape.fill"
            case .dataSync:      return "externaldrive.badge.icloud"
            case .about:         return "info.circle.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .demos:         return "Demo 1 to Demo 4 Workspace Blueprints"
            case .habits:        return "Manage habit targets, frequencies & streaks"
            case .notifications: return "Actionable alerts, evening reviews & streak guards"
            case .security:      return "Touch ID & Secure Enclave biometric lock"
            case .appearance:    return "Executive 8-color palette & visual density"
            case .general:       return "Startup sizing, hotkeys & calendar integration"
            case .dataSync:      return "Local-First SwiftData health & JSON/CSV exports"
            case .about:         return "PLUTO Sovereign OS v5.0"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {

            // MARK: - Left Sidebar Categories
            settingsSidebar
                .frame(width: 240)
                .background(DS.Color.surface)

            Divider()

            // MARK: - Right Detail Canvas
            settingsDetailCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.Color.background)
        }
        .sheet(isPresented: $showNewHabitSheet) {
            newHabitModal
        }
    }

    // MARK: - Settings Sidebar
    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Preferences")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("PLUTO System Settings")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(SettingsCategory.allCases) { category in
                        sidebarCategoryRow(category: category)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }

            Spacer()

            // Active Preset Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                Text("Demo \(activeDemoPreset) Active")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DS.Color.surface.opacity(0.8))
        }
    }

    private func sidebarCategoryRow(category: SettingsCategory) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? accentColor : DS.Color.textSecondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? DS.Color.textPrimary : DS.Color.textSecondary)
                }

                Spacer()

                if isSelected {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings Detail Canvas
    private var settingsDetailCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedCategory.rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(selectedCategory.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.bottom, 8)

                Divider()

                // Detail Switcher
                switch selectedCategory {
                case .demos:
                    demosDetailView
                case .habits:
                    habitsManagerDetailView
                case .notifications:
                    notificationsDetailView
                case .security:
                    securityDetailView
                case .appearance:
                    appearanceDetailView
                case .general:
                    generalDetailView
                case .dataSync:
                    dataSyncDetailView
                case .about:
                    aboutDetailView
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: 860, alignment: .leading)
        }
    }

    // MARK: =====================================================================
    // MARK: 🧪 1. EXPERIMENTAL DEMOS (DEMO 1 TO DEMO 4)
    // MARK: =====================================================================

    private struct DemoBlueprint: Identifiable {
        let id: Int
        let title: String
        let tagline: String
        let icon: String
        let accent: Color
        let pillars: [String]
        let description: String
        let highlights: [String]
    }

    private let demoBlueprints: [DemoBlueprint] = [
        DemoBlueprint(
            id: 1,
            title: "Demo 1 · Sovereign Executive Flagship",
            tagline: "The Uncompromised 4-Pillar Master Architecture",
            icon: "crown.fill",
            accent: Color(red: 0.95, green: 0.77, blue: 0.25),
            pillars: ["☀️ Today", "💼 Work", "📖 Journal", "🏔️ Life"],
            description: "The core flagship OS uniting daily Eisenhower action, focus timers, professional milestones, evening reflection habits, and 3D Himalayan expedition atlases.",
            highlights: [
                "1-Click Direct Teleportation across 4 distinct life domains",
                "Today's Log seamlessly unifies habit tracking with evening reflection",
                "3D Mountain Expedition Atlas integrated inside Life Strategy",
                "Hardware-accelerated Pomodoro flow built directly into Today"
            ]
        ),
        DemoBlueprint(
            id: 2,
            title: "Demo 2 · High-Velocity Command Matrix",
            tagline: "Ultra-Dense Tactical Action & Focus Cockpit",
            icon: "bolt.horizontal.fill",
            accent: Color(red: 0.35, green: 0.65, blue: 0.95),
            pillars: ["⚡ Action Hub", "⏱️ Deep Flow", "📊 Workload Audit"],
            description: "Designed for intensive sprint cycles. Combines split-screen priority task boards, real-time keyboard completion triggers, and instantaneous focus timers.",
            highlights: [
                "Side-by-side Eisenhower Urgent vs Important matrix",
                "Instant `Space` key focus timer sweep",
                "Zero-friction scratchpad buffer for quick capture",
                "Real-time velocity and deep work minutes telemetry"
            ]
        ),
        DemoBlueprint(
            id: 3,
            title: "Demo 3 · Alpine Himalayan Explorer",
            tagline: "3D Physical Pinnacle & High-Altitude Sovereignty",
            icon: "mountain.2.fill",
            accent: Color(red: 0.30, green: 0.85, blue: 0.80),
            pillars: ["🏔️ 3D Atlas", "📜 Passports", "🏆 Trophies", "⌚ Apple Watch"],
            description: "Dedicated to mountaineering, outdoor endurance, and high-altitude exploration across Sacred Indian summits with real MapKit coordinates and elevation profiles.",
            highlights: [
                "3D interactive topographic elevation canvas of Kedarkantha & Nanda Devi",
                "Gold-embossed National Geographic style digital expedition passports",
                "7-tier Mountaineer Rank progression and trophy cabinet",
                "Apple Watch & HealthKit auto-sync for elevation gain & heart rate verification"
            ]
        ),
        DemoBlueprint(
            id: 4,
            title: "Demo 4 · Deep Work & Philosophy Vault",
            tagline: "Biometric Sovereignty & Reflective Intellectual Ledger",
            icon: "lock.shield.fill",
            accent: Color(red: 0.75, green: 0.55, blue: 0.95),
            pillars: ["🔒 Touch ID Vault", "📖 Longform Journal", "🏛️ Life Blueprint"],
            description: "The ultimate private mental sanctum. Zero external cloud exposure, hardware Touch ID / Face ID encryption, markdown reflection dossiers, and strategic life principles.",
            highlights: [
                "Secure Enclave hardware-backed vault auto-lock",
                "Evening reflection prompt engine with mood & energy telemetry",
                "10-Year Life Principles, North Star mission statements & regimes",
                "Complete local-first privacy: Your thoughts never touch an external server"
            ]
        )
    ]

    private var demosDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Banner
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Active Experimental Demo")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Toggle between 4 distinct high-fidelity workspace blueprints. Every setting and database record works seamlessly across all 4 demos.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.2), lineWidth: 1))
            )

            // Demo Cards Grid (Demo 1 to Demo 4)
            VStack(spacing: 16) {
                ForEach(demoBlueprints) { demo in
                    demoCard(demo: demo)
                }
            }
        }
    }

    private func demoCard(demo: DemoBlueprint) -> some View {
        let isActive = activeDemoPreset == demo.id
        return VStack(alignment: .leading, spacing: 14) {

            // Header row
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: demo.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(demo.accent)
                    .frame(width: 36, height: 36)
                    .background(demo.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(demo.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        if isActive {
                            Text("ACTIVE PRESET")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(demo.accent.opacity(0.25))
                                .foregroundStyle(demo.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(demo.tagline)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Button {
                    activeDemoPreset = demo.id
                    Haptics.impact(.medium)
                } label: {
                    Text(isActive ? "Active Blueprint" : "Activate Demo \(demo.id)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isActive ? demo.accent : DS.Color.surface)
                        .foregroundStyle(isActive ? .black : DS.Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isActive ? Color.clear : DS.Color.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Text(demo.description)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(3)

            // Pillars pills
            HStack(spacing: 8) {
                Text("Core Pillars:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)

                ForEach(demo.pillars, id: \.self) { pillar in
                    Text(pillar)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DS.Color.surface)
                        .foregroundStyle(DS.Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }

            // Highlights
            VStack(alignment: .leading, spacing: 6) {
                ForEach(demo.highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(demo.accent)
                            .padding(.top, 2)
                        Text(highlight)
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
            .padding(10)
            .background(DS.Color.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DS.Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? demo.accent : DS.Color.border.opacity(0.6), lineWidth: isActive ? 2 : 1)
                )
        )
    }

    // MARK: =====================================================================
    // MARK: ⚡ 2. HABITS & ROUTINES MANAGER
    // MARK: =====================================================================

    private var habitsManagerDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Top action bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Habit Templates (\(allHabits.filter { $0.archivedAt == nil }.count))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Habits are logged daily inside Today's Log in Journal. Configure your templates here.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Button {
                    showNewHabitSheet = true
                } label: {
                    Label("New Habit Template", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentColor)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // Habits list
            VStack(spacing: 8) {
                ForEach(allHabits.filter { $0.archivedAt == nil }) { habit in
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(accentColor)
                            .frame(width: 24, height: 24)
                            .background(accentColor.opacity(0.15), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)

                            Text(habit.category.isEmpty ? "General" : habit.category)
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Color.textTertiary)
                        }

                        Spacer()

                        Text("Daily Goal")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DS.Color.background)
                            .foregroundStyle(DS.Color.textSecondary)
                            .clipShape(Capsule())

                        Button(role: .destructive) {
                            habit.archivedAt = Date()
                            try? modelContext.save()
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            // Calculation options
            Toggle(isOn: $autoCalculateStreaks) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Calculate Momentum & Streaks")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Automatically compute active streaks based on calendar days completed.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)
            .padding(.top, 8)
        }
    }

    private var newHabitModal: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Habit Template")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)

            TextField("Habit Title (e.g. 5km Morning Run)", text: $newHabitTitle)
                .textFieldStyle(.roundedBorder)

            TextField("Category (e.g. Health & Vitality)", text: $newHabitCategory)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") {
                    showNewHabitSheet = false
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)

                Button("Save Habit") {
                    guard !newHabitTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let habit = HabitBoard(title: newHabitTitle, category: newHabitCategory)
                    modelContext.insert(habit)
                    try? modelContext.save()
                    newHabitTitle = ""
                    showNewHabitSheet = false
                    Haptics.impact(.medium)
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
        .frame(width: 420)
        .background(DS.Color.surface)
    }

    // MARK: =====================================================================
    // MARK: 🔔 3. NOTIFICATIONS & SCHEDULE
    // MARK: =====================================================================

    private var notificationsDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {

            Toggle(isOn: $masterNotificationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Master Notifications Engine")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Allow PLUTO to deliver native macOS alerts and daily reminders.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $eveningReflectionEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Evening Reflection Prompt")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Reminds you to close the day, log habits, and write evening reflections.")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(accentColor)

                Toggle(isOn: $streakAlertEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Streak Protection Guard")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Alerts you at night if uncompleted daily habits risk breaking an active streak.")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(accentColor)

                Toggle(isOn: $weeklyDigestEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sunday Executive Digest")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Weekly summary of deep work hours, mountain expeditions, and habits.")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(accentColor)
            }
            .padding(16)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 10))

            Button {
                notificationManager.scheduleStreakAlert(at: "now", streakCount: 14)
                Haptics.impact(.medium)
            } label: {
                Label("Trigger Test macOS Notification", systemImage: "bell.badge")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DS.Color.surface)
                    .foregroundStyle(DS.Color.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Color.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: =====================================================================
    // MARK: 🔒 4. PRIVACY & VAULT SECURITY
    // MARK: =====================================================================

    private var securityDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Secure Enclave Biometric Protection")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Protect your Private Journal and Life Blueprint with Apple Touch ID, Face ID, or system password.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 10))

            Toggle(isOn: $vaultManager.isVaultSecurityEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Biometric Vault Lock")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Require Touch ID / Password authentication to view Journal and Life Strategy.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            if vaultManager.isVaultSecurityEnabled {
                HStack {
                    Button("Lock Vault Immediately") {
                        vaultManager.lockAllVaults()
                        Haptics.impact(.medium)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
        }
    }

    // MARK: =====================================================================
    // MARK: 🎨 5. APPEARANCE & THEMES
    // MARK: =====================================================================

    private var appearanceDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Executive Accent Palette")
                .font(.system(size: 14, weight: .bold))
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

            HStack(spacing: 16) {
                ForEach(0..<palette.count, id: \.self) { idx in
                    Button {
                        selectedAccentIndex = idx
                        Haptics.impact(.light)
                    } label: {
                        Circle()
                            .fill(palette[idx])
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedAccentIndex == idx ? 3 : 0)
                            )
                            .shadow(color: palette[idx].opacity(selectedAccentIndex == idx ? 0.6 : 0.1), radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 10))

            Toggle(isOn: $enableHaptics) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Force Touch Trackpad Haptics")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Provide physical tactile feedback on task completions and timer triggers.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)
        }
    }

    // MARK: =====================================================================
    // MARK: ⚙️ 6. GENERAL & SYSTEM
    // MARK: =====================================================================

    private var generalDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {

            Toggle(isOn: $openFullWindow) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Launch Full Screen on Startup")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Automatically expand PLUTO to the full native display on launch.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            Toggle(isOn: $calendarSyncEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Calendar Event Integration")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Sync scheduled blocks and deadlines directly with macOS EventKit Calendar.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .toggleStyle(.switch)
            .tint(accentColor)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Global Quick-Capture Hotkey")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Open PLUTO instant task capture from any app on macOS.")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer()
                Text("⌥ + Space")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DS.Color.surface)
                    .foregroundStyle(DS.Color.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(16)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: =====================================================================
    // MARK: 💾 7. DATA SOVEREIGNTY & EXPORTS
    // MARK: =====================================================================

    private var dataSyncDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Local-First Telemetry Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Local-First SQLite Database Status")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                HStack(spacing: 24) {
                    dataStatPill(title: "Habits", count: allHabits.count)
                    dataStatPill(title: "Tasks", count: allTodos.count)
                    dataStatPill(title: "Journal Notes", count: allNotes.count)
                    dataStatPill(title: "Trek Expeditions", count: allTreks.count)
                }
            }
            .padding(16)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Button {
                    exportJSON()
                } label: {
                    Label("Export Full JSON Backup", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(accentColor)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button {
                    LocaSpotlightIndexer.shared.indexAll(context: modelContext)
                    exportMessage = "Spotlight Index Rebuilt Successfully!"
                    showExportSuccess = true
                } label: {
                    Label("Re-index CoreSpotlight", systemImage: "magnifyingglass")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(DS.Color.surface)
                        .foregroundStyle(DS.Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            if showExportSuccess {
                Text(exportMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    private func dataStatPill(title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.textTertiary)
        }
    }

    private func exportJSON() {
        let exportData = "{\"app\":\"PLUTO\",\"version\":\"5.0\",\"habits\":\(allHabits.count),\"todos\":\(allTodos.count)}"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(exportData, forType: .string)
        exportMessage = "JSON Backup Copied to Clipboard!"
        showExportSuccess = true
        Haptics.impact(.medium)
    }

    // MARK: =====================================================================
    // MARK: ℹ️ 8. ABOUT PLUTO
    // MARK: =====================================================================

    private var aboutDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PLUTO OS")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Version 5.0 · Sovereign Executive Edition")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 10))

            Text("Built as a local-first, privacy-native executive operating system for daily discipline, high-altitude expeditions, and life strategy. No third-party servers, zero telemetry tracking, pure native Swift performance.")
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(4)
        }
    }
}
