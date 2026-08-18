import SwiftUI

// MARK: - BrainStormSettingsView (Preferences Panel for BrainStorm)

struct BrainStormSettingsView: View {

    @Binding var isPresented: Bool

    // Device-Local Preferences (Never synced, zero conflict)
    @AppStorage("brainstorm_default_font") private var defaultFont: String = "system"
    @AppStorage("brainstorm_default_style") private var defaultStyle: String = "title"
    @AppStorage("brainstorm_start_with_title") private var startWithTitle: Bool = true
    @AppStorage("brainstorm_checklist_auto_bottom") private var autoMoveCheckedToBottom: Bool = false
    @AppStorage("brainstorm_auto_lock_interval") private var autoLockInterval: String = "15m"
    @AppStorage("brainstorm_word_count_visible") private var wordCountVisible: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)

                    Text("BRAINSTORM PREFERENCES")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.white)
                }

                Spacer()

                Button {
                    isPresented = false
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.2)

            // Settings Sections
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // 1. TYPOGRAPHY & STYLES SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TYPOGRAPHY & NEW NOTES")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))

                        // Default Font Design
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Default Font Design")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Text("Applies to Body text in new notes")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                            Spacer()

                            Picker("", selection: $defaultFont) {
                                Text("San Francisco (System)").tag("system")
                                Text("New York (Serif)").tag("serif")
                                Text("SF Mono (Monospaced)").tag("monospaced")
                            }
                            .frame(width: 170)
                        }

                        // New Notes Start With Title
                        Toggle(isOn: $startWithTitle) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New notes start with Title")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Text("First typed line automatically formats as Title")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

                    // 2. CHECKLIST BEHAVIOR SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CHECKLIST BEHAVIOR")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))

                        Toggle(isOn: $autoMoveCheckedToBottom) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Automatically sort checked items to bottom")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Text("Completed checklist rows animate to the end of the list")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

                    // 3. PRIVACY & AUTO-LOCK SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PRIVACY & SECURITY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Lock Inactivity Timer")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Text("Flushes memory journal before locking")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                            Spacer()

                            Picker("", selection: $autoLockInterval) {
                                Text("Immediately").tag("0m")
                                Text("1 minute").tag("1m")
                                Text("15 minutes").tag("15m")
                                Text("1 hour").tag("60m")
                                Text("Never").tag("never")
                            }
                            .frame(width: 140)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

                    // 4. TELEMETRY & HUD SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        Text("VIEW & TELEMETRY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))

                        Toggle(isOn: $wordCountVisible) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show live Word & Character Count HUD")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Text("Displays word and character metrics at the bottom of the editor")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))

                    // Reset Button
                    Button {
                        defaultFont = "system"
                        defaultStyle = "title"
                        startWithTitle = true
                        autoMoveCheckedToBottom = false
                        autoLockInterval = "15m"
                        wordCountVisible = true
                        Haptics.impact(.medium)
                    } label: {
                        Text("Restore Default Preferences")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .frame(width: 440, height: 490)
        .background(Color.black.opacity(0.85).background(.ultraThinMaterial))
    }
}
