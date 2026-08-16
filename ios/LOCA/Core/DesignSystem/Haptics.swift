import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

// MARK: - Haptics (Cross-Platform iOS & macOS Force Touch Trackpad Engine)

/// Centralized haptic feedback for iOS Taptic Engine and macOS Force Touch Trackpad (`NSHapticFeedbackManager`).
/// Provides tactile feedback when completing habits, tasks, timeline snapping, and goal checkpoints.
enum Haptics {

    /// Physical impact — a value committed, a check-in logged, a row removed.
    enum Impact {
        case light, medium, rigid, soft
    }

    /// Fire a physical impact on iOS Taptic Engine or macOS Trackpad.
    static func impact(_ style: Impact) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
              || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }

        #if canImport(UIKit)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:  generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .rigid:  generator = UIImpactFeedbackGenerator(style: .rigid)
        case .soft:   generator = UIImpactFeedbackGenerator(style: .soft)
        }
        generator.impactOccurred()
        #elseif canImport(AppKit)
        switch style {
        case .light, .soft, .medium:
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        case .rigid:
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
        #endif
    }

    /// A discrete selection changed — a tab, a layout, a picker value.
    static func selection() {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
              || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }

        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #endif
    }

    /// A semantic outcome.
    enum Notify {
        case success, warning, error
    }

    /// Fire an outcome notification — e.g. `.success` when a check-in crosses its goal.
    static func notify(_ type: Notify) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
              || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }

        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        switch type {
        case .success: generator.notificationOccurred(.success)
        case .warning: generator.notificationOccurred(.warning)
        case .error:   generator.notificationOccurred(.error)
        }
        #elseif canImport(AppKit)
        switch type {
        case .success, .error:
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        case .warning:
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
        #endif
    }

    /// Convenience alias for semantic outcome notification.
    static func notification(_ type: Notify) {
        notify(type)
    }
}
