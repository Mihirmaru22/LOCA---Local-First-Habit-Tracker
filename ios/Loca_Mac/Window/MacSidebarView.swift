import SwiftUI

// MARK: - MacSidebarView (100% Apple Liquid Glass Sovereign Sidebar)

/// Master Navigation Sidebar styled with full multi-layer Liquid Glassmorphism,
/// frosted optical depth, dynamic refractive strokes, and ambient pillar accent auras.
struct MacSidebarView: View {

    @Binding var selection: MacSection?
    @State private var hoveredSection: MacSection? = nil

    private let mainSections: [MacSection] = [.today, .notes, .studio, .life]

    var body: some View {
        ZStack(alignment: .trailing) {
            // Full-Height Frosted Liquid Glass Canvas Backing
            VStack(spacing: 0) {

                // Top Workspace Brand Header
                brandHeader
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                Divider()
                    .opacity(0.12)
                    .padding(.horizontal, 10)

                // Main Navigation Items List
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(mainSections) { section in
                            sidebarItemButton(section: section)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }

                Spacer(minLength: 0)

                // Frosted Tray for Settings at the bottom
                VStack(spacing: 8) {
                    Divider()
                        .opacity(0.15)
                        .padding(.horizontal, 8)

                    sidebarItemButton(section: .settings)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 12)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0)),
                        Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Right-hand 1px Optical Refractive Glass Border
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)
        }
        .navigationTitle("PLUTO")
    }

    // MARK: - Top Brand Header

    private var brandHeader: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.85),
                                Color(red: 0.95, green: 0.55, blue: 0.20).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 18, height: 18)
                    .shadow(color: Color.orange.opacity(0.4), radius: 4)

                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("PLUTO")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .tracking(1.2)

                Text("EXECUTIVE OS")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(0.8)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sidebar Item Button (100% Liquid Glass Surface)

    private func sidebarItemButton(section: MacSection) -> some View {
        let isSelected = selection == section
        let isHovered = hoveredSection == section
        let accent = sectionAccentColor(section)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                selection = section
            }
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 11) {
                // Section Icon with Ambient Aura
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accent.opacity(0.20))
                            .frame(width: 24, height: 24)
                            .blur(radius: 2)
                    }

                    Image(systemName: section.systemImage)
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(
                            isSelected
                                ? Color.white
                                : (isHovered ? Color.white : Color.white.opacity(0.65))
                        )
                        .frame(width: 22, height: 22)
                }

                // Section Title
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(
                        isSelected
                            ? Color.white
                            : (isHovered ? Color.white : Color.white.opacity(0.70))
                    )
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer()

                // Active Liquid Glass Pip / Dot
                if isSelected {
                    Circle()
                        .fill(accent)
                        .frame(width: 5.5, height: 5.5)
                        .shadow(color: accent.opacity(0.9), radius: 4)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        // Selected Liquid Glass Gradient Fill
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.16),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: accent.opacity(0.20), radius: 8, x: 0, y: 2)
                    } else if isHovered {
                        // Hover Glass Glow
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : (isHovered ? LinearGradient(colors: [Color.white.opacity(0.14), Color.clear], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered && !isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredSection = hovering ? section : nil
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // MARK: - Section Ambient Accent Palette

    private func sectionAccentColor(_ section: MacSection) -> Color {
        switch section {
        case .today:    return Color(red: 0.95, green: 0.75, blue: 0.25) // Golden Sunrise
        case .notes:    return Color(red: 0.98, green: 0.82, blue: 0.35) // Notes Amber
        case .studio:   return Color(red: 0.75, green: 0.55, blue: 0.95) // Studio Amethyst
        case .life:     return Color(red: 0.35, green: 0.85, blue: 0.65) // Alpine Emerald
        case .settings: return Color(red: 0.80, green: 0.82, blue: 0.88) // Titanium Slate
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        MacSidebarView(selection: .constant(.today))
    } detail: {
        Text("Detail")
    }
}
