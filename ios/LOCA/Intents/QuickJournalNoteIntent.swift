import AppIntents
import Foundation
import SwiftData
import SwiftUI

// MARK: - QuickJournalNoteIntent (Siri Voice Journal Reflection)

/// Records a quick journal reflection or win directly into Today's Journal via Siri.
///
/// Example Voice Invocations:
/// - "Hey Siri, quick journal in LOCA: Closed the client contract and hit sub-5min pace."
/// - "Hey Siri, log a win in LOCA: Shipped V2.0 on time."
struct QuickJournalNoteIntent: AppIntent {

    static let title: LocalizedStringResource = "Log Journal Note"
    static let description = IntentDescription("Record a daily reflection or win into LOCA's private journal.")

    @Parameter(title: "Reflection or Win")
    var reflectionText: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log '\(\.$reflectionText)' in LOCA Journal")
    }

    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        guard let container = try? ModelContainerFactory.makeConfiguredContainer() else {
            return .result(dialog: "Unable to access LOCA journal.") {
                JournalAddedSnippetView(text: reflectionText)
            }
        }

        let context = ModelContext(container)
        let note = JournalNote(
            date: .now,
            body: reflectionText,
            noteKind: reflectionText.lowercased().contains("win") ? .win : .moment
        )

        context.insert(note)
        try? context.save()

        let dialog = IntentDialog("Recorded your reflection in Today's Journal. Keep compounding!")

        return .result(dialog: dialog) {
            JournalAddedSnippetView(text: reflectionText)
        }
    }
}

struct JournalAddedSnippetView: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Reflection Logged")
                    .font(.system(size: 14, weight: .bold))

                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text("JOURNAL")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.purple)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.purple.opacity(0.12), in: Capsule())
        }
        .padding()
    }
}
