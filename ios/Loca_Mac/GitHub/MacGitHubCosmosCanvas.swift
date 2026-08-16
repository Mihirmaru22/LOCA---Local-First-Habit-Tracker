import SwiftUI
import SwiftData

// MARK: - GitHubViewMode

enum GitHubViewMode: String, CaseIterable, Identifiable {
    case cosmos    = "AI Cosmos"
    case techTree  = "Tech Tree"
    case directory = "Directory"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cosmos:    return "sparkles.rectangle.stack.fill"
        case .techTree:  return "point.3.connected.trianglepath.dotted"
        case .directory: return "folder.fill"
        }
    }
}

// MARK: - MacGitHubCosmosCanvas

/// The primary top-level visual canvas for Pluto's GitHub & AI Engineering Cosmos.
/// Orchestrates planetary constellations, RPG tech progression trees, and repository inspection.
struct MacGitHubCosmosCanvas: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GitHubRepoRecord.starCount, order: .reverse) private var allRepos: [GitHubRepoRecord]

    @AppStorage("mac_github_view_mode_v1") private var selectedViewMode: GitHubViewMode = .directory
    @StateObject private var syncEngine = GitHubSyncEngine.shared

    @State private var selectedDomainFilter: AIDomain? = nil
    @State private var searchText: String = ""
    @State private var selectedRepo: GitHubRepoRecord? = nil
    @State private var isAuthModalPresented: Bool = false

    private var activeRepos: [GitHubRepoRecord] {
        allRepos.filter { !$0.isArchived }
    }

    private var filteredRepos: [GitHubRepoRecord] {
        activeRepos.filter { repo in
            let matchesSearch = searchText.isEmpty
                || repo.name.localizedCaseInsensitiveContains(searchText)
                || repo.repoDescription.localizedCaseInsensitiveContains(searchText)
                || repo.primaryLanguage.localizedCaseInsensitiveContains(searchText)
                || repo.techStackTags.contains { $0.localizedCaseInsensitiveContains(searchText) }

            guard matchesSearch else { return false }

            if let domain = selectedDomainFilter {
                return repo.domain == domain
            }
            return true
        }
    }

    // Telemetry aggregations
    private var totalStars: Int {
        activeRepos.map(\.starCount).reduce(0, +)
    }

    private var totalCommits: Int {
        activeRepos.map(\.commitCount).reduce(0, +)
    }

    private var totalForks: Int {
        activeRepos.map(\.forkCount).reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top Telemetry & Control Banner
            engineeringTelemetryBanner

            Divider()

            // Main Canvas Body based on View Mode
            GeometryReader { geo in
                layoutBody(geo: geo)
            }
        }
        .sheet(isPresented: $isAuthModalPresented) {
            GitHubAuthModal(syncEngine: syncEngine) {
                Task {
                    await syncEngine.syncRepositories(context: modelContext)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                GitHubSeeder.seedIfNeeded(context: modelContext)
                if selectedRepo == nil {
                    selectedRepo = filteredRepos.first
                }
            }
        }
    }

    // MARK: - Main Layout Switcher

    @ViewBuilder
    private func layoutBody(geo: GeometryProxy) -> some View {
        switch selectedViewMode {
        case .cosmos:
            // Placeholder canvas for Sub-Phase 5.3 (Cosmos & Constellation)
            cosmosPreviewCanvas(geo: geo)
        case .techTree:
            // Placeholder canvas for Sub-Phase 5.4 (RPG Tech Tree)
            techTreePreviewCanvas(geo: geo)
        case .directory:
            // High-Density Codebase Directory Layout
            directorySplitLayout(geo: geo)
        }
    }

    // MARK: - Top Telemetry Banner

    private var engineeringTelemetryBanner: some View {
        HStack(spacing: DS.Space.lg) {

            // Stat 1: AI Systems Tracked
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.cyan)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(activeRepos.count) AI SYSTEMS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Tracked Codebases")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 24)

            // Stat 2: Total GitHub Stars
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.yellow)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(totalStars.formatted()) STARS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Community Traction")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 24)

            // Stat 3: Codebase Velocity
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.purple)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(totalCommits.formatted()) COMMITS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Engineering Velocity")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 24)

            // Sync Button
            Button {
                Task {
                    await syncEngine.syncRepositories(context: modelContext)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: syncEngine.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                        .rotationEffect(.degrees(syncEngine.isSyncing ? 360 : 0))
                        .animation(syncEngine.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: syncEngine.isSyncing)
                    Text(syncEngine.isSyncing ? "Syncing..." : "Sync GitHub")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.cyan)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(syncEngine.isSyncing)

            // Auth Button
            Button {
                isAuthModalPresented = true
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: syncEngine.hasToken ? "key.fill" : "key")
                        .foregroundStyle(syncEngine.hasToken ? Color.green : DS.Color.textSecondary)
                    Text(syncEngine.hasToken ? "PAT Active" : "Connect PAT")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Spacer()

            // View Mode Switcher
            HStack(spacing: 2) {
                ForEach(GitHubViewMode.allCases) { mode in
                    let isSelected = selectedViewMode == mode
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedViewMode = mode
                        }
                        Haptics.impact(.light)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundStyle(isSelected ? Color.white : DS.Color.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
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
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface)
    }

    // MARK: - Directory Split Layout

    private func directorySplitLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {

            // Left: Repo Directory List (380px)
            VStack(spacing: 0) {
                searchAndFilterHeader
                Divider()
                repoListScrollView
            }
            .frame(width: min(380, geo.size.width * 0.38))
            .background(DS.Color.surface)

            Divider()

            // Right: Repo Deep Inspector Canvas
            VStack(spacing: 0) {
                if let repo = selectedRepo {
                    repoDetailInspector(repo: repo)
                } else {
                    VStack(spacing: DS.Space.md) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text("Select a repository to inspect architecture & AI telemetry")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.surfaceRecessed)
        }
    }

    // MARK: - Search & Domain Filter Bar

    private var searchAndFilterHeader: some View {
        VStack(spacing: DS.Space.sm) {
            // Search Input
            HStack(spacing: DS.Space.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.textTertiary)

                TextField("Search AI systems, models, stacks...", text: $searchText)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))

            // Domain Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    domainFilterPill(title: "All Systems", icon: "square.grid.2x2", domain: nil)

                    ForEach(AIDomain.allCases) { domain in
                        domainFilterPill(title: domain.rawValue, icon: domain.icon, domain: domain)
                    }
                }
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface)
    }

    private func domainFilterPill(title: String, icon: String, domain: AIDomain?) -> some View {
        let isSelected = selectedDomainFilter == domain
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedDomainFilter = domain
            }
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? Color.white : DS.Color.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected ? Color(red: 0.38, green: 0.45, blue: 0.98) : DS.Color.surfaceRecessed,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Repo List ScrollView

    private var repoListScrollView: some View {
        ScrollView {
            LazyVStack(spacing: DS.Space.sm) {
                ForEach(filteredRepos) { repo in
                    let isSelected = selectedRepo?.id == repo.id

                    Button {
                        selectedRepo = repo
                        Haptics.impact(.light)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                Image(systemName: repo.domain.icon)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(repo.domain.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(repo.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(DS.Color.textPrimary)
                                        .lineLimit(1)

                                    Text(repo.repoDescription)
                                        .font(DS.Text.caption)
                                        .foregroundStyle(DS.Color.textTertiary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.yellow)
                                    Text(repo.formattedStars)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                            }

                            // Tags strip
                            HStack(spacing: 4) {
                                Text(repo.primaryLanguage)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(repo.domain.accentColor)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(repo.domain.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 3))

                                ForEach(repo.techStackTags.prefix(2), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(DS.Color.textSecondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 3))
                                }

                                Spacer()

                                Text(repo.formattedCommits)
                                    .font(.system(size: 9))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                        }
                        .padding(DS.Space.md)
                        .background(
                            isSelected ? Color.white.opacity(0.08) : DS.Color.surface,
                            in: RoundedRectangle(cornerRadius: DS.Radius.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.card)
                                .stroke(isSelected ? repo.domain.accentColor : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DS.Space.md)
        }
    }

    // MARK: - Repo Detail Inspector

    private func repoDetailInspector(repo: GitHubRepoRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {

                // Top Header Card
                VStack(alignment: .leading, spacing: DS.Space.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(repo.name)
                                    .font(.system(size: 20, weight: .black, design: .serif))
                                    .foregroundStyle(DS.Color.textPrimary)

                                Text(repo.domain.rawValue.uppercased())
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(repo.domain.accentColor)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(repo.domain.accentColor.opacity(0.15), in: Capsule())
                            }

                            Text(repo.repoDescription)
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textSecondary)
                        }

                        Spacer()

                        // Quick Actions
                        HStack(spacing: 8) {
                            if let url = URL(string: repo.htmlURL) {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "safari.fill")
                                        Text("GitHub")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }

                    // Stat Metrics Grid
                    HStack(spacing: DS.Space.md) {
                        statCell(title: "STARS", value: repo.formattedStars, icon: "star.fill", color: Color.yellow)
                        statCell(title: "FORKS", value: "\(repo.forkCount)", icon: "tuningfork", color: Color.cyan)
                        statCell(title: "COMMITS", value: "\(repo.commitCount)", icon: "bolt.fill", color: Color.purple)
                        statCell(title: "LANGUAGE", value: repo.primaryLanguage, icon: "curlybraces", color: repo.domain.accentColor)
                    }
                }
                .padding(DS.Space.lg)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // AI Model Telemetry Section
                if let tel = repo.telemetry {
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.cyan)
                            Text("AI MODEL WEIGHTS & EVALUATION DOSSIER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DS.Color.textSecondary)
                                .tracking(0.6)
                        }

                        HStack(spacing: DS.Space.md) {
                            telemetryPill(title: "BASE ARCHITECTURE", value: tel.baseModelArchitecture, color: Color.cyan)
                            telemetryPill(title: "PARAMETERS", value: tel.parameterSize, color: Color.purple)
                            telemetryPill(title: "QUANTIZATION", value: tel.quantizationFormat, color: Color.orange)
                            telemetryPill(title: "CONTEXT WINDOW", value: tel.formattedContext, color: Color.green)
                        }

                        HStack(spacing: DS.Space.md) {
                            telemetryPill(title: "BENCHMARK ACCURACY", value: tel.benchmarkName, color: Color.yellow)
                            telemetryPill(title: "INFERENCE SPEED", value: tel.formattedThroughput, color: Color.cyan)
                            telemetryPill(title: "TIME TO FIRST TOKEN", value: tel.formattedLatency, color: Color.pink)
                        }

                        // Loss Summary
                        Text(tel.trainingLossSummary)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(DS.Space.lg)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(Color.cyan.opacity(0.25), lineWidth: 1))
                }

                // Tech Stack Tags
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("TECH STACK & DEPENDENCIES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)

                    HStack(spacing: 8) {
                        ForEach(repo.techStackTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DS.Color.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(DS.Space.xl)
        }
    }

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(DS.Color.textTertiary)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }

    private func telemetryPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Placeholder Canvases (Sub-Phases 5.3 & 5.4)

    private func cosmosPreviewCanvas(geo: GeometryProxy) -> some View {
        ZStack(alignment: .trailing) {
            // Main Interstellar Orbital Map Canvas
            GitHubCosmosMapView(
                repos: filteredRepos,
                selectedRepo: selectedRepo,
                onSelectRepo: { repo in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedRepo = repo
                    }
                }
            )

            // Floating Detail Drawer if a repo is selected
            if let repo = selectedRepo {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: repo.domain.icon)
                                .foregroundStyle(repo.domain.accentColor)
                            Text(repo.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedRepo = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, DS.Space.xs)

                    Divider()

                    repoDetailInspector(repo: repo)
                }
                .padding(DS.Space.md)
                .frame(width: 370)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.5), radius: 16)
                .padding(DS.Space.lg)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    private func techTreePreviewCanvas(geo: GeometryProxy) -> some View {
        GitHubTechTreeMap(
            repos: filteredRepos,
            onSelectRepoName: { repoName in
                if let found = allRepos.first(where: { $0.name.localizedCaseInsensitiveContains(repoName) }) {
                    selectedRepo = found
                    selectedViewMode = .directory
                    Haptics.impact(.light)
                }
            }
        )
    }
}

// MARK: - GitHubAuthModal

struct GitHubAuthModal: View {
    @ObservedObject var syncEngine: GitHubSyncEngine
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var usernameInput: String = ""
    @State private var tokenInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(Color.cyan)
                Text("CONNECT GITHUB CREDENTIALS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .tracking(0.6)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Text("Store a Personal Access Token (PAT) securely in macOS Keychain for higher API rate limits and private repo discovery.")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("GITHUB USERNAME")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                TextField("e.g. Mihirmaru22", text: $usernameInput)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("PERSONAL ACCESS TOKEN (OPTIONAL)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $tokenInput)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                if syncEngine.hasToken {
                    Button("Remove Token") {
                        syncEngine.deleteToken()
                        tokenInput = ""
                        Haptics.impact(.medium)
                    }
                    .foregroundStyle(Color.red)
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Save & Sync") {
                    syncEngine.setUsername(usernameInput)
                    if !tokenInput.isEmpty {
                        _ = syncEngine.saveToken(tokenInput)
                    }
                    dismiss()
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(DS.Space.xl)
        .frame(width: 440)
        .background(DS.Color.surface)
        .onAppear {
            usernameInput = syncEngine.customUsername
            if let t = syncEngine.readToken() {
                tokenInput = t
            }
        }
    }
}
