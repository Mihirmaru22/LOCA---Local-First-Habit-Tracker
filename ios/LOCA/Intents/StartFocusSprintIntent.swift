import AppIntents
import Foundation
import SwiftData

// MARK: - StartFocusSprintIntent (Siri Voice Command)

/// Starts a Focus Sprint or Pomodoro timer with 3D Spatial ambient focus audio via Siri.
///
/// Example Voice Invocations:
/// - "Hey Siri, start a focus sprint in LOCA"
/// - "Hey Siri, start a 25 minute focus session in LOCA"
struct StartFocusSprintIntent: AppIntent {

    static let title: LocalizedStringResource = "Start Focus Sprint"
    static let description = IntentDescription("Start a Pomodoro or deep work focus sprint in LOCA with ambient focus audio.")

    @Parameter(title: "Duration (Minutes)", default: 25)
    var durationMinutes: Int

    @Parameter(title: "Soundscape", default: "Lo-Fi Focus Chords")
    var soundscape: String

    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$durationMinutes) minute focus sprint with \(\.$soundscape)")
    }

    func perform() async throws -> some ProvidesDialog & ShowsSnippetView {
        let mins = max(5, min(durationMinutes, 180))

        // Trigger notification so app can start timer & audio if open
        NotificationCenter.default.post(
            name: NSNotification.Name("LocaStartFocusSprintNotification"),
            object: nil,
            userInfo: ["duration": mins, "sound": soundscape]
        )

        let dialog = IntentDialog("Starting your \(mins)-minute focus sprint with \(soundscape) in PLUTO. Lock in and enter flow state.")

        return .result(dialog: dialog) {
            FocusSprintSnippetView(minutes: mins, soundscape: soundscape)
        }
    }
}

import SwiftUI

struct FocusSprintSnippetView: View {
    let minutes: Int
    let soundscape: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(minutes)m Focus Sprint Active")
                    .font(.system(size: 14, weight: .bold))
                Text(soundscape)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("FLOW STATE")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.15), in: Capsule())
        }
        .padding()
    }
}
