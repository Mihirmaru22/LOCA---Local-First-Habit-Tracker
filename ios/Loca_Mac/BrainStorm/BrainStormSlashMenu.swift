import SwiftUI
import AppKit

// MARK: - SlashCommandItem

public struct SlashCommandItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: String
    public let category: String
    public let action: () -> Void

    public init(id: String, title: String, subtitle: String, icon: String, category: String, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.action = action
    }
}

// MARK: - BrainStormSlashMenu (Floating Quick Inserter Palette)

public struct BrainStormSlashMenu: View {
    let items: [SlashCommandItem]
    let onDismiss: () -> Void

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0

    private var filteredItems: [SlashCommandItem] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return items
        }
        let q = query.lowercased()
        return items.filter {
            $0.title.lowercased().contains(q) ||
            $0.subtitle.lowercased().contains(q) ||
            $0.id.lowercased().contains(q)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Search Input
            HStack(spacing: 8) {
                Image(systemName: "slash.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Theme.amber)

                TextField("Type a command...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.white)
                    .onSubmit {
                        executeSelected()
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(DS.Theme.surface)

            Divider().opacity(0.15)

            // Commands List
            ScrollView {
                VStack(spacing: 2) {
                    if filteredItems.isEmpty {
                        HStack {
                            Text("No commands matching \"\(query)\"")
                                .font(.system(size: 11.5))
                                .foregroundStyle(DS.Theme.textTertiary)
                            Spacer()
                        }
                        .padding(12)
                    } else {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            let isSelected = index == selectedIndex
                            Button {
                                item.action()
                                onDismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(isSelected ? DS.Theme.amber : DS.Theme.textSecondary)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.title)
                                            .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                                            .foregroundStyle(isSelected ? Color.white : DS.Theme.textPrimary)

                                        Text(item.subtitle)
                                            .font(.system(size: 10))
                                            .foregroundStyle(DS.Theme.textTertiary)
                                    }

                                    Spacer()

                                    Text(item.category)
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundStyle(DS.Theme.textTertiary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 3))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected ? Color.white.opacity(0.10) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 280)
        }
        .frame(width: 320)
        .background(DS.Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(DS.Theme.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 8)
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredItems.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private func executeSelected() {
        guard !filteredItems.isEmpty, selectedIndex < filteredItems.count else { return }
        filteredItems[selectedIndex].action()
        onDismiss()
    }
}
