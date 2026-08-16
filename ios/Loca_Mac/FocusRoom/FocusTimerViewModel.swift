import SwiftUI
import Combine

// MARK: - FocusTimerViewModel (Wall-Clock Precision Focus Sprint Timer)

@MainActor
final class FocusTimerViewModel: ObservableObject {

    @Published var secondsElapsed: Int = 0
    @Published var isRunning: Bool = true
    @Published var isMuted: Bool = false
    @Published var showFullTimerCard: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var timerPublisher = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    // Wall-clock delta anchors
    private var lastResumeDate: Date? = Date()
    private var accumulatedSeconds: Int = 0

    init() {
        startTimer()
    }

    func startTimer() {
        isRunning = true
        lastResumeDate = Date()

        timerPublisher
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, let start = self.lastResumeDate else { return }
                let delta = max(0, Int(Date().timeIntervalSince(start)))
                self.secondsElapsed = self.accumulatedSeconds + delta
            }
            .store(in: &cancellables)
    }

    func togglePlayPause() {
        if isRunning {
            // Pausing
            if let start = lastResumeDate {
                accumulatedSeconds += max(0, Int(Date().timeIntervalSince(start)))
            }
            secondsElapsed = accumulatedSeconds
            lastResumeDate = nil
            isRunning = false
        } else {
            // Resuming
            lastResumeDate = Date()
            isRunning = true
        }
        Haptics.impact(.light)
    }

    func resetTimer() {
        accumulatedSeconds = 0
        secondsElapsed = 0
        lastResumeDate = nil
        isRunning = false
        Haptics.impact(.medium)
    }

    var formattedTime: String {
        let hours = secondsElapsed / 3600
        let minutes = (secondsElapsed % 3600) / 60
        let seconds = secondsElapsed % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
