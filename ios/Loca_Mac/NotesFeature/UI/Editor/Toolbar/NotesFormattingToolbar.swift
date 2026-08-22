import SwiftUI

/// Stateful rich-text formatting bar for inline styling and block conversion with visual ON states.
public struct NotesFormattingToolbar: View {
    
    public let state: FormattingState
    public let onToggleBold: () -> Void
    public let onToggleItalic: () -> Void
    public let onToggleBlockType: (EditorBlockType) -> Void
    
    public init(
        state: FormattingState,
        onToggleBold: @escaping () -> Void,
        onToggleItalic: @escaping () -> Void,
        onToggleBlockType: @escaping (EditorBlockType) -> Void
    ) {
        self.state = state
        self.onToggleBold = onToggleBold
        self.onToggleItalic = onToggleItalic
        self.onToggleBlockType = onToggleBlockType
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            // Inline marks group (Combine with each other and with any block type)
            toolbarButton(
                title: "B",
                icon: nil,
                isActive: state.isBold,
                help: "Bold (⌘B)",
                isBoldFont: true,
                action: {
                    print("🎨 TOOLBAR CLICK: B")
                    DispatchQueue.main.async {
                        onToggleBold()
                    }
                }
            )
            
            toolbarButton(
                title: "I",
                icon: nil,
                isActive: state.isItalic,
                help: "Italic (⌘I)",
                isItalicFont: true,
                action: {
                    print("🎨 TOOLBAR CLICK: I")
                    DispatchQueue.main.async {
                        onToggleItalic()
                    }
                }
            )
            
            Divider()
                .frame(height: 14)
                .padding(.horizontal, 2)
            
            // Exclusive Headings Group
            toolbarButton(
                title: "H1",
                icon: nil,
                isActive: state.blockType == .h1,
                help: "Heading 1",
                action: {
                    print("🎨 TOOLBAR CLICK: H1")
                    DispatchQueue.main.async {
                        onToggleBlockType(.h1)
                    }
                }
            )
            
            toolbarButton(
                title: "H2",
                icon: nil,
                isActive: state.blockType == .h2,
                help: "Heading 2",
                action: {
                    print("🎨 TOOLBAR CLICK: H2")
                    DispatchQueue.main.async {
                        onToggleBlockType(.h2)
                    }
                }
            )
            
            toolbarButton(
                title: "H3",
                icon: nil,
                isActive: state.blockType == .h3,
                help: "Heading 3",
                action: {
                    print("🎨 TOOLBAR CLICK: H3")
                    DispatchQueue.main.async {
                        onToggleBlockType(.h3)
                    }
                }
            )
            
            Divider()
                .frame(height: 14)
                .padding(.horizontal, 2)
            
            // Lists & Paragraph Group
            toolbarButton(
                title: nil,
                icon: "checklist",
                isActive: state.blockType == .checklist,
                help: "Checklist",
                action: {
                    print("🎨 TOOLBAR CLICK: checklist")
                    DispatchQueue.main.async {
                        onToggleBlockType(.checklist)
                    }
                }
            )
            
            toolbarButton(
                title: nil,
                icon: "list.bullet",
                isActive: state.blockType == .bullet,
                help: "Bullet List",
                action: {
                    print("🎨 TOOLBAR CLICK: bullet")
                    DispatchQueue.main.async {
                        onToggleBlockType(.bullet)
                    }
                }
            )
            
            toolbarButton(
                title: nil,
                icon: "paragraph",
                isActive: state.blockType == .paragraph,
                help: "Normal Paragraph",
                action: {
                    print("🎨 TOOLBAR CLICK: paragraph")
                    DispatchQueue.main.async {
                        onToggleBlockType(.paragraph)
                    }
                }
            )
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func toolbarButton(
        title: String?,
        icon: String?,
        isActive: Bool,
        help: String,
        isBoldFont: Bool = false,
        isItalicFont: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let title = title {
                    Text(title)
                        .fontWeight(isBoldFont ? .bold : (isActive ? .semibold : .medium))
                        .italic(isItalicFont)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: isActive ? .bold : .regular))
                }
            }
            .font(.system(size: 11, design: .rounded))
            .frame(minWidth: 26, minHeight: 22)
            .background(Capsule().fill(isActive ? Color.accentColor.opacity(0.28) : Color.clear))
            .overlay(Capsule().strokeBorder(isActive ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1))
            .foregroundStyle(isActive ? Color.primary : Color.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityValue(isActive ? "on" : "off")
        .animation(.easeOut(duration: 0.12), value: isActive)
    }
}
