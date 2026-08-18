import SwiftUI

// MARK: - BrainStormShortcutCheatSheet (Keyboard Cheat-Sheet HUD)

struct BrainStormShortcutCheatSheet: View {

    @Binding var isPresented: Bool

    private let shortcutCategories: [(title: String, items: [(keys: [String], label: String)])] = [
        ("ORGANIZATION & NAVIGATION", [
            (["⌘", "N"], "New Note"),
            (["⌘", "⇧", "N"], "New Folder"),
            (["⌘", "⌥", "F"], "Search All Notes"),
            (["⌘", "1"], "Show / Hide Folders Sidebar"),
            (["⌘", "2"], "Toggle List / Gallery View")
        ]),
        ("EDITOR & FORMATTING", [
            (["⌘", "B"], "Bold Text"),
            (["⌘", "I"], "Italic Text"),
            (["⌘", "U"], "Underline Text"),
            (["⌘", "⇧", "X"], "Strikethrough Text"),
            (["⌘", "⇧", "C"], "Insert / Toggle Checklist"),
            (["⌘", "T"], "Insert Table"),
            (["⌘", "K"], "Insert Hyperlink"),
            (["⌘", "F"], "Find in Note")
        ]),
        ("FOCUS & SYSTEM", [
            (["⌘", "⌃", "F"], "Zen Distraction-Free Canvas"),
            (["Esc"], "Close Popover / Find Bar / Exit Zen"),
            (["⌘", "/"], "Show Shortcut Cheat-Sheet")
        ])
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "command")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)

                    Text("KEYBOARD SHORTCUTS")
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

            // Categories
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(shortcutCategories, id: \.title) { cat in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(cat.title)
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.45))

                            VStack(spacing: 6) {
                                ForEach(cat.items, id: \.label) { item in
                                    HStack {
                                        Text(item.label)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.white.opacity(0.85))

                                        Spacer()

                                        HStack(spacing: 3) {
                                            ForEach(item.keys, id: \.self) { key in
                                                Text(key)
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .foregroundStyle(Color.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(width: 420, height: 460)
        .background(Color.black.opacity(0.85).background(.ultraThinMaterial))
    }
}
