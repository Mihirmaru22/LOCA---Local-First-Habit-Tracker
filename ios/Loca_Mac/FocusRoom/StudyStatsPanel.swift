import SwiftUI
import SwiftData

// MARK: - StudyTimePeriod

enum StudyTimePeriod: String, CaseIterable, Identifiable {
    case today     = "Today"
    case thisWeek  = "This week"
    case thisMonth = "This month"
    case allTime   = "All time"

    var id: String { rawValue }
}

// MARK: - StudyStatsPanel

struct StudyStatsPanel: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [FocusSession]
    @Query private var goals: [FocusGoal]

    @Binding var isPresented: Bool
    @State private var selectedPeriod: StudyTimePeriod = .thisMonth

    // Level System Tiers
    enum StudyLevel {
        case member, entry, scholar, focused, deepWork, flowState, legendary

        var name: String {
            switch self {
            case .member: return "Member (0-10m)"
            case .entry: return "Entry (10m-1h)"
            case .scholar: return "Scholar (1-5h)"
            case .focused: return "Focused (5-20h)"
            case .deepWork: return "Deep Work (20-50h)"
            case .flowState: return "Flow State (50-100h)"
            case .legendary: return "Legendary (100h+)"
            }
        }

        var nextName: String {
            switch self {
            case .member: return "Entry (10m-60m)"
            case .entry: return "Scholar (1h-5h)"
            case .scholar: return "Focused (5h-20h)"
            case .focused: return "Deep Work (20h-50h)"
            case .deepWork: return "Flow State (50h-100h)"
            case .flowState: return "Legendary (100h+)"
            case .legendary: return "Master"
            }
        }

        var thresholdHours: Double {
            switch self {
            case .member: return 0.16
            case .entry: return 1.0
            case .scholar: return 5.0
            case .focused: return 20.0
            case .deepWork: return 50.0
            case .flowState: return 100.0
            case .legendary: return 500.0
            }
        }
    }

    private var totalStudyHours: Double {
        let now = Date()
        let calendar = Calendar.current
        let filtered = sessions.filter { session in
            switch selectedPeriod {
            case .today:
                return calendar.isDateInToday(session.startTime)
            case .thisWeek:
                return calendar.isDate(session.startTime, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth:
                return calendar.isDate(session.startTime, equalTo: now, toGranularity: .month)
            case .allTime:
                return true
            }
        }
        let totalSecs = filtered.reduce(0) { $0 + $1.durationSeconds }
        return Double(totalSecs) / 3600.0
    }

    private var currentLevel: StudyLevel {
        let h = totalStudyHours
        if h < 0.16 { return .member }
        if h < 1.0 { return .entry }
        if h < 5.0 { return .scholar }
        if h < 20.0 { return .focused }
        if h < 50.0 { return .deepWork }
        if h < 100.0 { return .flowState }
        return .legendary
    }

    private var levelProgress: Double {
        let current = totalStudyHours
        let target = currentLevel.thresholdHours
        return min(1.0, max(0.0, current / target))
    }

    private var hoursRemaining: Double {
        max(0.1, currentLevel.thresholdHours - totalStudyHours)
    }

    private var openGoalsCount: Int {
        goals.filter { !$0.isCompleted }.count
    }

    private var completedGoalsCount: Int {
        goals.filter { $0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header + Period Dropdown
            HStack {
                Label("Study stats", systemImage: "chart.bar.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Menu {
                    ForEach(StudyTimePeriod.allCases) { period in
                        Button(period.rawValue) {
                            selectedPeriod = period
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12), in: Capsule())
                    .foregroundStyle(.white)
                }
                .menuStyle(.borderlessButton)

                Button {
                    isPresented = false
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(spacing: 10) {

                    // Card 1 — Study Time
                    statCard {
                        HStack(spacing: 12) {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.white)
                                .frame(width: 42, height: 42)
                                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Study time")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(String(format: "%.1f h", totalStudyHours))
                                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                    }

                    // Card 2 — Level & Progression
                    statCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Current level")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.6))
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.white).frame(width: 6, height: 6)
                                        Text(currentLevel.name)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }

                            // Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.15))
                                    Capsule().fill(Color.blue).frame(width: geo.size.width * CGFloat(levelProgress))
                                }
                            }
                            .frame(height: 6)

                            Text("\(String(format: "%.1f", hoursRemaining)) hours left until: \(currentLevel.nextName)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(red: 0.55, green: 0.65, blue: 0.95))
                        }
                    }

                    // Card 3 — Goals (Open vs Completed)
                    statCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("All goals")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))

                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(openGoalsCount)")
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("Open Goals")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 1, height: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(completedGoalsCount)")
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color.green)
                                    Text("Completed Goals")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .padding(.leading, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // Card 4 — Leaderboard / Global Rank
                    statCard {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.yellow)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Leaderboard rank")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("#30640")
                                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxHeight: 330)
        }
        .padding(16)
        .frame(width: 310)
        .background(
            Color.black.opacity(0.72)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
    }

    private func statCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading) {
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}
