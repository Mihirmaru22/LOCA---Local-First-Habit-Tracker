import SwiftUI
import Combine

// MARK: - PlutoAppGuideStep

enum PlutoAppGuideStep: Int, CaseIterable, Identifiable {
    case sidebarNavigation      = 0
    case todayPriorityMatrix    = 1
    case todayMetricsArchitecture = 2
    case todayFocusSprintTimer  = 3
    case studioNotesHierarchy   = 4
    case studioEditorEngine     = 5
    case studioProjectsMatrix   = 6
    case lifeSatelliteAtlas     = 7
    case lifeBlueprintHorizon   = 8
    case sovereignVaultSettings = 9

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sidebarNavigation:        return "Command Navigation Sidebar"
        case .todayPriorityMatrix:      return "Priority Task Matrix (P1–P4)"
        case .todayMetricsArchitecture: return "Day Architecture & Metrics HUD"
        case .todayFocusSprintTimer:    return "Focus Sprint & Acoustic Timers"
        case .studioNotesHierarchy:     return "Notes Library & #Tag Taxonomy"
        case .studioEditorEngine:       return "Rich-Text Engine & Formatting"
        case .studioProjectsMatrix:     return "Projects & Milestone Matrix"
        case .lifeSatelliteAtlas:       return "Satellite Trek & Travel Atlas"
        case .lifeBlueprintHorizon:     return "Life Blueprint & 10-Year Horizon"
        case .sovereignVaultSettings:   return "Biometric Vault & Offline Storage"
        }
    }

    var subtitle: String {
        switch self {
        case .sidebarNavigation:        return "4-PILLAR ARCHITECTURE"
        case .todayPriorityMatrix:      return "DISCIPLINE ENGINE"
        case .todayMetricsArchitecture: return "PERFORMANCE HUD"
        case .todayFocusSprintTimer:    return "DEEP WORK HORIZON"
        case .studioNotesHierarchy:     return "KNOWLEDGE REPOSITORY"
        case .studioEditorEngine:       return "APPLE NOTES ENGINE"
        case .studioProjectsMatrix:     return "EXECUTION BREAKDOWN"
        case .lifeSatelliteAtlas:       return "GLOBAL EXPEDITION SYSTEM"
        case .lifeBlueprintHorizon:     return "10-YEAR LIFE STRATEGY"
        case .sovereignVaultSettings:   return "ZERO-CLOUD PRIVACY"
        }
    }

    var icon: String {
        switch self {
        case .sidebarNavigation:        return "sidebar.left"
        case .todayPriorityMatrix:      return "list.bullet.indent"
        case .todayMetricsArchitecture: return "chart.bar.xaxis"
        case .todayFocusSprintTimer:    return "timer"
        case .studioNotesHierarchy:     return "folder.fill"
        case .studioEditorEngine:       return "character.textbox"
        case .studioProjectsMatrix:     return "briefcase.fill"
        case .lifeSatelliteAtlas:       return "mountain.2.fill"
        case .lifeBlueprintHorizon:     return "target"
        case .sovereignVaultSettings:   return "lock.shield.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .sidebarNavigation:        return Color(red: 0.35, green: 0.65, blue: 0.95)
        case .todayPriorityMatrix:      return Color(red: 0.95, green: 0.77, blue: 0.25)
        case .todayMetricsArchitecture: return Color(red: 0.35, green: 0.85, blue: 0.65)
        case .todayFocusSprintTimer:    return Color(red: 0.85, green: 0.40, blue: 0.40)
        case .studioNotesHierarchy:     return Color(red: 0.95, green: 0.75, blue: 0.25)
        case .studioEditorEngine:       return Color(red: 0.95, green: 0.60, blue: 0.20)
        case .studioProjectsMatrix:     return Color(red: 0.25, green: 0.85, blue: 0.55)
        case .lifeSatelliteAtlas:       return Color(red: 0.30, green: 0.85, blue: 0.80)
        case .lifeBlueprintHorizon:     return Color(red: 0.75, green: 0.55, blue: 0.95)
        case .sovereignVaultSettings:   return Color(red: 0.95, green: 0.55, blue: 0.35)
        }
    }

    /// High-density structured details: (Icon, Header, Description)
    var detailsList: [(icon: String, header: String, text: String)] {
        switch self {
        case .sidebarNavigation:
            return [
                ("rectangle.3.group", "4 Pillar System", "Instantly partition life into Today (Discipline), Studio (Notes/Projects), Life (Atlas/Blueprint), and Settings (Vault)."),
                ("command", "Global Shortcuts", "Jump anywhere with ⌘1 (Today), ⌘2 (Studio), ⌘3 (Life), and ⌘, (Settings)."),
                ("bolt.fill", "120 FPS Native", "Built purely in SwiftData & AppKit with zero web views or input latency.")
            ]
        case .todayPriorityMatrix:
            return [
                ("flag.fill", "P1–P4 Priority Tiers", "Categorize tasks by High (P1), Medium (P2), Standard (P3), and Backlog (P4)."),
                ("checkmark.circle.fill", "Quick Execution", "Press ⌘N to create a block, ⌘Return to complete, and ⌘Delete to archive."),
                ("clock.arrow.2.circlepath", "Timeline Drag", "Easily nudge tasks earlier (⌥↑) or later (⌥↓) in 5-minute intervals.")
            ]
        case .todayMetricsArchitecture:
            return [
                ("gauge.with.needle.fill", "Live Telemetry", "Real-time metrics on Planned Focus Time, completion percentage, and unscheduled tasks."),
                ("calendar", "Day Shifting", "Press ← / → arrow keys to review past execution logs or plan future days."),
                ("quote.opening", "Daily Philosophy", "Curated stoic axioms refresh every morning at 05:00 to align focus.")
            ]
        case .todayFocusSprintTimer:
            return [
                ("hourglass", "25-Minute Sprints", "Pomodoro deep-work sessions with visual glowing countdown rings."),
                ("arrow.up.left.and.arrow.down.right", "Focus Mode (⌘⇧T)", "Expand into full-screen Zen mode with zero visual distractions."),
                ("speaker.wave.2.fill", "Acoustic Soundscapes", "Tactile summit gongs, mechanical ticking, and binaural audio feedback.")
            ]
        case .studioNotesHierarchy:
            return [
                ("text.badge.star", "4-Line Snippet Previews", "Expansive card previews show up to 4 content lines with softened titles."),
                ("number", "Instant #Tags", "Organize thoughts naturally with inline #tags and realtime sidebar filtering."),
                ("pin.fill", "Smart Organization", "Dedicated views for Pinned, Favorites, Quick Notes, and Biometric Locked notes.")
            ]
        case .studioEditorEngine:
            return [
                ("textformat", "Rich Typography (Aa)", "Format Titles, Subtitles, Monospace code, and curated highlight colors."),
                ("checklist", "Smart Checklists (⌘⇧C)", "Interactive todo circles that automatically animate to the bottom when checked."),
                ("tablecells.badge.ellipsis", "Tables & Media", "Insert 2D grid tables (⊞) and attach images, PDFs, or audio (📎).")
            ]
        case .studioProjectsMatrix:
            return [
                ("arrow.triangle.branch", "Milestone Trees", "Decompose ambitious multi-month goals into phased deliverables and sub-tasks."),
                ("link", "Inter-Pillar Bridges", "Convert raw brainstorm notes directly into structured projects with one click."),
                ("chart.line.uptrend.xyaxis", "Auto-Calculated Progress", "Real-time progress bars computed dynamically from completed sub-tasks.")
            ]
        case .lifeSatelliteAtlas:
            return [
                ("globe.americas.fill", "Apple Satellite 3D", "High-altitude satellite canvas with terrain contours and elevation overlays."),
                ("mappin.and.ellipse", "Summit Passports", "Log mountain summits, visited GPS coordinates, and trek passport stamps."),
                ("figure.hiking", "Expedition Journal", "Attach route photos, altitude records, and trail notes directly to map pins.")
            ]
        case .lifeBlueprintHorizon:
            return [
                ("star.fill", "Master Bucket List", "Lifetime ambitions categorized into Adventure, Mastery, and Freedom."),
                ("shield.lefthalf.filled", "Core Principles", "Document your non-negotiable personal manifesto and life values."),
                ("timeline.selection", "10-Year Horizon", "Phased decade roadmap with annual progress milestones and financial goals.")
            ]
        case .sovereignVaultSettings:
            return [
                ("touchid", "Secure Enclave Hardware", "Touch ID & Face ID biometric locks protect sensitive notes and journals."),
                ("internaldrive.fill", "Local-First Zero Cloud", "Data stays strictly in your local SQLite database without cloud telemetry."),
                ("paintpalette.fill", "8 Executive Themes", "Tailored color palettes and custom acoustic sound effects.")
            ]
        }
    }

    var shortcutHint: String {
        switch self {
        case .sidebarNavigation:        return "Navigate: Click or ⌘1 - ⌘4"
        case .todayPriorityMatrix:      return "New Task: ⌘N · Complete: ⌘↩"
        case .todayMetricsArchitecture: return "Shift Day: ← / → Arrow Keys"
        case .todayFocusSprintTimer:    return "Focus Mode: ⌘⇧T"
        case .studioNotesHierarchy:     return "New Note: ⌘N · Search: ⌘F"
        case .studioEditorEngine:       return "Format: ⌘B / ⌘I · Checklist: ⌘⇧C"
        case .studioProjectsMatrix:     return "New Milestone: ⌘M"
        case .lifeSatelliteAtlas:       return "Search Atlas: ⌘F · Satellite: ⌃S"
        case .lifeBlueprintHorizon:     return "Add Goal: Click + Goal"
        case .sovereignVaultSettings:   return "Lock Vault: ⌘L"
        }
    }

    var associatedSection: MacSection {
        switch self {
        case .sidebarNavigation, .todayPriorityMatrix, .todayMetricsArchitecture, .todayFocusSprintTimer:
            return .today
        case .studioNotesHierarchy, .studioEditorEngine:
            return .notes
        case .studioProjectsMatrix:
            return .studio
        case .lifeSatelliteAtlas, .lifeBlueprintHorizon:
            return .life
        case .sovereignVaultSettings:
            return .settings
        }
    }

    /// Calculates pixel-accurate bounding box based on actual macOS window dimensions and column tokens.
    func calculateTargetRect(in windowSize: CGSize) -> CGRect {
        let sidebarWidth: CGFloat = 195
        let topBarY: CGFloat = 36
        let margin: CGFloat = 6

        switch self {
        case .sidebarNavigation:
            // Left sidebar exactly
            return CGRect(
                x: margin,
                y: topBarY,
                width: sidebarWidth - margin * 2,
                height: max(100, windowSize.height - topBarY - margin)
            )

        case .todayPriorityMatrix:
            // Today middle content column (Priority Tasks P1-P4)
            let width: CGFloat = min(340, (windowSize.width - sidebarWidth) * 0.40)
            return CGRect(
                x: sidebarWidth + margin,
                y: topBarY,
                width: width,
                height: max(100, windowSize.height - topBarY - margin)
            )

        case .todayMetricsArchitecture:
            // Today detail top metrics area
            let originX = sidebarWidth + min(340, (windowSize.width - sidebarWidth) * 0.40) + margin * 2
            let sprintWidth: CGFloat = min(360, windowSize.width * 0.30)
            let width = max(200, windowSize.width - originX - sprintWidth - margin)
            return CGRect(
                x: originX,
                y: topBarY,
                width: width,
                height: min(230, windowSize.height * 0.38)
            )

        case .todayFocusSprintTimer:
            // Focus sprint timer on the right
            let sprintWidth: CGFloat = min(380, windowSize.width * 0.32)
            let originX = max(sidebarWidth + margin, windowSize.width - sprintWidth - margin)
            return CGRect(
                x: originX,
                y: topBarY + 4,
                width: sprintWidth,
                height: max(100, windowSize.height - topBarY - margin - 8)
            )

        case .studioNotesHierarchy:
            // Folders and notes list column in Studio
            let width: CGFloat = min(480, (windowSize.width - sidebarWidth) * 0.46)
            return CGRect(
                x: sidebarWidth + margin,
                y: topBarY,
                width: width,
                height: max(100, windowSize.height - topBarY - margin)
            )

        case .studioEditorEngine:
            // Rich-text editor canvas in Studio
            let listWidth: CGFloat = min(480, (windowSize.width - sidebarWidth) * 0.46)
            let originX = sidebarWidth + listWidth + margin * 2
            return CGRect(
                x: originX,
                y: topBarY,
                width: max(200, windowSize.width - originX - margin),
                height: max(100, windowSize.height - topBarY - margin)
            )

        case .studioProjectsMatrix, .lifeSatelliteAtlas, .lifeBlueprintHorizon, .sovereignVaultSettings:
            // Full canvas area for full-width views
            let originX = sidebarWidth + margin
            return CGRect(
                x: originX,
                y: topBarY,
                width: max(200, windowSize.width - originX - margin),
                height: max(100, windowSize.height - topBarY - margin)
            )
        }
    }
}

// MARK: - PlutoAppGuideManager

final class PlutoAppGuideManager: ObservableObject {
    static let shared = PlutoAppGuideManager()

    @Published var isTourActive: Bool = false
    @Published var currentStep: PlutoAppGuideStep = .sidebarNavigation

    private init() {}

    func startTour() {
        currentStep = .sidebarNavigation
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .locaJumpToSection, object: PlutoAppGuideStep.sidebarNavigation.associatedSection)
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            isTourActive = true
        }
        Haptics.impact(.medium)
    }

    func nextStep() {
        if currentStep.rawValue < PlutoAppGuideStep.allCases.count - 1 {
            if let next = PlutoAppGuideStep(rawValue: currentStep.rawValue + 1) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                    currentStep = next
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .locaJumpToSection, object: next.associatedSection)
                }
            }
            Haptics.impact(.light)
        } else {
            finishTour()
        }
    }

    func previousStep() {
        if currentStep.rawValue > 0 {
            if let prev = PlutoAppGuideStep(rawValue: currentStep.rawValue - 1) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                    currentStep = prev
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .locaJumpToSection, object: prev.associatedSection)
                }
            }
            Haptics.impact(.light)
        }
    }

    func jumpTo(step: PlutoAppGuideStep) {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
            currentStep = step
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .locaJumpToSection, object: step.associatedSection)
        }
        Haptics.impact(.light)
    }

    func finishTour() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTourActive = false
        }
        Haptics.notify(.success)
    }
}

// MARK: - SpotlightCutoutShape

struct SpotlightCutoutShape: Shape {
    var cutoutRect: CGRect
    var cornerRadius: CGFloat = 10

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(cutoutRect.origin.x, cutoutRect.origin.y),
                AnimatablePair(cutoutRect.size.width, cutoutRect.size.height)
            )
        }
        set {
            cutoutRect = CGRect(
                x: newValue.first.first,
                y: newValue.first.second,
                width: newValue.second.first,
                height: newValue.second.second
            )
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Outer dark veil
        path.addRect(rect)
        // Inner cutout aperture (rounded matching window panes)
        let innerPath = Path(roundedRect: cutoutRect, cornerRadius: cornerRadius)
        path.addPath(innerPath)
        return path
    }
}

// MARK: - PlutoAppGuideOverlay

struct PlutoAppGuideOverlay: View {
    @ObservedObject var guideManager = PlutoAppGuideManager.shared

    var body: some View {
        GeometryReader { proxy in
            let windowSize = proxy.size
            let step = guideManager.currentStep
            let targetRect = step.calculateTargetRect(in: windowSize)

            ZStack {
                // 1. DULLED / BLURRED BACKDROP WITH CUTOUT SPOTLIGHT
                SpotlightCutoutShape(cutoutRect: targetRect, cornerRadius: 10)
                    .fill(Color.black.opacity(0.68), style: FillStyle(eoFill: true))
                    .background(.ultraThinMaterial.opacity(0.35))
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Clicking anywhere on the blurred background jumps to the next feature!
                        guideManager.nextStep()
                    }

                // 2. ILLUMINATED SPOTLIGHT GLOW BORDER OVER TARGET
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            colors: [step.accentColor, step.accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: step.accentColor.opacity(0.50), radius: 12, x: 0, y: 0)
                    .frame(width: targetRect.width, height: targetRect.height)
                    .position(x: targetRect.midX, y: targetRect.midY)
                    .allowsHitTesting(false)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: guideManager.currentStep)

                // 3. EXPLANATION POPOVER CARD
                popoverCard(step: step, windowSize: windowSize, targetRect: targetRect)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Popover Card

    @ViewBuilder
    private func popoverCard(step: PlutoAppGuideStep, windowSize: CGSize, targetRect: CGRect) -> some View {
        let cardWidth: CGFloat = 460
        let cardHeight: CGFloat = 310

        // Smart positioning so the card never covers the highlighted region:
        let posX: CGFloat = {
            switch step {
            case .sidebarNavigation:
                return targetRect.maxX + cardWidth / 2 + 20
            case .todayPriorityMatrix, .studioNotesHierarchy:
                // Target is on the left-center; put card on the right
                return windowSize.width - cardWidth / 2 - 24
            case .todayFocusSprintTimer:
                // Target is on the right; put card on the left
                return 210 + cardWidth / 2 + 20
            case .todayMetricsArchitecture:
                // Target is top-left detail; put card bottom-left or bottom-right
                return windowSize.width - cardWidth / 2 - 24
            case .studioEditorEngine:
                // Target is editor on the right; put card on bottom-left
                return 210 + cardWidth / 2 + 20
            default:
                return max(cardWidth / 2 + 24, min(windowSize.width - cardWidth / 2 - 24, windowSize.width * 0.58))
            }
        }()

        let posY: CGFloat = {
            switch step {
            case .sidebarNavigation, .todayFocusSprintTimer:
                return min(max(cardHeight / 2 + 50, targetRect.midY), windowSize.height - cardHeight / 2 - 50)
            default:
                return min(windowSize.height - cardHeight / 2 - 28, windowSize.height * 0.64)
            }
        }()

        VStack(alignment: .leading, spacing: 11) {

            // Top Header Row
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(step.accentColor.opacity(0.20))
                        .frame(width: 34, height: 34)
                    Image(systemName: step.icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(step.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(step.subtitle)
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(step.accentColor)

                        Text("·")
                            .foregroundStyle(Color.white.opacity(0.3))

                        Text("FEATURE \(step.rawValue + 1) OF \(PlutoAppGuideStep.allCases.count)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }

                    Text(step.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                Spacer()

                Button {
                    guideManager.finishTour()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
                .help("Exit Guide")
            }

            Divider().opacity(0.18)

            // High-Density Structured 3-Point Details
            VStack(alignment: .leading, spacing: 8) {
                ForEach(step.detailsList, id: \.header) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(step.accentColor)
                            .frame(width: 14, height: 14)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.header)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(Color.white)

                            Text(item.text)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.75))
                                .lineSpacing(2)
                        }
                    }
                }
            }

            // Shortcut Hint Bar
            HStack(spacing: 6) {
                Image(systemName: "command")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(step.accentColor)

                Text(step.shortcutHint)
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.85))

                Spacer()

                Text("Click anywhere to advance ➔")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.40))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 1))

            Divider().opacity(0.18)

            // Bottom Action Bar: Step Dots, Back, Next / Finish
            HStack(alignment: .center) {

                // Step Dots
                HStack(spacing: 4.5) {
                    ForEach(PlutoAppGuideStep.allCases) { s in
                        Circle()
                            .fill(s == step ? step.accentColor : Color.white.opacity(0.20))
                            .frame(width: s == step ? 7 : 4.5, height: s == step ? 7 : 4.5)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: step)
                            .onTapGesture {
                                guideManager.jumpTo(step: s)
                            }
                    }
                }

                Spacer()

                // Previous Button
                if step.rawValue > 0 {
                    Button {
                        guideManager.previousStep()
                    } label: {
                        Text("← Back")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlutoFastButtonStyle())
                }

                // Next Button
                Button {
                    guideManager.nextStep()
                } label: {
                    HStack(spacing: 4.5) {
                        Text(step.rawValue < PlutoAppGuideStep.allCases.count - 1 ? "Next Feature →" : "Done Exploring ✦")
                            .font(.system(size: 11, weight: .bold))
                        if step.rawValue == PlutoAppGuideStep.allCases.count - 1 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9.5, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(step.accentColor, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlutoFastButtonStyle())
            }
        }
        .padding(15)
        .frame(width: cardWidth)
        .background(
            Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 0.98)),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(step.accentColor.opacity(0.45), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.70), radius: 28, x: 0, y: 14)
        .position(x: posX, y: posY)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: guideManager.currentStep)
    }
}
