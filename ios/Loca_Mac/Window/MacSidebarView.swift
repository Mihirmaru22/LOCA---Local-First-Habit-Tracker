import SwiftUI

// MARK: - MacSidebarView

/// Left-column sidebar listing top-level navigation sections with increased size and comfortable spacing.
struct MacSidebarView: View {

    @Binding var selection: MacSection?
    @State private var hoveredSection: MacSection? = nil

    private let mainSections: [MacSection] = [.today, .work, .journal, .life]

    var body: some View {
        VStack(spacing: 0) {

            // Main Navigation Items List with Increased Size & Spacious Layout
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(mainSections) { section in
                        sidebarItemButton(section: section)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }

            Spacer()

            Divider()

            // Pinned Settings Row at the very bottom
            sidebarItemButton(section: .settings)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
        }
        .navigationTitle("PLUTO")
    }

    private func sidebarItemButton(section: MacSection) -> some View {
        let isSelected = selection == section
        let isHovered = hoveredSection == section

        return Button {
            selection = section
            PlutoTelemetryEngine.shared.trackScreenView(screenName: section.rawValue)
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : DS.Color.textSecondary))
                    .frame(width: 22, height: 22)

                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : DS.Color.textSecondary))

                Spacer()

                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 5, height: 5)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color.white.opacity(0.12)
                    : (isHovered ? Color.white.opacity(0.05) : Color.clear),
                in: RoundedRectangle(cornerRadius: 7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isSelected ? Color.white.opacity(0.18) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
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
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        MacSidebarView(selection: .constant(.habits))
    } detail: {
        Text("Detail")
    }
}
