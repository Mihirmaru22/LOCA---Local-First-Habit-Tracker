//
//  Haptics.swift
//  LOCA
//
//  Phase P.0.8 / P4.5 — The haptics contract.
//
//  One path for all haptic feedback so call sites stop hand-writing
//  UIImpactFeedbackGenerator inline. UIKit-gated; a no-op on platforms without it
//  so callers never write `#if canImport(UIKit)` themselves.
//  Gated by @AppStorage("hapticsEnabled"); defaults to true.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Centralized haptic feedback. Semantic entry points, not raw generators, so the
/// intent (a value committed vs. a selection changed vs. an outcome) is legible at the
/// call site and the feedback stays consistent across equivalent actions app-wide.
enum Haptics {

    /// Physical impact — a value committed, a check-in logged, a row removed.
    enum Impact {
        case light, rigid, soft
    }

    /// Fire a physical impact. Gated by user setting (default on); no-op where UIKit is unavailable.
    static func impact(_ style: Impact) {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
              || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }
        #if canImport(UIKit)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = UIImpactFeedbackGenerator(style: .light)
        case .rigid: generator = UIImpactFeedbackGenerator(style: .rigid)
        case .soft:  generator = UIImpactFeedbackGenerator(style: .soft)
        }
        generator.impactOccurred()
        #endif
    }

    /// A discrete selection changed — a tab, a layout, a picker value.
    /// Gated by user setting (default on); no-op where UIKit is unavailable.
    static func selection() {
        guard UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
              || UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// A semantic outcome.
    enum Notify {
        case success, warning, error
    }

    /// Fire an outcome notification — e.g. `.success` when a check-in crosses its goal.
    /// Gated by user setting (default on); no-op where UIKit is unavailable.
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
        #endif
    }
}
