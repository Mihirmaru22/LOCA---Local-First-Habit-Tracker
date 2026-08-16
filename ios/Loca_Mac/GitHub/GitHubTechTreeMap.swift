import SwiftUI
import SwiftData

// MARK: - GitHubTechTreeMap

/// Interactive RPG-style technology & skill tree matrix mapping the engineer's mastery
/// across foundational primitives to cutting-edge AI architectures.
struct GitHubTechTreeMap: View {

    let repos: [GitHubRepoRecord]
    let onSelectRepoName: (String) -> Void

    @State private var selectedBranchFilter: AIDomain? = nil
    @State private var selectedNodeForDetail: TechTreeNode? = nil
    @State private var zoomScale: CGFloat = 1.0

    private var allNodes: [TechTreeNode] {
        TechTreeEvaluationEngine.buildAllNodes(repos: repos)
    }

    private var overallMasteryPercentage: Double {
        TechTreeEvaluationEngine.calculateOverallMastery(nodes: allNodes)
    }

    private var masteredCount: Int {
        allNodes.filter { $0.status == .mastered }.count
    }

    private var inProgressCount: Int {
        allNodes.filter { $0.status == .inProgress }.count
    }

    private var activeBranches: [AIDomain] {
        if let filter = selectedBranchFilter {
            return [filter]
        } else {
            return AIDomain.allCases
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top Tech Tree Mastery HUD
            techTreeHeaderHUD

            Divider()

            // Main Tech Tree Spines Canvas
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: DS.Space.xl) {
                    ForEach(activeBranches) { branch in
                        branchProgressionSpine(branch: branch)
                    }
                }
                .padding(DS.Space.xl)
                .scaleEffect(zoomScale, anchor: .topLeading)
            }
            .background(Color(red: 0.03, green: 0.04, blue: 0.07))
        }
        .popover(item: $selectedNodeForDetail) { node in
            nodeDetailPopover(node: node)
        }
    }

    // MARK: - Top Tech Tree Header HUD

    private var techTreeHeaderHUD: some View {
        HStack(spacing: DS.Space.lg) {

            // Mastery Score Badge
            HStack(spacing: DS.Space.sm) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    Circle()
                        .trim(from: 0, to: overallMasteryPercentage / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan, Color(red: 0.95, green: 0.75, blue: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 40, height: 40)

                    Text("\(Int(overallMasteryPercentage))%")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("AI ENGINEERING MASTERY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("\(masteredCount) Mastered · \(inProgressCount) In Progress")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Divider().frame(height: 24)

            // Branch Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    branchFilterPill(title: "All Branches", icon: "square.grid.2x2", domain: nil)

                    ForEach(AIDomain.allCases) { domain in
                        branchFilterPill(title: domain.rawValue, icon: domain.icon, domain: domain)
                    }
                }
            }

            Spacer()

            // Zoom Controls
            HStack(spacing: 6) {
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        zoomScale = max(0.6, zoomScale - 0.1)
                    }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)

                Text("\(Int(zoomScale * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(width: 36)

                Button {
                    withAnimation(.spring(response: 0.2)) {
                        zoomScale = min(1.4, zoomScale + 0.1)
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface)
    }

    private func branchFilterPill(title: String, icon: String, domain: AIDomain?) -> some View {
        let isSelected = selectedBranchFilter == domain
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedBranchFilter = domain
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

    // MARK: - Branch Progression Spine Column

    private func branchProgressionSpine(branch: AIDomain) -> some View {
        let branchNodes = allNodes.filter { $0.branch == branch }.sorted { $0.tier < $1.tier }

        return VStack(spacing: 0) {

            // Branch Top Pillar Card
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(branch.accentColor.opacity(0.18))
                            .frame(width: 32, height: 32)
                        Image(systemName: branch.icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(branch.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(branch.rawValue.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color.white)
                            .tracking(0.6)
                        Text(branch.tagline)
                            .font(.system(size: 8))
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(DS.Space.md)
            .frame(width: 280)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(branch.accentColor.opacity(0.35), lineWidth: 1))
            .padding(.bottom, 16)

            // Step-by-Step Tier Progression
            ForEach(Array(branchNodes.enumerated()), id: \.offset) { index, node in
                VStack(spacing: 0) {
                    // Node Hexagonal Card
                    techNodeCard(node: node)

                    // Connecting Animated Energy Line (if not last)
                    if index < branchNodes.count - 1 {
                        energyConnectorLine(isUnlocked: node.status != .locked, color: branch.accentColor)
                    }
                }
            }
        }
        .frame(width: 280)
    }

    // MARK: - Tech Node Card

    private func techNodeCard(node: TechTreeNode) -> some View {
        Button {
            selectedNodeForDetail = node
            Haptics.impact(.medium)
        } label: {
            VStack(alignment: .leading, spacing: 8) {

                // Top Header Row
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(node.status.badgeColor.opacity(0.15))
                            .frame(width: 24, height: 24)
                        Image(systemName: node.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(node.status.badgeColor)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(node.tierName.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(node.branch.accentColor)
                            .tracking(0.5)

                        Text(node.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Status Pill
                    Text(node.status.rawValue.uppercased())
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(node.status.badgeColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(node.status.badgeColor.opacity(0.12), in: Capsule())
                }

                // Summary Prose
                Text(node.summary)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(2)

                // Contributing Repos Strip
                if !node.contributingRepos.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(DS.Color.textTertiary)
                        Text(node.contributingRepos.first ?? "")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 4))
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 3)
                        Capsule()
                            .fill(node.status == .mastered ? Color(red: 0.95, green: 0.75, blue: 0.15) : node.branch.accentColor)
                            .frame(width: geo.size.width * CGFloat(node.progress), height: 3)
                    }
                }
                .frame(height: 3)
            }
            .padding(DS.Space.md)
            .background(
                node.status == .locked ? Color.black.opacity(0.4) : DS.Color.surface,
                in: RoundedRectangle(cornerRadius: DS.Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(
                        node.status == .mastered ? Color(red: 0.95, green: 0.75, blue: 0.15).opacity(0.5) : (node.status == .inProgress ? node.branch.accentColor.opacity(0.5) : Color.white.opacity(0.06)),
                        lineWidth: node.status == .mastered ? 1.5 : 1
                    )
            )
            .shadow(color: node.status == .mastered ? node.branch.accentColor.opacity(0.2) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Energy Connector Line

    private func energyConnectorLine(isUnlocked: Bool, color: Color) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<4) { _ in
                Circle()
                    .fill(isUnlocked ? color : Color.white.opacity(0.12))
                    .frame(width: 3, height: 3)
            }
        }
        .frame(height: 24)
    }

    // MARK: - Node Detail Popover

    private func nodeDetailPopover(node: TechTreeNode) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(node.status.badgeColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: node.icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(node.status.badgeColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(node.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(node.tierName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(node.branch.accentColor)
                }

                Spacer()

                Text(node.status.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(node.status.badgeColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(node.status.badgeColor.opacity(0.15), in: Capsule())
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("ARCHITECTURAL CAPABILITY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
                Text(node.capability)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            if !node.contributingRepos.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BACKED BY REPOSITORIES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)

                    ForEach(node.contributingRepos, id: \.self) { repoName in
                        Button {
                            onSelectRepoName(repoName)
                            selectedNodeForDetail = nil
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(node.branch.accentColor)
                                Text(repoName)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            .padding(8)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(DS.Space.lg)
        .frame(width: 360)
        .background(DS.Color.surface)
    }
}
