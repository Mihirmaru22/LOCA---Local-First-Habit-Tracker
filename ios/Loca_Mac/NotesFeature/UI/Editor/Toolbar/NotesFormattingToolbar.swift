import SwiftUI

/// Floating or pinned rich-text formatting bar for block conversion and text styling.
public struct NotesFormattingToolbar: View {
    
    public let onSetBlockType: (String, [String: String]) -> Void
    public let onToggleChecklist: () -> Void
    
    public init(
        onSetBlockType: @escaping (String, [String: String]) -> Void,
        onToggleChecklist: @escaping () -> Void
    ) {
        self.onSetBlockType = onSetBlockType
        self.onToggleChecklist = onToggleChecklist
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            // Headings group
            Button("H1") {
                onSetBlockType("heading", ["level": "1"])
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .help("Heading 1")
            
            Button("H2") {
                onSetBlockType("heading", ["level": "2"])
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .help("Heading 2")
            
            Button("H3") {
                onSetBlockType("heading", ["level": "3"])
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .help("Heading 3")
            
            Divider()
                .frame(height: 14)
                .padding(.horizontal, 2)
            
            // Lists group
            Button {
                onSetBlockType("checklistItem", ["isChecked": "false"])
            } label: {
                Image(systemName: "checklist")
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .help("Checklist")
            
            Button {
                onSetBlockType("bullet", [:])
            } label: {
                Image(systemName: "list.bullet")
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .help("Bullet List")
            
            Button {
                onSetBlockType("paragraph", [:])
            } label: {
                Image(systemName: "paragraph")
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .help("Normal Body Text")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

private struct ToolbarIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(configuration.isPressed ? Color.accentColor : Color.primary)
            .frame(minWidth: 26, minHeight: 22)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
