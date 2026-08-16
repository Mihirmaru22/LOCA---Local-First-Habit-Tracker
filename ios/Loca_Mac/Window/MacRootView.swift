import SwiftUI
import SwiftData
import CoreSpotlight

// MARK: - MacSection

/// Top-level navigation sections shown in the Mac sidebar.
/// Ordered to match the natural daily workflow: check habits first,
/// then review today's completions, then journal.
enum MacSection: String, CaseIterable, Identifiable {
    case habits   = "Habits"
    case today    = "Today"
    case time     = "Time"
    case journal  = "Journal"
    case life     = "Life"
    case treks    = "Trek Atlas"
    case github   = "GitHub"
    case audit    = "Audit"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .habits:   "checkmark.circle"
        case .today:    "sun.max"
        case .time:     "timer"
        case .journal:  "book.closed"
        case .life:     "binoculars"
        case .treks:    "mountain.2.fill"
        case .github:   "cpu.fill"
        case .audit:    "slider.horizontal.3"
        case .settings: "gearshape"
        }
    }
}

// MARK: - MacRootView

/// Three-pane root for the macOS app.
///
/// Column roles:
/// - **Sidebar** (`MacSidebarView`): section picker (Habits, Today, Time, Journal, Life, Trek Atlas, Audit, Settings).
/// - **Content** (`MacHabitContentColumn` etc.): list for the active section.
/// - **Detail** (`MacHabitDetailColumn` etc.): selected-item detail.
///
/// `selectedHabit` is owned here so it spans both the content and detail columns
/// without either column owning the other. The content column writes it via a
/// `@Binding`; the detail column reads it as a plain `let`.
struct MacRootView: View {

    @State private var selectedSection:     MacSection?      = .habits
    @State private var selectedHabit:       HabitBoard?      = nil
    @State private var selectedTodo:        TodoItem?        = nil
    @State private var selectedJournalRow:  JournalRow?      = .todaysLog
    @State private var selectedJournalNote: JournalNote?     = nil
    @State private var selectedLifeRow:     LifeRow?         = .blueprint
    @State private var columnVisibility:    NavigationSplitViewVisibility = .all
    @AppStorage("has_completed_onboarding_v3") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding:      Bool             = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ObservedObject private var vaultManager = LocaVaultAuthManager.shared

    @Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil }, sort: \HabitBoard.createdAt)
    private var activeHabits: [HabitBoard]

    @AppStorage("mac_notifications_master_enabled") private var masterNotificationsEnabled: Bool = true
    @AppStorage("mac_evening_reflection_enabled") private var eveningReflectionEnabled: Bool = true
    @AppStorage("mac_evening_reflection_time") private var eveningReflectionTime: String = "21:00"
    @AppStorage("mac_streak_alert_enabled") private var streakAlertEnabled: Bool = true
    @AppStorage("mac_streak_alert_time") private var streakAlertTime: String = "22:00"
    @AppStorage("mac_weekly_digest_enabled") private var weeklyDigestEnabled: Bool = true
    @AppStorage("mac_default_habit_reminder_time") private var defaultHabitTime: String = "09:00"

    var body: some View {
        splitView
    }

    private var splitView: some View {
        Group {
            if selectedSection == .audit || selectedSection == .life || selectedSection == .time || selectedSection == .settings || selectedSection == .treks || selectedSection == .github {
                NavigationSplitView {
                    MacSidebarView(selection: $selectedSection)
                        .navigationSplitViewColumnWidth(
                            min:   DS.Mac.sidebarMinWidth,
                            ideal: DS.Mac.sidebarIdealWidth,
                            max:   DS.Mac.sidebarMaxWidth
                        )
                } detail: {
                    if selectedSection == .audit {
                        MacAuditView()
                    } else if selectedSection == .life {
                        if vaultManager.isVaultSecurityEnabled && !vaultManager.isLifeUnlocked {
                            MacVaultLockView(sectionTitle: "Life Blueprint & Strategy")
                        } else {
                            MacLifeView()
                        }
                    } else if selectedSection == .treks {
                        MacTrekAtlasCanvas()
                    } else if selectedSection == .github {
                        MacGitHubCosmosCanvas()
                    } else if selectedSection == .time {
                        MacTimeView()
                    } else {
                        MacSettingsView()
                    }
                }
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    MacSidebarView(selection: $selectedSection)
                        .navigationSplitViewColumnWidth(
                            min:   DS.Mac.sidebarMinWidth,
                            ideal: DS.Mac.sidebarIdealWidth,
                            max:   DS.Mac.sidebarMaxWidth
                        )
                } content: {
                    MacContentColumn(section: selectedSection,
                                     selectedHabit:       $selectedHabit,
                                     selectedTodo:        $selectedTodo,
                                     selectedJournalRow:  $selectedJournalRow,
                                     selectedJournalNote: $selectedJournalNote,
                                     selectedLifeRow:     $selectedLifeRow)
                        .navigationSplitViewColumnWidth(
                            min:   DS.Mac.contentMinWidth,
                            ideal: DS.Mac.contentIdealWidth,
                            max:   DS.Mac.contentMaxWidth
                        )
                } detail: {
                    if selectedSection == .journal && vaultManager.isVaultSecurityEnabled && !vaultManager.isJournalUnlocked {
                        MacVaultLockView(sectionTitle: "Private Journal")
                            .navigationSplitViewColumnWidth(
                                min:   DS.Mac.detailMinWidth,
                                ideal: DS.Mac.detailIdealWidth
                            )
                    } else {
                        MacDetailColumn(section: selectedSection,
                                         selectedHabit:       $selectedHabit,
                                         selectedTodo:        $selectedTodo,
                                         selectedJournalRow:  $selectedJournalRow,
                                         selectedJournalNote: $selectedJournalNote,
                                         selectedLifeRow:     $selectedLifeRow)
                            .navigationSplitViewColumnWidth(
                                min:   DS.Mac.detailMinWidth,
                                ideal: DS.Mac.detailIdealWidth
                            )
                    }
                }
            }
        }
        .navigationTitle("PLUTO")
        .sheet(isPresented: $showOnboarding) {
            MacOnboardingView(isPresented: $showOnboarding)
                .frame(minWidth: 720, minHeight: 520)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }

            LocaSpotlightIndexer.shared.indexAll(context: modelContext)

            // Auto-sync Apple Native Notifications (A1-A8)
            PlutoNotificationManager.shared.syncAll(
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
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
               let (type, _) = LocaSpotlightIndexer.ItemType.parseIdentifier(identifier) {
                switch type {
                case .habit:
                    selectedSection = .habits
                case .task:
                    selectedSection = .today
                case .journal:
                    selectedSection = .journal
                case .principle, .bucket:
                    selectedSection = .life
                case .goal:
                    selectedSection = .audit
                }
            }
        }
        .onChange(of: selectedSection) { _, _ in
            selectedHabit      = nil
            selectedTodo       = nil
            selectedJournalRow = .todaysLog
            selectedLifeRow    = .blueprint
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaJumpToSection)) { note in
            if let section = note.object as? MacSection {
                selectedSection = section
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaShowOnboarding)) { _ in
            showOnboarding = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaCompleteSelected)) { _ in
            guard let todo = selectedTodo else { return }
            todo.completedAt = todo.isCompleted ? nil : Date()
            try? modelContext.save()
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaArchiveSelected)) { _ in
            guard let todo = selectedTodo else { return }
            todo.archivedAt = Date()
            selectedTodo = nil
            try? modelContext.save()
        }
        .onReceive(NotificationCenter.default.publisher(for: .locaDeepLink)) { note in
            if let payload = note.object as? PlutoNotificationManager.DeepLinkPayload {
                withAnimation(reduceMotion ? nil : DS.Motion.settle) {
                    selectedSection = payload.section
                    if let habitID = payload.habitID {
                        selectedHabit = activeHabits.first(where: { $0.id == habitID })
                    }
                    if let taskID = payload.taskID,
                       let tasks = try? modelContext.fetch(FetchDescriptor<TodoItem>()) {
                        selectedTodo = tasks.first(where: { $0.id == taskID })
                    }
                }
                Haptics.impact(.light)
            }
        }
        .onOpenURL { url in
            PlutoNotificationManager.shared.handleDeepLinkURL(url)
        }
    }
}

// MARK: - MacContentColumn

/// Picks the correct content list for the active sidebar section.
private struct MacContentColumn: View {

    let section: MacSection?
    @Binding var selectedHabit:       HabitBoard?
    @Binding var selectedTodo:        TodoItem?
    @Binding var selectedJournalRow:  JournalRow?
    @Binding var selectedJournalNote: JournalNote?
    @Binding var selectedLifeRow:     LifeRow?

    var body: some View {
        switch section {
        case .habits:
            MacHabitContentColumn(selection: $selectedHabit)
        case .today:
            MacTodoContentColumn(selection: $selectedTodo)
        case .journal:
            MacJournalContentColumn(selectedRow: $selectedJournalRow, selectedNote: $selectedJournalNote)
        case .life:
            MacLifeContentColumn(selectedRow: $selectedLifeRow)
        case .audit, .settings, .time, .treks:
            EmptyView()
        case nil:
            MacEmptyContentView()
        }
    }
}

// MARK: - MacDetailColumn

/// Picks the correct detail view for the active section and selection.
private struct MacDetailColumn: View {

    let section: MacSection?
    @Binding var selectedHabit:       HabitBoard?
    @Binding var selectedTodo:        TodoItem?
    @Binding var selectedJournalRow:  JournalRow?
    @Binding var selectedJournalNote: JournalNote?
    @Binding var selectedLifeRow:     LifeRow?

    var body: some View {
        switch section {
        case .habits:
            MacHabitDetailColumn(habit: selectedHabit)
        case .today:
            MacTodoDetailColumn(item: $selectedTodo)
        case .journal:
            MacJournalDetailColumn(selectedRow: $selectedJournalRow, selectedNote: $selectedJournalNote)
        case .life:
            MacLifeDetailColumn(selectedRow: selectedLifeRow)
        case .treks:
            MacTrekAtlasCanvas()
        case .time:
            MacTimeView()
        case .audit:
            MacAuditDetailColumn()
        case .settings:
            MacSettingsView()
        case nil:
            MacDetailPlaceholder()
        }
    }
}

private struct MacEmptyContentView: View {
    var body: some View {
        ContentUnavailableView("No Section Selected", systemImage: "sidebar.left")
    }
}

// MARK: - MacDetailPlaceholder

struct MacDetailPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Select an Item",
            systemImage: "arrow.left.to.line",
            description: Text("Choose a habit from the list to see its detail.")
        )
    }
}

// MARK: - Preview

#Preview {
    MacRootView()
}
