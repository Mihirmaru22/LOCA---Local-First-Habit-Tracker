import SwiftUI

// MARK: - JournalMode   (J1)

/// The two modes of the Mac Journal section.
///
/// - **collect**: Write today's note; browse past daily notes and habit check-in notes.
/// - **analyse**: See the weekly habit digest, cross-habit daily grid, and a reflection.
enum JournalMode: String, CaseIterable, Identifiable {
    case collect = "Collect"
    case analyse = "Analyse"
    var id: String { rawValue }
}

// MARK: - MacJournalContentColumn   (J1)

/// Middle column for the Journal sidebar section.
///
/// A segmented `Picker` at the top switches between Collect and Analyse modes.
/// Each mode renders a distinct view beneath the picker:
/// - Collect → `MacJournalCollect` (J2)
/// - Analyse → `MacJournalAnalyse` (J3 + J6)
///
/// `selectedNote` is threaded up to `MacRootView` so the detail column
/// (`MacJournalDetailColumn`, J5) shows the chosen note.
struct MacJournalContentColumn: View {

    @Binding var selectedNote: JournalNote?
    @State private var mode: JournalMode = .collect

    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle (J1)
            Picker("Mode", selection: $mode) {
                ForEach(JournalMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)

            Divider()

            // Mode content
            switch mode {
            case .collect:
                MacJournalCollect(selectedNote: $selectedNote)
            case .analyse:
                MacJournalAnalyse()
            }
        }
        .navigationTitle("Journal")
    }
}
