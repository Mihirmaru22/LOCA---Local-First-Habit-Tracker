//
//  DS+Motion.swift
//  LOCA
//
//  Phase 11 — Motion grammar.
//
//  Two named springs define how LOCA moves: `.confirm` snaps (tactile), `.settle`
//  eases (soft). These promote the existing rippleConfirm / rippleSettle springs
//  into the design system. Reduce Motion is a TOKEN, not a per-view conditional:
//  callers pass the environment flag and get the correct animation, so no view
//  ever hand-writes the check (the Phase 10.3 pattern, systematized).
//

import SwiftUI

extension DS {

    enum Motion {

        /// Tactile snap — confirmations, check-ins, value commits.
        /// Mirrors `Animation.rippleConfirm`.
        static let confirm = Animation.spring(response: 0.3, dampingFraction: 0.5)

        /// Soft settle — navigation, sheet appearance, list insertion.
        /// Mirrors `Animation.rippleSettle`.
        static let settle = Animation.spring(response: 0.4, dampingFraction: 0.75)

        /// Near-instant fallback used when Reduce Motion is enabled.
        static let reduced = Animation.linear(duration: 0.1)

        /// Reduce-Motion-aware confirm. Pass `\.accessibilityReduceMotion`.
        static func confirm(reduceMotion: Bool) -> Animation {
            reduceMotion ? reduced : confirm
        }

        /// Reduce-Motion-aware settle. Pass `\.accessibilityReduceMotion`.
        static func settle(reduceMotion: Bool) -> Animation {
            reduceMotion ? reduced : settle
        }
    }
}
