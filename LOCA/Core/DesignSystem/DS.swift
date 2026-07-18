//
//  DS.swift
//  LOCA
//
//  Phase 11 — Design System namespace.
//
//  `DS` is the single source of truth for LOCA's design tokens: spacing, radius,
//  typography, color, and motion. Views reference these tokens rather than literal
//  values so the design language stays consistent and centrally tunable. Every
//  future module reuses the same tokens — the system is module-agnostic by design.
//

import SwiftUI

/// LOCA Design System namespace. See `Docs/DESIGN_LANGUAGE.md` for the rationale
/// behind each token group and the seven identity-bearing dimensions.
enum DS {}

// MARK: - Spacing (4-pt base scale)

extension DS {

    /// The 4-pt spacing scale. Vertical rhythm runs slightly generous; horizontal
    /// margins stay consistent per surface. Views never use literal padding values.
    enum Space {
        /// 4 pt — tight, intra-element (icon ↔ label).
        static let xs: CGFloat = 4
        /// 8 pt — related elements within a group.
        static let sm: CGFloat = 8
        /// 12 pt — standard element separation.
        static let md: CGFloat = 12
        /// 16 pt — screen margins, card padding.
        static let lg: CGFloat = 16
        /// 24 pt — section separation.
        static let xl: CGFloat = 24
        /// 32 pt — major zone separation.
        static let xxl: CGFloat = 32
        /// 48 pt — hero / empty-state breathing.
        static let xxxl: CGFloat = 48
    }
}

// MARK: - Radius (role-based, concentric-correct)

extension DS {

    /// Corner radii keyed to element role, chosen so nested elements stay visually
    /// concentric (a control inside a card inside a sheet reads correctly).
    enum Radius {
        /// 4 pt — heatmap / contribution cell.
        static let cell: CGFloat = 4
        /// 10 pt — buttons, pills, inline controls.
        static let control: CGFloat = 10
        /// 16 pt — cards (the one sanctioned container).
        static let card: CGFloat = 16
        /// 22 pt — sheets, large surfaces.
        static let sheet: CGFloat = 22
    }
}
