import SwiftUI

// MARK: - Canonical Animation Springs (Engineering Principles §7.1)
//
// Two spring animations are defined project-wide. No other spring parameters
// are used without an explicit revision to the Engineering Principles document.
//
// All `withAnimation` call sites use one of these two values. Ad-hoc
// `.spring(response:dampingFraction:)` calls with custom parameters are banned.

extension Animation {

    /// Tactile confirm: check-in button press, log confirmation feedback.
    ///
    /// High energy, quick settle. Used wherever a gesture demands a physical
    /// response — check-in confirmation, interactive widget tap, value submit.
    ///
    /// Parameters: `response: 0.3, dampingFraction: 0.5` per Engineering Principles §7.1.
    static let rippleConfirm = Animation.spring(response: 0.3, dampingFraction: 0.5)

    /// Smooth settle: navigation transitions, sheet appearances, list insertions.
    ///
    /// Lower energy, overdamped. Used where smoothness matters more than impact.
    ///
    /// Parameters: `response: 0.4, dampingFraction: 0.75` per Engineering Principles §7.1.
    static let rippleSettle = Animation.spring(response: 0.4, dampingFraction: 0.75)
}
