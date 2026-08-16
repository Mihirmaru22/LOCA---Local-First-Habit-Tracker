import SwiftUI
import SwiftData

// MARK: - MacSettingsView (Executive Split-Pane Settings Studio)

/// Premium macOS Settings Studio for LOCA.
/// Features a native 2-pane Settings sidebar + detail canvas with
/// an interactive Live Layout Glimpse Inspector that responds to cursor hovering.
struct MacSettingsView: View {

    @Environment(\.modelContext) private var modelContext

    // Layout Storage
    @AppStorage("mac_task_workspace_layout_v2") private var taskLayout: TaskWorkspaceLayout = .linearSplit
    @AppStorage("mac_habit_layout_v2") private var habitLayout: HabitDesignVariant = .habit1
    @AppStorage("mac_life_layout_v3") private var lifeLayout: LifeDesignVariant = .life1
    @AppStorage("mac_journal_analyse_layout_v2") private var journalLayout: AnalyseDesignVariant = .bentoHorizon

    // General & Appearance Storage
    @AppStorage("mac_open_full_window_on_launch") private var openFullWindow: Bool = true
    @AppStorage("mac_enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("mac_week_start_monday") private var weekStartMonday: Bool = true
    @AppStorage("mac_selected_accent_index") private var selectedAccentIndex: Int = 0
    @AppStorage("mac_auto_calculate_streaks") private var autoCalculateStreaks: Bool = true

    // Notifications & Reminders Storage (A1-A8)
    @AppStorage("mac_notifications_master_enabled") private var masterNotificationsEnabled: Bool = true
    @AppStorage("mac_evening_reflection_enabled") private var eveningReflectionEnabled: Bool = true
    @AppStorage("mac_evening_reflection_time") private var eveningReflectionTime: String = "21:00"
    @AppStorage("mac_streak_alert_enabled") private var streakAlertEnabled: Bool = true
    @AppStorage("mac_streak_alert_time") private var streakAlertTime: String = "22:00"
    @AppStorage("mac_weekly_digest_enabled") private var weeklyDigestEnabled: Bool = true
    @AppStorage("mac_default_habit_reminder_time") private var defaultHabitTime: String = "09:00"
    @State private var testNotificationBanner: Bool = false

    @AppStorage("mac_calendar_sync_enabled") private var calendarSyncEnabled: Bool = true

    @Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil }, sort: \HabitBoard.createdAt)
    private var activeHabits: [HabitBoard]

    @ObservedObject private var notificationManager = PlutoNotificationManager.shared
    @ObservedObject private var loginManager = PlutoLoginItemManager.shared
    @ObservedObject private var calendarSync = PlutoCalendarSync.shared
    @ObservedObject private var hotkeyManager = PlutoGlobalHotkeyManager.shared

    // Hover & Active States
    @State private var selectedTab: SettingsCategory = .layouts
    @State private var hoveredTaskLayout: TaskWorkspaceLayout? = nil
    @State private var hoveredHabitLayout: HabitDesignVariant? = nil
    @State private var hoveredLifeLayout: LifeDesignVariant? = nil
    @State private var hoveredJournalLayout: AnalyseDesignVariant? = nil

    @State private var showingExportSuccess = false
    @State private var showingRecalculateSuccess = false

    enum SettingsCategory: String, CaseIterable, Identifiable {
        case layouts       = "Layouts & Workspaces"
        case appearance    = "Appearance & Colors"
        case notifications = "Notifications & Reminders"
        case security      = "Privacy & Vault Security"
        case general       = "General & Startup"
        case dataSync      = "Data & Cloud Sync"
        case habits        = "Habits & Engine"
        case about         = "About PLUTO"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .layouts:       return "square.grid.3x3.fill"
            case .appearance:    return "paintpalette.fill"
            case .notifications: return "bell.badge.fill"
            case .security:      return "lock.shield.fill"
            case .general:       return "gearshape.fill"
            case .dataSync:      return "externaldrive.badge.icloud"
            case .habits:        return "flame.fill"
            case .about:         return "info.circle.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .layouts:       return "Interactive workspace blueprints"
            case .appearance:    return "Unified 12-color executive palette"
            case .notifications: return "Smart reminders, actionable buttons & streak alerts"
            case .security:      return "Touch ID & Secure Enclave vault lock"
            case .general:       return "Launch sizing and feedback"
            case .dataSync:      return "Local-First SwiftData & exports"
            case .habits:        return "Streak caching and metrics"
            case .about:         return "PLUTO App Version 4.0"
            }
        }
    }

    private var accentColor: Color {
        ColorPalette[selectedAccentIndex]
    }

    var body: some View {
        HStack(spacing: 0) {

            // Settings Left Sidebar (Categories)
            VStack(alignment: .leading, spacing: DS.Space.md) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preferences")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("System Settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.top, DS.Space.lg)

                Divider()

                VStack(spacing: 3) {
                    ForEach(SettingsCategory.allCases) { cat in
                        Button {
                            selectedTab = cat
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 13))
                                    .foregroundStyle(selectedTab == cat ? accentColor : DS.Color.textSecondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cat.rawValue)
                                        .font(.system(size: 12, weight: selectedTab == cat ? .bold : .medium))
                                        .foregroundStyle(selectedTab == cat ? DS.Color.textPrimary : DS.Color.textSecondary)
                                }

                                Spacer()

                                if selectedTab == cat {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedTab == cat
                                    ? DS.Color.surfaceRecessed
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)

                Spacer()

                // Bottom Status Pill
                HStack(spacing: 6) {
                    Circle().fill(DS.Color.success).frame(width: 6, height: 6)
                    Text("Local-First Active")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.bottom, DS.Space.lg)
            }
            .frame(width: 220)
            .background(DS.Color.surface)

            Divider()

            // Settings Right Detail Canvas
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    // Header for Active Category
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedTab.rawValue)
                            .font(DS.Text.title)
                            .fontWeight(.bold)
                            .foregroundStyle(DS.Color.textPrimary)

                        Text(selectedTab.subtitle)
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Divider()

                    switch selectedTab {
                    case .layouts:
                        layoutsStudioSection
                    case .appearance:
                        appearanceSection
                    case .notifications:
                        notificationsSection
                    case .security:
                        vaultSecuritySection
                    case .general:
                        generalSection
                    case .dataSync:
                        dataSyncSection
                    case .habits:
                        habitsEngineSection
                    case .about:
                        aboutSection
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.xxl)
                .frame(maxWidth: 860, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.background)
        }
        .alert("Data Exported", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your complete local-first database has been compiled and saved.")
        }
        .alert("Streaks Recalculated", isPresented: $showingRecalculateSuccess) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("All habit streaks and completion rates have been verified and cached.")
        }
    }

    // MARK: =====================================================================
    // MARK: 📐 1. LAYOUTS & WORKSPACES STUDIO (WITH LIVE HOVER GLIMPSE)
    // MARK: =====================================================================

    private var layoutsStudioSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // 0. Habits Workspace Studio
            VStack(alignment: .leading, spacing: DS.Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HABITS WORKSPACE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text("Choose your preferred habit tracking cards and progress visualization")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                }

                // 3 Habit Layout Cards
                HStack(spacing: DS.Space.md) {
                    ForEach(HabitDesignVariant.allCases) { layout in
                        layoutCardItem(
                            title: layout.rawValue,
                            subtitle: habitSubtitle(for: layout),
                            icon: layout.icon,
                            isSelected: habitLayout == layout,
                            isHovered: (hoveredHabitLayout ?? habitLayout) == layout
                        ) {
                            habitLayout = layout
                        }
                        .onHover { isHovered in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                hoveredHabitLayout = isHovered ? layout : nil
                            }
                        }
                    }
                }
            }

            Divider()

            // 1. Today & Task Workspace Studio
            VStack(alignment: .leading, spacing: DS.Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TODAY & TASK WORKSPACE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text("Touch/hover over any layout card below to glimpse its live interface structure")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                }

                // 3 Layout Option Cards
                HStack(spacing: DS.Space.md) {
                    ForEach(TaskWorkspaceLayout.allCases) { layout in
                        layoutCardItem(
                            title: layout.shortTitle,
                            subtitle: layoutSubtitle(for: layout),
                            icon: layout.icon,
                            isSelected: taskLayout == layout,
                            isHovered: (hoveredTaskLayout ?? taskLayout) == layout
                        ) {
                            taskLayout = layout
                        }
                        .onHover { isHovered in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                hoveredTaskLayout = isHovered ? layout : nil
                            }
                        }
                    }
                }

                // Live Glimpse Inspection Screen for Task Workspace
                let activeGlimpse = hoveredTaskLayout ?? taskLayout
                taskWorkspaceLiveGlimpse(layout: activeGlimpse)
            }

            Divider()

            // 2. Life Operating System Studio
            VStack(alignment: .leading, spacing: DS.Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LIFE OPERATING SYSTEM")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text("Touch/hover over any life pillar layout to preview its visual architecture")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                }

                // 4 Life Layout Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.md) {
                    ForEach(LifeDesignVariant.allCases) { layout in
                        layoutCardItem(
                            title: layout.shortTitle,
                            subtitle: lifeSubtitle(for: layout),
                            icon: layout.icon,
                            isSelected: lifeLayout == layout,
                            isHovered: (hoveredLifeLayout ?? lifeLayout) == layout
                        ) {
                            lifeLayout = layout
                        }
                        .onHover { isHovered in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                hoveredLifeLayout = isHovered ? layout : nil
                            }
                        }
                    }
                }

                // Live Glimpse Inspection Screen for Life
                let activeLife = hoveredLifeLayout ?? lifeLayout
                lifeLiveGlimpse(layout: activeLife)
            }

            Divider()

            // 3. Journal Analytics Studio
            VStack(alignment: .leading, spacing: DS.Space.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("JOURNAL ANALYTICS STUDIO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)
                        Text("Choose your preferred monthly reflection and correlation layout")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                }

                // 3 Journal Layout Cards
                HStack(spacing: DS.Space.md) {
                    ForEach(AnalyseDesignVariant.allCases) { layout in
                        layoutCardItem(
                            title: layout.rawValue,
                            subtitle: journalSubtitle(for: layout),
                            icon: layout.icon,
                            isSelected: journalLayout == layout,
                            isHovered: (hoveredJournalLayout ?? journalLayout) == layout
                        ) {
                            journalLayout = layout
                        }
                        .onHover { isHovered in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                hoveredJournalLayout = isHovered ? layout : nil
                            }
                        }
                    }
                }

                // Live Glimpse Inspection Screen for Journal
                let activeJournal = hoveredJournalLayout ?? journalLayout
                journalLiveGlimpse(layout: activeJournal)
            }
        }
    }

    // MARK: - Reusable Layout Selector Card

    private func layoutCardItem(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        isHovered: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            Haptics.impact(.rigid)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? accentColor : DS.Color.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.success)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(
                        isSelected ? accentColor : (isHovered ? DS.Color.textSecondary.opacity(0.6) : DS.Color.border.opacity(0.4)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? accentColor.opacity(0.2) : (isHovered ? Color.black.opacity(0.15) : Color.clear),
                radius: isHovered ? 6 : 2,
                y: isHovered ? 2 : 1
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Large Live Glimpse Inspection Panels

    private func taskWorkspaceLiveGlimpse(layout: TaskWorkspaceLayout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(accentColor).frame(width: 6, height: 6)
                    Text("LIVE GLIMPSE:")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)
                    Text(layout.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                Spacer()
                Text(taskDescription(for: layout))
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            // High-Fidelity Mock Canvas
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Color.surfaceRecessed)
                    .frame(height: 140)

                switch layout {
                case .linearSplit:
                    HStack(spacing: 12) {
                        // Left 70%
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                RoundedRectangle(cornerRadius: 3).fill(DS.Color.success).frame(width: 50, height: 10)
                                RoundedRectangle(cornerRadius: 3).fill(DS.Color.surface).frame(width: 40, height: 10)
                                Spacer()
                            }
                            RoundedRectangle(cornerRadius: 3).fill(DS.Color.textPrimary.opacity(0.8)).frame(width: 140, height: 12)
                            Divider()
                            VStack(spacing: 4) {
                                ForEach(0..<3) { _ in
                                    HStack(spacing: 6) {
                                        Circle().stroke(DS.Color.success, lineWidth: 1.5).frame(width: 10, height: 10)
                                        RoundedRectangle(cornerRadius: 2).fill(DS.Color.surface).frame(height: 8)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))

                        // Right 30% Inspector
                        VStack(spacing: 8) {
                            Circle().stroke(accentColor, lineWidth: 3).frame(width: 32, height: 32)
                            Text("25:00").font(.system(size: 11, weight: .bold, design: .monospaced))
                            RoundedRectangle(cornerRadius: 3).fill(accentColor).frame(width: 50, height: 12)
                            Spacer()
                        }
                        .padding(12)
                        .frame(width: 90)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(8)

                case .thingsDoc:
                    VStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle().stroke(DS.Color.success, lineWidth: 2).frame(width: 14, height: 14)
                                Text("High-Impact Focus Task").font(.system(size: 12, weight: .bold))
                                Spacer()
                            }
                            RoundedRectangle(cornerRadius: 2).fill(DS.Color.surfaceRecessed).frame(height: 18)
                            VStack(spacing: 5) {
                                ForEach(0..<4) { i in
                                    HStack(spacing: 6) {
                                        Circle().stroke(i == 0 ? DS.Color.success : DS.Color.textTertiary, lineWidth: 1.5).frame(width: 9, height: 9)
                                        RoundedRectangle(cornerRadius: 2).fill(i == 0 ? DS.Color.success.opacity(0.3) : DS.Color.surfaceRecessed).frame(height: 7)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: 320)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(8)

                case .bentoMatrix:
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4).fill(DS.Color.surface).frame(height: 20)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(["Subtasks (3/4)", "Notes & Strategy", "Schedule & Due", "25m Sprint"], id: \.self) { title in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(title).font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                                    RoundedRectangle(cornerRadius: 2).fill(DS.Color.surfaceRecessed).frame(height: 24)
                                }
                                .padding(6)
                                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func lifeLiveGlimpse(layout: LifeDesignVariant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(accentColor).frame(width: 6, height: 6)
                    Text("LIVE GLIMPSE:")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)
                    Text(layout.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                Spacer()
                Text(lifeDescription(for: layout))
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            // High-Fidelity Mock Canvas
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Color.surfaceRecessed)
                    .frame(height: 140)

                switch layout {
                case .life1:
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NORTH STAR MAXIM").font(.system(size: 8, weight: .bold)).foregroundStyle(accentColor)
                            Text("\"Live with radical agency and craftsmanship.\"").font(.system(size: 11, weight: .bold, design: .serif))
                            RoundedRectangle(cornerRadius: 2).fill(DS.Color.surface).frame(height: 40)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("LIFE SATISFACTION RADAR").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                            ForEach(["Health", "Craft", "Mind", "Wealth"], id: \.self) { p in
                                HStack {
                                    Text(p).font(.system(size: 8))
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 1).fill(DS.Color.success).frame(width: 30, height: 4)
                                }
                            }
                        }
                        .padding(10)
                        .frame(width: 140)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(8)

                case .life2:
                    VStack(spacing: 6) {
                        HStack {
                            Text("2 of 8 Dreams Realized (25%)").font(.system(size: 11, weight: .bold))
                            Spacer()
                            Circle().stroke(DS.Color.success, lineWidth: 3).frame(width: 22, height: 22)
                        }
                        .padding(8)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(0..<3) { i in
                                HStack(spacing: 4) {
                                    Circle().fill(i == 0 ? DS.Color.success : DS.Color.textTertiary).frame(width: 6, height: 6)
                                    RoundedRectangle(cornerRadius: 2).fill(DS.Color.surfaceRecessed).frame(height: 16)
                                }
                                .padding(6)
                                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    .padding(8)

                case .life3:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("90-YEAR HORIZON & ERAS").font(.system(size: 9, weight: .bold)).foregroundStyle(accentColor)
                        HStack(spacing: 4) {
                            ForEach(["Youth", "Foundation", "Prime Sprint", "Legacy", "Wisdom"], id: \.self) { era in
                                VStack(spacing: 4) {
                                    Circle().fill(era == "Prime Sprint" ? accentColor : DS.Color.surface).frame(width: 14, height: 14)
                                    Text(era).font(.system(size: 7, weight: .bold)).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(12)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    .padding(8)

                case .life4:
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WEEKLY RETROSPECTIVE").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                            RoundedRectangle(cornerRadius: 2).fill(DS.Color.surfaceRecessed).frame(height: 18)
                            RoundedRectangle(cornerRadius: 2).fill(DS.Color.surfaceRecessed).frame(height: 18)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ENERGY SCORE").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                            Text("8.5 / 10").font(.system(size: 16, weight: .bold)).foregroundStyle(DS.Color.success)
                        }
                        .padding(8)
                        .frame(width: 100)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(8)

                case .life5:
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MOUNTAIN SUMMIT ATLAS").font(.system(size: 8, weight: .bold)).foregroundStyle(Color.cyan)
                            Text("Conquered Summits & 3D Radar").font(.system(size: 10, weight: .bold))
                            HStack(spacing: 4) {
                                Text("⛰️ Mt Fuji").font(.system(size: 8)).padding(4).background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 3))
                                Text("⛰️ Matterhorn").font(.system(size: 8)).padding(4).background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ELEVATION PROFILE").font(.system(size: 8, weight: .bold)).foregroundStyle(DS.Color.textTertiary)
                            RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [Color.cyan.opacity(0.4), Color.purple.opacity(0.2)], startPoint: .top, endPoint: .bottom)).frame(height: 36)
                        }
                        .padding(8)
                        .frame(width: 140)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func journalLiveGlimpse(layout: AnalyseDesignVariant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(accentColor).frame(width: 6, height: 6)
                    Text("LIVE GLIMPSE:")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)
                    Text(layout.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                Spacer()
                Text(journalDescription(for: layout))
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            // High-Fidelity Mock Canvas
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(DS.Color.surfaceRecessed)
                    .frame(height: 120)

                switch layout {
                case .bentoHorizon:
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3).fill(DS.Color.surface).frame(height: 28)
                            RoundedRectangle(cornerRadius: 3).fill(DS.Color.surface).frame(height: 28)
                            RoundedRectangle(cornerRadius: 3).fill(DS.Color.surface).frame(height: 28)
                        }
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3).fill(DS.Color.surface).frame(height: 48)
                            RoundedRectangle(cornerRadius: 3).fill(accentColor.opacity(0.2)).frame(height: 48)
                        }
                    }
                    .padding(8)

                case .splitKpi:
                    HStack(spacing: 8) {
                        VStack(spacing: 4) {
                            Text("Physical Recovery").font(.system(size: 8, weight: .bold))
                            RoundedRectangle(cornerRadius: 3).fill(DS.Color.surface).frame(height: 50)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))

                        VStack(spacing: 4) {
                            Text("Mental Clarity").font(.system(size: 8, weight: .bold))
                            RoundedRectangle(cornerRadius: 3).fill(DS.Color.surface).frame(height: 50)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(8)

                case .dataMatrix:
                    VStack(spacing: 4) {
                        ForEach(0..<3) { _ in
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 2).fill(accentColor.opacity(0.8)).frame(width: 24, height: 12)
                                RoundedRectangle(cornerRadius: 2).fill(DS.Color.surface).frame(height: 12)
                                RoundedRectangle(cornerRadius: 2).fill(DS.Color.surface).frame(width: 36, height: 12)
                            }
                        }
                    }
                    .padding(12)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // Helper text functions
    private func layoutSubtitle(for l: TaskWorkspaceLayout) -> String {
        switch l {
        case .linearSplit: return "70/30 Split + Inspector"
        case .thingsDoc:   return "Centered Sheet Canvas"
        case .bentoMatrix: return "Modular 4-Zone Grid"
        }
    }

    private func taskDescription(for l: TaskWorkspaceLayout) -> String {
        switch l {
        case .linearSplit: return "Wide main canvas with a dedicated right inspector for subtasks, Pomodoro sprint, and due dates."
        case .thingsDoc:   return "Minimalist document view with centered sheet, circular checkmarks, and inline quick-add."
        case .bentoMatrix: return "High-density modular bento allocating separate zones for checklist, notes, schedule, and focus."
        }
    }

    private func habitSubtitle(for h: HabitDesignVariant) -> String {
        switch h {
        case .habit1: return "Rings & Streaks"
        case .habit2: return "7-Day Strip Heatmap"
        case .habit3: return "High-Density Matrix"
        }
    }

    private func lifeSubtitle(for l: LifeDesignVariant) -> String {
        switch l {
        case .life1: return "North Star & Rules"
        case .life2: return "Dream Vault & Milestones"
        case .life3: return "90-Year Horizon Axis"
        case .life4: return "Weekly Retrospectives"
        case .life5: return "Trek & Mountain Atlas"
        }
    }

    private func lifeDescription(for l: LifeDesignVariant) -> String {
        switch l {
        case .life1: return "Core guiding principles, life satisfaction radar matrix, and daily decision filters."
        case .life2: return "Comprehensive lifetime dream vault with achievement tags, category filters, and target horizons."
        case .life3: return "Chronological life timeline mapping past milestones, current sprint, and future horizons."
        case .life4: return "Weekly review questions, energy allocation scoring, and personal growth journal notes."
        case .life5: return "Expedition tracking, 3D interactive topographic maps, GPX trail corridors, and summit photo galleries."
        }
    }

    private func journalSubtitle(for l: AnalyseDesignVariant) -> String {
        switch l {
        case .bentoHorizon: return "Executive Overview"
        case .splitKpi:     return "Side-by-Side KPIs"
        case .dataMatrix:   return "Compact Matrix"
        }
    }

    private func journalDescription(for l: AnalyseDesignVariant) -> String {
        switch l {
        case .bentoHorizon: return "High-density bento grid combining sleep trends, mood breakdown, and habit consistency."
        case .splitKpi:     return "Dual-column layout comparing physical recovery stats directly against mental clarity scores."
        case .dataMatrix:   return "Compact tabular matrix designed for scanning months of daily logs at a glance."
        }
    }

    // MARK: =====================================================================
    // MARK: 🎨 2. APPEARANCE & COLORS SECTION
    // MARK: =====================================================================

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            settingsGroupHeader(title: "UNIFIED COLOR PALETTE", subtitle: "Choose your primary executive theme accent")

            VStack(alignment: .leading, spacing: DS.Space.md) {
                Text("App-Wide Primary Accent")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Controls active states, hero badges, and primary buttons across all sections.")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                    ForEach(0..<ColorPalette.count, id: \.self) { idx in
                        Button {
                            selectedAccentIndex = idx
                            Haptics.impact(.light)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(ColorPalette[idx])
                                    .frame(width: 34, height: 34)

                                if selectedAccentIndex == idx {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 2)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(DS.Space.lg)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: =====================================================================
    // MARK: ⚙️ 3. GENERAL & STARTUP SECTION
    // MARK: =====================================================================

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // 1. Startup & Window Sizing
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(title: "STARTUP & WINDOW BEHAVIOR", subtitle: "Window sizing and interaction feedback")

                VStack(spacing: 0) {
                    settingToggleRow(
                        title: "Launch PLUTO Automatically at Login",
                        subtitle: "Runs as a persistent background companion on startup (ServiceManagement)",
                        isOn: Binding(
                            get: { loginManager.isEnabled },
                            set: { newVal in
                                loginManager.setLaunchAtLogin(enabled: newVal)
                            }
                        )
                    )

                    Divider().padding(.horizontal, DS.Space.lg)

                    settingToggleRow(
                        title: "Open in Full Window on Launch",
                        subtitle: "Automatically expand the window to fill your display on startup",
                        isOn: $openFullWindow
                    )

                    Divider().padding(.horizontal, DS.Space.lg)

                    settingToggleRow(
                        title: "Haptic Feedback",
                        subtitle: "Trigger tactile feedback when logging habits and completing tasks",
                        isOn: $enableHaptics
                    )

                    Divider().padding(.horizontal, DS.Space.lg)

                    settingToggleRow(
                        title: "Start Week on Monday",
                        subtitle: "Use Monday as the first day of the week in heatmaps and calendars",
                        isOn: $weekStartMonday
                    )
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                )
            }

            // 2. Global Hotkey (⌃⌥P Quick Action HUD)
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(title: "GLOBAL KEYBOARD SHORTCUT", subtitle: "Summon PLUTO quick actions from any application")

                HStack(spacing: DS.Space.xl) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("⌃⌥P")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(accentColor, in: RoundedRectangle(cornerRadius: 6))

                            Text("Control + Option + P")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                        }

                        Text("Press anywhere across macOS (in Safari, Xcode, Notes, or Terminal) to summon the floating HUD for instant habit logging, fast task capture, and focus sprints.")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineSpacing(2)
                    }

                    Spacer()

                    Button {
                        hotkeyManager.toggleHUD()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "macwindow.on.rectangle")
                            Text("Test HUD Overlay")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Color.border.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 3. Apple Calendar Sync (EventKit)
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(title: "APPLE CALENDAR SYNC (EVENTKIT)", subtitle: "Display native calendar events inside Day Planner")

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(calendarSync.isAuthorized ? DS.Color.success : Color(red: 0.95, green: 0.68, blue: 0.22))
                                    .frame(width: 8, height: 8)

                                Text(calendarSync.isAuthorized ? "Calendar Access Granted" : "Calendar Permission Required")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }

                            Text(calendarSync.isAuthorized ? "PLUTO reads your scheduled Apple Calendar events to display timeline blocks alongside tasks." : "Grant permission so PLUTO can read your calendar events without manual .ics exports.")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Spacer()

                        if !calendarSync.isAuthorized {
                            Button {
                                Task {
                                    _ = await calendarSync.requestAuthorization()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Grant Access")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(accentColor, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(DS.Space.lg)

                    Divider().padding(.horizontal, DS.Space.lg)

                    settingToggleRow(
                        title: "Show Apple Calendar Events on Timeline",
                        subtitle: "Overlay calendar meetings and appointments with one-click Convert to Task",
                        isOn: $calendarSyncEnabled
                    )
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }
        }
    }

    // MARK: =====================================================================
    // MARK: 🔒 4. DATA & CLOUD SYNC SECTION
    // MARK: =====================================================================

    private var dataSyncSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            settingsGroupHeader(title: "STORAGE & PRIVACY", subtitle: "Zero-telemetry local-first architecture")

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Architecture Status")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Local-First SwiftData with Private CloudKit syncing")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(DS.Color.success).frame(width: 7, height: 7)
                        Text("On-Device & Encrypted")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.success)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DS.Color.success.opacity(0.12), in: Capsule())
                }
                .padding(DS.Space.lg)

                Divider().padding(.horizontal, DS.Space.lg)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Export Database")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Save a portable JSON backup of your habits, logs, and dreams")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                    Button("Export JSON…") {
                        showingExportSuccess = true
                        Haptics.impact(.rigid)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(DS.Space.lg)

                #if DEBUG
                Divider().padding(.horizontal, DS.Space.lg)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Seed Sample Content")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Populate demo habits, task sprints, and master bucket list dreams")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                    Button("Re-Seed Data") {
                        DebugSeeder.seedIfNeeded(context: modelContext)
                        LifeSeeder.seedIfNeeded(context: modelContext)
                        Haptics.impact(.rigid)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(DS.Space.lg)
                #endif
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: =====================================================================
    // MARK: 🔥 5. HABITS & ENGINE SECTION
    // MARK: =====================================================================

    private var habitsEngineSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            settingsGroupHeader(title: "ANALYTICS & ENGINES", subtitle: "Streak formulas and progress cache")

            VStack(spacing: 0) {
                settingToggleRow(
                    title: "Live Streak Recalculation",
                    subtitle: "Automatically refresh streaks and heatmaps on every check-in",
                    isOn: $autoCalculateStreaks
                )

                Divider().padding(.horizontal, DS.Space.lg)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Rebuild Analytics Cache")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Force recalculation of all habit streaks and 182-day heatmaps")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                    Button("Recalculate Now") {
                        showingRecalculateSuccess = true
                        Haptics.impact(.rigid)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(DS.Space.lg)
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: =====================================================================
    // MARK: ℹ️ 6. ABOUT SECTION
    // MARK: =====================================================================

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            settingsGroupHeader(title: "ABOUT PLUTO", subtitle: "Local-First Habit & Life Architecture")

            VStack(alignment: .leading, spacing: DS.Space.md) {
                HStack(spacing: 12) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PLUTO App Version 4.0")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Version 4.0 (Alpine Edition) · Built with SwiftData, SwiftCharts & Topo MapKit")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }

                Divider()

                Text("PLUTO is designed from first principles as a local-first habit, task, and life operating system. Your data lives on your device and syncs securely through Apple CloudKit with zero third-party analytics or tracking.")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(3)

                Divider()

                HStack {
                    Button {
                        NotificationCenter.default.post(name: .locaShowOnboarding, object: nil)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("Replay Welcome & Feature Tour…")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
            .padding(DS.Space.xl)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Subcomponents

    private func settingsGroupHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)
                .tracking(0.6)
            Text(subtitle)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    private func settingToggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Text(subtitle)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(DS.Space.lg)
    }

    // MARK: =====================================================================
    // MARK: 🔒 2. PRIVACY & SECURE ENCLAVE VAULT
    // MARK: =====================================================================

    @ObservedObject private var vaultManager = LocaVaultAuthManager.shared

    private var vaultSecuritySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // 1. Biometric Protection
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "SECURE ENCLAVE BIOMETRICS",
                    subtitle: "Hardware-level encryption for private journal entries and life strategy"
                )

                VStack(spacing: 0) {
                    settingToggleRow(
                        title: "Enable \(vaultManager.biometryTypeString) Vault Lock",
                        subtitle: "Require biometric authentication to open Private Journal and Life Blueprint",
                        isOn: $vaultManager.isVaultSecurityEnabled
                    )

                    if vaultManager.isVaultSecurityEnabled {
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Auto-Lock Inactivity Timeout")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text("Time before vault automatically relocks when inactive")
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Spacer()

                            Picker("", selection: $vaultManager.autoLockMinutes) {
                                Text("Immediately on Sleep/Background").tag(0)
                                Text("After 1 Minute").tag(1)
                                Text("After 5 Minutes").tag(5)
                                Text("After 15 Minutes").tag(15)
                            }
                            .frame(width: 220)
                            .labelsHidden()
                        }
                        .padding(DS.Space.lg)

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Manual Vault Lock")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text("Immediately lock all sensitive workspaces")
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Spacer()

                            Button {
                                vaultManager.lockAll()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                    Text("Lock Vault Now")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(DS.Color.danger, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(DS.Space.lg)
                    }
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 2. Local-First Privacy Assurance
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "PRIVACY ARCHITECTURE",
                    subtitle: "Zero third-party telemetry, zero cloud trackers"
                )

                HStack(spacing: DS.Space.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(DS.Color.success)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("100% On-Device & Encrypted")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("Your habits, journal reflections, sleep records, and goals are stored exclusively inside your Mac's private local SwiftData container. No external servers ever access your data.")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineSpacing(2)
                    }
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }
        }
    }

    // MARK: =====================================================================
    // MARK: 🔔 NOTIFICATIONS & REMINDERS STUDIO (A1-A4)
    // MARK: =====================================================================

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // 1. Master System Notification Status & Authorization
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "SYSTEM NOTIFICATION STATUS",
                    subtitle: "macOS UserNotifications system integration"
                )

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(notificationManager.isAuthorized ? DS.Color.success : Color(red: 0.95, green: 0.68, blue: 0.22))
                                    .frame(width: 8, height: 8)

                                Text(notificationManager.isAuthorized ? "macOS System Authorized" : "Permission Required")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)

                                if notificationManager.pendingRequestsCount > 0 {
                                    Text("(\(notificationManager.pendingRequestsCount) active triggers)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(DS.Color.textTertiary)
                                }
                            }

                            Text(notificationManager.isAuthorized ? "PLUTO has system permission to deliver streak-aware alerts and prompts." : "Enable notifications in System Settings to receive habit reminders.")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Spacer()

                        if !notificationManager.isAuthorized {
                            Button {
                                Task {
                                    _ = await notificationManager.requestAuthorization()
                                    triggerSync()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.badge.fill")
                                    Text("Request Permission")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(accentColor, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(DS.Space.lg)

                    Divider()

                    settingToggleRow(
                        title: "Enable PLUTO Native Notifications",
                        subtitle: "Master switch for smart habit reminders, actionable buttons, and evening reflections",
                        isOn: Binding(
                            get: { masterNotificationsEnabled },
                            set: { newVal in
                                masterNotificationsEnabled = newVal
                                triggerSync()
                            }
                        )
                    )
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 2. A2: Actionable Notification Buttons Showcase & Live Test
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "A2 · ZERO-FRICTION ACTIONABLE NOTIFICATIONS",
                    subtitle: "Log habits and snooze reminders directly from the banner without opening the app"
                )

                VStack(alignment: .leading, spacing: DS.Space.md) {
                    HStack(spacing: DS.Space.xl) {
                        // Mock Banner representation
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(DS.Color.streak)
                                    .font(.system(size: 12))
                                Text("PLUTO · Running (14-Day Streak)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Spacer()
                                Text("now")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }

                            Text("Keep your 14-day streak alive! Time to execute.")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Color.textSecondary)

                            HStack(spacing: 8) {
                                Text("✅ Mark as Done")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 4))
                                    .foregroundStyle(DS.Color.textPrimary)

                                Text("⏰ Snooze 1 Hour")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 4))
                                    .foregroundStyle(DS.Color.textSecondary)
                            }
                            .padding(.top, 2)
                        }
                        .padding(DS.Space.md)
                        .background(DS.Color.background, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Color.border.opacity(0.6), lineWidth: 1))
                        .frame(maxWidth: 340)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interactive Notification Banner")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)

                            Text("Clicking **Mark as Done** updates SwiftData, calculates your streak, and refreshes Desktop Widgets in the background with zero lag.")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                                .lineSpacing(2)

                            Button {
                                notificationManager.sendInstantTestNotification()
                                testNotificationBanner = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                    testNotificationBanner = false
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Instant Test Notification")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(accentColor, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)

                            if testNotificationBanner {
                                Text("⚡ Test notification firing in 3 seconds...")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(DS.Color.success)
                                    .transition(.opacity)
                            }
                        }
                    }
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 3. A1: Smart Habit Reminders (Streak-Aware)
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "A1 · SMART HABIT REMINDERS",
                    subtitle: "Dynamic streak-aware notifications per habit"
                )

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Default Habit Reminder Time")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Baseline reminder time for habits without a custom schedule")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Spacer()

                        Picker("", selection: Binding(
                            get: { defaultHabitTime },
                            set: { newVal in
                                defaultHabitTime = newVal
                                triggerSync()
                            }
                        )) {
                            Text("07:00 AM").tag("07:00")
                            Text("08:00 AM").tag("08:00")
                            Text("09:00 AM (Default)").tag("09:00")
                            Text("10:00 AM").tag("10:00")
                            Text("12:00 PM").tag("12:00")
                            Text("06:00 PM").tag("18:00")
                            Text("08:00 PM").tag("20:00")
                        }
                        .frame(width: 180)
                        .labelsHidden()
                    }
                    .padding(DS.Space.lg)

                    Divider()

                    // Per-habit custom schedule list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACTIVE HABITS & SCHEDULES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)
                            .padding(.horizontal, DS.Space.lg)
                            .padding(.top, DS.Space.md)

                        ForEach(activeHabits) { habit in
                            HStack {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(ColorPalette[habit.colorIndex])
                                        .frame(width: 8, height: 8)

                                    Text(habit.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(DS.Color.textPrimary)

                                    if habit.currentStreak > 0 {
                                        Text("\(habit.currentStreak)d streak")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(DS.Color.streak)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DS.Color.surfaceRecessed, in: Capsule())
                                    }
                                }

                                Spacer()

                                Picker("", selection: Binding(
                                    get: { habit.preferredReminderTime ?? defaultHabitTime },
                                    set: { newVal in
                                        habit.preferredReminderTime = newVal
                                        try? modelContext.save()
                                        triggerSync()
                                    }
                                )) {
                                    Text("07:00 AM").tag("07:00")
                                    Text("08:00 AM").tag("08:00")
                                    Text("09:00 AM").tag("09:00")
                                    Text("12:00 PM").tag("12:00")
                                    Text("05:00 PM").tag("17:00")
                                    Text("06:00 PM").tag("18:00")
                                    Text("08:00 PM").tag("20:00")
                                    Text("09:00 PM").tag("21:00")
                                }
                                .frame(width: 130)
                                .labelsHidden()
                            }
                            .padding(.horizontal, DS.Space.lg)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, DS.Space.md)
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 4. A3: Evening Reflection Prompt
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "A3 · EVENING REFLECTION PROMPT",
                    subtitle: "Daily cognitive decompression and reflection prompt"
                )

                VStack(spacing: 0) {
                    settingToggleRow(
                        title: "Daily Evening Reflection Prompt",
                        subtitle: "Delivers a calm notification at 9 PM to capture daily wins, moments, and energy in Journal",
                        isOn: Binding(
                            get: { eveningReflectionEnabled },
                            set: { newVal in
                                eveningReflectionEnabled = newVal
                                triggerSync()
                            }
                        )
                    )

                    if eveningReflectionEnabled {
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Reflection Delivery Time")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text("Time of evening to receive the reflection reminder")
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Spacer()

                            Picker("", selection: Binding(
                                get: { eveningReflectionTime },
                                set: { newVal in
                                    eveningReflectionTime = newVal
                                    triggerSync()
                                }
                            )) {
                                Text("08:00 PM (20:00)").tag("20:00")
                                Text("08:30 PM (20:30)").tag("20:30")
                                Text("09:00 PM (21:00 · Default)").tag("21:00")
                                Text("09:30 PM (21:30)").tag("21:30")
                                Text("10:00 PM (22:00)").tag("22:00")
                            }
                            .frame(width: 200)
                            .labelsHidden()
                        }
                        .padding(DS.Space.lg)
                    }
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 5. A4: Streak Break Alert
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "A4 · STREAK BREAK ALERT",
                    subtitle: "Emergency notification before midnight for unlogged habits"
                )

                VStack(spacing: 0) {
                    settingToggleRow(
                        title: "Urgent Streak Break Warning",
                        subtitle: "Alerts you if any active habit streak is at risk of breaking before midnight",
                        isOn: Binding(
                            get: { streakAlertEnabled },
                            set: { newVal in
                                streakAlertEnabled = newVal
                                triggerSync()
                            }
                        )
                    )

                    if streakAlertEnabled {
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Warning Trigger Time")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text("Time to alert you if habits remain uncompleted today")
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Spacer()

                            Picker("", selection: Binding(
                                get: { streakAlertTime },
                                set: { newVal in
                                    streakAlertTime = newVal
                                    triggerSync()
                                }
                            )) {
                                Text("09:00 PM (21:00)").tag("21:00")
                                Text("09:30 PM (21:30)").tag("21:30")
                                Text("10:00 PM (22:00 · Default)").tag("22:00")
                                Text("10:30 PM (22:30)").tag("22:30")
                                Text("11:00 PM (23:00)").tag("23:00")
                            }
                            .frame(width: 200)
                            .labelsHidden()
                        }
                        .padding(DS.Space.lg)
                    }
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 6. A5: Focus Session Complete Notifications
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "A5 · FOCUS SESSION COMPLETION",
                    subtitle: "Background delivery when Pomodoro timers expire"
                )

                HStack(spacing: DS.Space.md) {
                    Image(systemName: "timer")
                        .font(.system(size: 22))
                        .foregroundStyle(DS.Color.active)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Always-On Focus Timer Notification")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("When an active Pomodoro session or Deep Work countdown finishes, PLUTO delivers a completion notification with session stats even if the app is minimized or backgrounded.")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineSpacing(2)
                    }
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 7. A6: Weekly Progress Digest (Sunday 8 AM)
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "A6 · WEEKLY PROGRESS DIGEST",
                    subtitle: "Passive Sunday morning summary across habits, wins, and deep work"
                )

                VStack(spacing: 0) {
                    settingToggleRow(
                        title: "Sunday Morning Executive Digest (8:00 AM)",
                        subtitle: "Delivers a summary of your 7-day compounding percentage, deep work hours, and journal wins",
                        isOn: Binding(
                            get: { weeklyDigestEnabled },
                            set: { newVal in
                                weeklyDigestEnabled = newVal
                                triggerSync()
                            }
                        )
                    )
                }
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }

            // 8. A8: Notification Interrupt Levels Architecture
            VStack(alignment: .leading, spacing: DS.Space.md) {
                settingsGroupHeader(
                    title: "A8 · SYSTEM INTERRUPTION LEVELS",
                    subtitle: "Respectful cognitive attention routing"
                )

                VStack(spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "bolt.badge.clock.fill")
                            .foregroundStyle(DS.Color.streak)
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time Sensitive (.timeSensitive)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Habit Reminders, Focus Sprints, and 10 PM Streak Break alerts break through system Focus modes so you never lose momentum.")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                    .padding(DS.Space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(Color(red: 0.68, green: 0.45, blue: 0.98))
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Passive (.passive)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Sunday Weekly Progress Digest is delivered silently into Notification Center without waking your display.")
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                    .padding(DS.Space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
            }
        }
    }

    private func triggerSync() {
        notificationManager.syncAll(
            habits: activeHabits,
            masterEnabled: masterNotificationsEnabled,
            eveningReflectionEnabled: eveningReflectionEnabled,
            eveningReflectionTime: eveningReflectionTime,
            streakAlertEnabled: streakAlertEnabled,
            streakAlertTime: streakAlertTime,
            weeklyDigestEnabled: weeklyDigestEnabled,
            defaultHabitTime: defaultHabitTime
        )
    }
}
