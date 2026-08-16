import SwiftUI
import Combine

// MARK: - FocusTimerViewModel

@MainActor
final class FocusTimerViewModel: ObservableObject {

    @Published var secondsElapsed: Int = 0
    @Published var isRunning: Bool = true
    @Published var isMuted: Bool = false
    @Published var showFullTimerCard: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    init() {
        startTimer()
    }

    func startTimer() {
        isRunning = true
        timerPublisher
            .sink { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                self.secondsElapsed += 1
            }
            .store(in: &cancellables)
    }

    func togglePlayPause() {
        isRunning.toggle()
        PlutoSoundEngine.shared.play(.checkmark)
        Haptics.impact(.light)
    }

    func resetTimer() {
        secondsElapsed = 0
        isRunning = false
        PlutoSoundEngine.shared.play(.timerComplete)
        Haptics.impact(.medium)
    }

    var formattedTime: String {
        let hours = secondsElapsed / 3600
        let minutes = (secondsElapsed % 3600) / 60
        let seconds = secondsElapsed % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
