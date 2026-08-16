import SwiftUI
import SwiftData
import Combine
import Foundation

// MARK: - GitHubCosmosMapView

/// Interactive interstellar visual canvas transforming repositories into living planetary bodies
/// orbiting around an AI engineering core hub.
struct GitHubCosmosMapView: View {

    let repos: [GitHubRepoRecord]
    let selectedRepo: GitHubRepoRecord?
    let onSelectRepo: (GitHubRepoRecord) -> Void

    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var hoveredRepo: GitHubRepoRecord? = nil
    @State private var isOrbiting: Bool = true
    @State private var orbitRotation: Double = 0.0

    // Timer for smooth 60fps orbital rotation
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Deep space void background
            deepSpaceBackground

            // Transformable orbital world canvas
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2 + panOffset.width, y: geo.size.height / 2 + panOffset.height)

                ZStack {
                    // 1. Orbital Ring Paths & Domain Titles
                    orbitalRingsView(center: center)

                    // 2. Synapse Constellation Lines
                    synapseBeamsView(center: center)

                    // 3. Central Solar Hub (AI Engineer Core)
                    solarCoreView(center: center)

                    // 4. Planetary Repositories
                    planetsView(center: center)
                }
                .scaleEffect(zoomScale, anchor: .center)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        panOffset = CGSize(
                            width: panOffset.width + value.translation.width * 0.1,
                            height: panOffset.height + value.translation.height * 0.1
                        )
                    }
            )

            // Canvas Controls Overlay (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    // Hover Holographic Telemetry Pill (Bottom Left)
                    if let hovered = hoveredRepo {
                        holographicTelemetryHUD(repo: hovered)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer()

                    // Controls Toolbar
                    cosmosControlsToolbar
                }
                .padding(DS.Space.lg)
            }
        }
        .onReceive(timer) { _ in
            if isOrbiting {
                orbitRotation += 0.12
                if orbitRotation >= 360.0 {
                    orbitRotation = 0.0
                }
            }
        }
    }

    // MARK: - Deep Space Background

    private var deepSpaceBackground: some View {
        ZStack {
            // Rich multi-stop dark interstellar gradient
            RadialGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.15),
                    Color(red: 0.04, green: 0.05, blue: 0.09),
                    Color(red: 0.02, green: 0.03, blue: 0.05)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 650
            )
            .edgesIgnoringSafeArea(.all)

            // Starfield particle grid
            Canvas { context, size in
                var rng = SystemRandomNumberGenerator()
                for _ in 0..<90 {
                    let x = Double.random(in: 0...Double(size.width), using: &rng)
                    let y = Double.random(in: 0...Double(size.height), using: &rng)
                    let r = Double.random(in: 0.8...2.2, using: &rng)
                    let opacity = Double.random(in: 0.2...0.8, using: &rng)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }
            .opacity(0.7)
        }
    }

    // MARK: - Central Solar Core

    private func solarCoreView(center: CGPoint) -> some View {
        ZStack {
            // Corona Solar Flares
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.35),
                            Color.orange.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)

            // Inner Core
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.80, blue: 0.25), Color(red: 0.95, green: 0.45, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                .shadow(color: Color.orange.opacity(0.8), radius: 24)

            VStack(spacing: 1) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.black)
                Text("ENGINEER")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(Color.black)
            }

            // Core Label
            VStack(spacing: 2) {
                Text("AI SYSTEMS NUCLEUS")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.yellow)
                    .tracking(1.0)
                Text("Mihir Maru · Architecture Core")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 0.8))
            .offset(y: 52)
        }
        .position(center)
    }

    // MARK: - 5 Orbital Rings

    private func orbitalRingsView(center: CGPoint) -> some View {
        ForEach(Array(AIDomain.allCases.enumerated()), id: \.offset) { index, domain in
            let radius = domainRadius(for: domain)

            ZStack {
                // Dashed orbit path
                Circle()
                    .stroke(
                        domain.accentColor.opacity(0.25),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 6])
                    )
                    .frame(width: radius * 2, height: radius * 2)

                // Domain Orbit Tag
                Text(domain.rawValue.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(domain.accentColor.opacity(0.6))
                    .tracking(1.0)
                    .offset(y: -radius)
            }
            .position(center)
        }
    }

    // MARK: - Synapse Beams

    private func synapseBeamsView(center: CGPoint) -> some View {
        Path { path in
            let positions = repos.map { repo in
                planetPosition(for: repo, center: center)
            }

            for i in 0..<positions.count {
                for j in (i + 1)..<positions.count {
                    let p1 = positions[i]
                    let p2 = positions[j]
                    let r1 = repos[i]
                    let r2 = repos[j]

                    // Connect if sharing any tech stack tag or domain
                    let shareTag = !Set(r1.techStackTags).isDisjoint(with: Set(r2.techStackTags))
                    if shareTag || r1.domain == r2.domain {
                        path.move(to: p1)
                        let midX = (p1.x + p2.x) / 2
                        let midY = (p1.y + p2.y) / 2
                        path.addQuadCurve(to: p2, control: CGPoint(x: midX + 15, y: midY - 15))
                    }
                }
            }
        }
        .stroke(
            LinearGradient(
                colors: [Color.cyan.opacity(0.2), Color.purple.opacity(0.2), Color.yellow.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )
    }

    // MARK: - Planetary Bodies

    private func planetsView(center: CGPoint) -> some View {
        ForEach(repos) { repo in
            let pos = planetPosition(for: repo, center: center)
            let isSelected = selectedRepo?.id == repo.id
            let isHovered = hoveredRepo?.id == repo.id

            planetBody(repo: repo, isSelected: isSelected, isHovered: isHovered)
                .position(pos)
                .onTapGesture {
                    onSelectRepo(repo)
                    Haptics.impact(.medium)
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        hoveredRepo = hovering ? repo : nil
                    }
                }
        }
    }

    private func planetBody(repo: GitHubRepoRecord, isSelected: Bool, isHovered: Bool) -> some View {
        let diameter: CGFloat = max(44, min(68, CGFloat(40 + repo.starCount / 100)))

        return VStack(spacing: 6) {
            ZStack {
                // Glow Halo
                Circle()
                    .fill(repo.domain.accentColor.opacity(isSelected || isHovered ? 0.45 : 0.18))
                    .frame(width: diameter + 20, height: diameter + 20)

                // Atmospheric Ring for pinned/major repos
                if repo.isPinned || repo.starCount > 2000 {
                    Ellipse()
                        .stroke(repo.domain.accentColor.opacity(0.7), lineWidth: 1.5)
                        .frame(width: diameter + 26, height: diameter * 0.45)
                        .rotationEffect(.degrees(-25))
                }

                // Planet Celestial Sphere
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                repo.domain.accentColor.opacity(0.95),
                                repo.domain.accentColor.opacity(0.6),
                                Color(red: 0.05, green: 0.08, blue: 0.14)
                            ],
                            center: .topLeading,
                            startRadius: 5,
                            endRadius: diameter * 0.8
                        )
                    )
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: repo.domain.accentColor.opacity(0.8), radius: isSelected ? 16 : 8)

                // Domain Icon on Planet Surface
                Image(systemName: repo.domain.icon)
                    .font(.system(size: diameter * 0.35, weight: .bold))
                    .foregroundStyle(Color.white)

                // Orbiting Moon (Release / Benchmark Satellite)
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.cyan, lineWidth: 1))
                    .offset(x: diameter * 0.65, y: -diameter * 0.3)
            }

            // Planet Label Capsule
            VStack(spacing: 2) {
                Text(repo.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(repo.primaryLanguage)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(repo.domain.accentColor)

                    Text("•")
                        .font(.system(size: 8))
                        .foregroundStyle(DS.Color.textTertiary)

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(Color.yellow)
                        Text(repo.formattedStars)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isSelected ? repo.domain.accentColor.opacity(0.3) : Color.black.opacity(0.7),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? repo.domain.accentColor : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    // MARK: - Holographic Telemetry HUD (Hover State)

    private func holographicTelemetryHUD(repo: GitHubRepoRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(repo.domain.accentColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: repo.domain.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(repo.domain.accentColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(repo.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text(repo.domain.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(repo.domain.accentColor)
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.yellow)
                    Text(repo.formattedStars)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)
                }
            }

            Text(repo.repoDescription)
                .font(.system(size: 10))
                .foregroundStyle(DS.Color.textSecondary)
                .lineLimit(2)

            if let tel = repo.telemetry {
                Divider().overlay(Color.white.opacity(0.1))

                HStack(spacing: 12) {
                    hudStat(title: "MODEL", value: tel.baseModelArchitecture, color: Color.cyan)
                    hudStat(title: "ACCURACY", value: tel.benchmarkName, color: Color.yellow)
                    hudStat(title: "LATENCY", value: tel.formattedLatency, color: Color.pink)
                }
            }
        }
        .padding(DS.Space.md)
        .frame(width: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(repo.domain.accentColor.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 16)
    }

    private func hudStat(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    // MARK: - Cosmos Controls Toolbar

    private var cosmosControlsToolbar: some View {
        HStack(spacing: 8) {
            // Orbit Animation Toggle
            Button {
                withAnimation(.spring(response: 0.2)) {
                    isOrbiting.toggle()
                }
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isOrbiting ? "pause.fill" : "play.fill")
                        .font(.system(size: 10))
                    Text(isOrbiting ? "Orbit Active" : "Orbit Paused")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(isOrbiting ? Color.cyan : DS.Color.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(isOrbiting ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Divider().frame(height: 16)

            // Zoom Out
            Button {
                withAnimation(.spring(response: 0.2)) {
                    zoomScale = max(0.5, zoomScale - 0.15)
                }
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)

            Text("\(Int(zoomScale * 100))%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 38)

            // Zoom In
            Button {
                withAnimation(.spring(response: 0.2)) {
                    zoomScale = min(1.8, zoomScale + 0.15)
                }
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)

            // Recenter
            Button("Center") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    zoomScale = 1.0
                    panOffset = .zero
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Orbital Math Helpers

    private func domainRadius(for domain: AIDomain) -> CGFloat {
        switch domain {
        case .autonomousAgents: return 130
        case .llmReasoning:     return 200
        case .visionMultimodal: return 270
        case .mlopsKernels:     return 340
        case .localFirstClient: return 410
        }
    }

    private func planetPosition(for repo: GitHubRepoRecord, center: CGPoint) -> CGPoint {
        let r = domainRadius(for: repo.domain)
        let domainRepos = repos.filter { $0.domain == repo.domain }
        let index = domainRepos.firstIndex(where: { $0.id == repo.id }) ?? 0
        let totalInDomain = max(1, domainRepos.count)

        let baseAngle = (Double(index) / Double(totalInDomain)) * (2.0 * .pi)
        let speedFactor = 1.0 / (Double(domainRadius(for: repo.domain)) / 100.0)
        let dynamicRotation = (orbitRotation * speedFactor) * (.pi / 180.0)
        let finalAngle = baseAngle + dynamicRotation

        let x = center.x + CGFloat(cos(finalAngle)) * r
        let y = center.y + CGFloat(sin(finalAngle)) * r

        return CGPoint(x: x, y: y)
    }
}
