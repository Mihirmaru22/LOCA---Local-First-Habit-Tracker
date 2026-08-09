import SwiftUI

// MARK: - MacSidebarView

/// Left-column sidebar listing the top-level navigation sections.
///
/// Uses a plain `List` with `.sidebar` style (the macOS-native inset-highlight
/// style) rather than a custom selection cell, so keyboard navigation and
/// focus rings work automatically.
struct MacSidebarView: View {

    @Binding var selection: MacSection?

    var body: some View {
        List(MacSection.allCases, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.systemImage)
                .tag(section)
        }
        .listStyle(.sidebar)
        .navigationTitle("LOCA")
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
