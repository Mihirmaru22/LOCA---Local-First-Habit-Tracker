//
//  View+PlatformAdaptations.swift
//  LOCA
//
//  Phase 10 (cross-platform hardening, pulled forward) — platform shims.
//
//  LOCA targets iOS 17+ and macOS 14+. Several UIKit-derived SwiftUI modifiers
//  used by the iOS-first UI are unavailable on macOS. These helpers apply the
//  iOS variant where it exists and fall back appropriately on macOS, keeping
//  call sites free of inline `#if os(iOS)` noise and centralising the platform
//  knowledge in one documented place (the same canonical-helper pattern as
//  `ColorPalette` and `Animation+Extensions`).
//

import SwiftUI

extension View {

    /// Inline navigation-bar title display.
    ///
    /// - iOS: applies `.navigationBarTitleDisplayMode(.inline)`.
    /// - macOS: no-op — the modifier is unavailable (macOS has no navigation-bar
    ///   title display mode); the title renders in the window/toolbar chrome.
    @ViewBuilder
    func inlineNavigationTitleDisplay() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Decimal keypad for numeric text entry.
    ///
    /// - iOS: applies `.keyboardType(.decimalPad)`.
    /// - macOS: no-op — `TextField` has no `keyboardType`; entry uses the
    ///   hardware keyboard.
    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// Grouped-inset list styling, mapped per platform.
    ///
    /// - iOS: `.insetGrouped` — the standard grouped detail-list appearance.
    /// - macOS: `.inset` — `.insetGrouped` is unavailable there; `.inset` is the
    ///   closest native equivalent for an inset, sectioned list.
    @ViewBuilder
    func groupedInsetList() -> some View {
        #if os(iOS)
        listStyle(.insetGrouped)
        #else
        listStyle(.inset)
        #endif
    }
}
