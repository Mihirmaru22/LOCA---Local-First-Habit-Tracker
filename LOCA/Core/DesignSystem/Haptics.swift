//
//  Haptics.swift
//  LOCA
//
//  Phase P.0.8 — The haptics contract.
//
//  One path for all haptic feedback so call sites stop hand-writing
//  UIImpactFeedbackGenerator inline (the pattern currently duplicated in
//  HabitListView, HabitCheckInsView, and AddCheckInSheetView). UIKit-gated; a no-op
//  on platforms without it, so callers never write `#if canImport(UIKit)` themselves.
//
//  Sequencing (see Docs/PhaseP-CraftsmanshipPolish.md): created here in P0 because
//  P2.3 is the first new consumer. P4 extends this with a user-facing enable/disable
//  setting and folds in the three existing hand-written sites. Until P4 these fire
//  unconditionally on iOS — the enable check lives in exactly one place when it lands.
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

    /// Fire a physical impact. No-op where UIKit is unavailable.
    static func impact(_ style: Impact) {
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
    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// A semantic outcome.
    enum Notify {
        case success, warning, error
    }

    /// Fire an outcome notification — e.g. `.success` when a check-in crosses its goal.
    static func notify(_ type: Notify) {
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
