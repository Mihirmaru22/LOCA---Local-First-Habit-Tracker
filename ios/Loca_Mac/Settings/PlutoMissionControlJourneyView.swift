import SwiftUI

// MARK: - PlutoMissionControlJourneyView (Demo 4: Mission Control Launch Telemetry HUD)

/// High-density cyber-executive command cockpit showcasing the evolutionary trajectory of PLUTO OS
/// from v1.0 Genesis to v5.0 Sovereign OS with real-time telemetry gauges, interactive scrubbers,
/// and subsystem diagnostic monitors.
struct PlutoMissionControlJourneyView: View {

    @State private var scrubbedEraIndex: Double = 4.0 // 0 to 4 (Default v5.0)
    @State private var isSimulatingTelemetry = false
    @State private var telemetryLatencyMs: Double = 0.18

    struct SubsystemTelemetry {
        let version: String
        let codename: String
        let status: String
        let latency: String
        let cloudExposure: String
        let pillarCount: Int
        let accent: Color
        let coreSubsystem: String
        let architecturalBlueprint: [String]
        let sensorTelemetry: [(label: String, value: String, unit: String)]
    }

    private let subsystemTelemetryData: [SubsystemTelemetry] = [
        SubsystemTelemetry(
            version: "v1.0",
            codename: "GENESIS-CORE",
            status: "OFFLINE IMMUTABLE",
            latency: "0.22 ms",
            cloudExposure: "0.00% (Air-Gapped)",
            pillarCount: 1,
            accent: Color(red: 0.95, green: 0.77, blue: 0.25),
            coreSubsystem: "SwiftData Single-Table SQLite Engine",
            architecturalBlueprint: [
                "Single-table SwiftData schema with cached scalar streaks",
                "O(1) incremental write hooks bypassing full historical walks",
                "Pure local file persistence with zero network socket allocation"
            ],
            sensorTelemetry: [
                (label: "DB LATENCY", value: "0.22", unit: "ms"),
                (label: "CLOUD PACKETS", value: "0", unit: "pkts"),
                (label: "LOCAL MEMORY", value: "14.2", unit: "MB")
            ]
        ),
        SubsystemTelemetry(
            version: "v2.0",
            codename: "TACTICAL-MATRIX",
            status: "HIGH VELOCITY",
            latency: "0.19 ms",
            cloudExposure: "0.00% (Air-Gapped)",
            pillarCount: 2,
            accent: Color(red: 0.85, green: 0.40, blue: 0.40),
            coreSubsystem: "Eisenhower Decision Engine & Pomodoro Flow",
            architecturalBlueprint: [
                "4-Quadrant visual matrix with instant priority routing",
                "High-precision 25m Pomodoro sprint countdown loop",
                "Global system-wide HUD capture trigger (⌥ + Space)"
            ],
            sensorTelemetry: [
                (label: "SPRINT DURATION", value: "25", unit: "min"),
                (label: "HOTKEY VELOCITY", value: "< 12", unit: "ms"),
                (label: "TRIAGE QUEUE", value: "100", unit: "%")
            ]
        ),
        SubsystemTelemetry(
            version: "v3.0",
            codename: "SANCTUM-VAULT",
            status: "BIOMETRIC ENCRYPTED",
            latency: "0.18 ms",
            cloudExposure: "0.00% (Air-Gapped)",
            pillarCount: 3,
            accent: Color(red: 0.75, green: 0.55, blue: 0.95),
            coreSubsystem: "Apple Secure Enclave Hardware Auth Lock",
            architecturalBlueprint: [
                "Hardware Touch ID / Face ID biometric gatekeeper",
                "Local AES-256 encryption over private reflections",
                "Automatic lock trigger on app background resign and sleep"
            ],
            sensorTelemetry: [
                (label: "SECURITY CHIP", value: "T2/M-SERIES", unit: ""),
                (label: "ENCRYPTION", value: "AES-256", unit: "bit"),
                (label: "AUTO-LOCK", value: "300", unit: "sec")
            ]
        ),
        SubsystemTelemetry(
            version: "v4.0",
            codename: "ALPINE-ODYSSEY",
            status: "TOPOGRAPHIC 3D",
            latency: "0.16 ms",
            cloudExposure: "0.00% (Air-Gapped)",
            pillarCount: 4,
            accent: Color(red: 0.30, green: 0.85, blue: 0.80),
            coreSubsystem: "3D MapKit Topographic Elevation Engine",
            architecturalBlueprint: [
                "High-resolution 3D MapKit topographic terrain mesh",
                "GPS altitude telemetry & 7-tier Mountaineer Rank engine",
                "Gold-embossed digital expedition passport generator"
            ],
            sensorTelemetry: [
                (label: "MAX ELEVATION", value: "6,816", unit: "m"),
                (label: "EXPEDITIONS", value: "6", unit: "summits"),
                (label: "MAPKIT FPS", value: "60", unit: "fps")
            ]
        ),
        SubsystemTelemetry(
            version: "v5.0",
            codename: "SOVEREIGN-MONOLITH",
            status: "EXECUTIVE 4-PILLARS",
            latency: "0.14 ms",
            cloudExposure: "0.00% (Air-Gapped)",
            pillarCount: 4,
            accent: Color(red: 0.95, green: 0.80, blue: 0.30),
            coreSubsystem: "4-Pillar Executive OS & Native Acoustic Audio",
            architecturalBlueprint: [
                "1-Click Direct Teleportation across ⌘1 Today, ⌘2 Work, ⌘3 Journal, ⌘4 Life",
                "Native acoustic mechanical sound engine with tactile trackpad haptics",
                "Bento Grid Horizon System Settings with instant live control dials"
            ],
            sensorTelemetry: [
                (label: "EXECUTIVE PILLARS", value: "4", unit: "pillars"),
                (label: "AUDIO SYNTH", value: "44.1", unit: "kHz"),
                (label: "CLICK FRICTION", value: "1", unit: "click")
            ]
        )
    ]

    private var currentTelemetry: SubsystemTelemetry {
        let index = Int(scrubbedEraIndex.rounded())
        let clamped = max(0, min(subsystemTelemetryData.count - 1, index))
        return subsystemTelemetryData[clamped]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Mission Control HUD Top Bar
                missionControlTopBar

                // Central Radar & Telemetry Cockpit
                HStack(alignment: .top, spacing: 16) {

                    // Left Column: Subsystem Architecture Dossier
                    leftSubsystemDossierCard
                        .frame(maxWidth: .infinity)

                    // Right Column: Live Telemetry Matrix Gauges
                    rightTelemetryGaugesCard
                        .frame(width: 320)
                }

                // Interactive Chrono-Scrubber Wheel
                interactiveChronoScrubber

                Spacer(minLength: 40)
            }
            .padding(28)
            .frame(maxWidth: 960)
        }
    }

    // MARK: - Top Bar
    private var missionControlTopBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(currentTelemetry.accent)
                .frame(width: 10, height: 10)
                .shadow(color: currentTelemetry.accent.opacity(0.8), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("MISSION CONTROL TELEMETRY HUD")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(currentTelemetry.status)
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(currentTelemetry.accent.opacity(0.2))
                        .foregroundStyle(currentTelemetry.accent)
                        .clipShape(Capsule())
                }

                Text("System Evolution Diagnostic Telemetry (v1.0 ➔ v5.0)")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            // Live Pulse
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 12))
                    .foregroundStyle(currentTelemetry.accent)
                Text("AIR-GAPPED 100%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(currentTelemetry.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.11))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(currentTelemetry.accent.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: - Left Dossier Card
    private var leftSubsystemDossierCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SUBSYSTEM ARCHITECTURE SPECIFICATION")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)

                Spacer()

                Text(currentTelemetry.version)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(currentTelemetry.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(currentTelemetry.coreSubsystem)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)

            Divider()

            Text("ENGINEERING BLUEPRINT SPECIFICATIONS:")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(currentTelemetry.accent)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(currentTelemetry.architecturalBlueprint, id: \.self) { spec in
                    HStack(alignment: .top, spacing: 8) {
                        Text("▶")
                            .font(.system(size: 9))
                            .foregroundStyle(currentTelemetry.accent)
                            .padding(.top, 2)
                        Text(spec)
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))

            Spacer()

            // Diagnostics Button
            Button {
                PlutoSoundEngine.shared.play(.checkmark)
                Haptics.impact(.rigid)
            } label: {
                HStack {
                    Image(systemName: "cpu")
                    Text("Simulate Subsystem Diagnostic Ping")
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(currentTelemetry.accent.opacity(0.15))
                .foregroundStyle(currentTelemetry.accent)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.11))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(currentTelemetry.accent.opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - Right Telemetry Gauges Card
    private var rightTelemetryGaugesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LIVE TELEMETRY SENSORS")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: 10) {
                ForEach(currentTelemetry.sensorTelemetry, id: \.label) { sensor in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sensor.label)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(DS.Color.textTertiary)
                            Text(sensor.value)
                                .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                .foregroundStyle(currentTelemetry.accent)
                        }

                        Spacer()

                        if !sensor.unit.isEmpty {
                            Text(sensor.unit)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(DS.Color.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("CLOUD EXPOSURE:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
                Text(currentTelemetry.cloudExposure)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
            }
            .padding(8)
            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.11))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(currentTelemetry.accent.opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - Interactive Chrono-Scrubber
    private var interactiveChronoScrubber: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("INTERACTIVE EVOLUTIONARY SCRUBBER")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)

                Spacer()

                Text("CURRENT TARGET: \(currentTelemetry.version) (\(currentTelemetry.codename))")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(currentTelemetry.accent)
            }

            // Slider
            Slider(value: $scrubbedEraIndex, in: 0...4, step: 1.0) {
                Text("Era")
            }
            .tint(currentTelemetry.accent)
            .onChange(of: scrubbedEraIndex) { _, _ in
                PlutoSoundEngine.shared.play(.checkmark)
                Haptics.impact(.light)
            }

            // Version Notch Labels
            HStack {
                ForEach(0..<subsystemTelemetryData.count, id: \.self) { idx in
                    let era = subsystemTelemetryData[idx]
                    let isSelected = Int(scrubbedEraIndex.rounded()) == idx

                    Button {
                        scrubbedEraIndex = Double(idx)
                        PlutoSoundEngine.shared.play(.checkmark)
                        Haptics.impact(.medium)
                    } label: {
                        VStack(spacing: 2) {
                            Text(era.version)
                                .font(.system(size: 11, weight: isSelected ? .heavy : .medium, design: .monospaced))
                                .foregroundStyle(isSelected ? era.accent : DS.Color.textTertiary)
                            Text(era.codename)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? DS.Color.textPrimary : DS.Color.textTertiary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)

                    if idx < subsystemTelemetryData.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.11))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Color.border.opacity(0.6), lineWidth: 1))
        )
    }
}
