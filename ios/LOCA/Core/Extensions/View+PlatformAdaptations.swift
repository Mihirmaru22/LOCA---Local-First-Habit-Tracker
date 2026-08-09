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

    /// Large navigation-bar title display.
    ///
    /// - iOS: applies `.navigationBarTitleDisplayMode(.large)`.
    /// - macOS: no-op.
    @ViewBuilder
    func largeNavigationTitleDisplay() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.large)
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

    /// Swipeable paged `TabView` without the page-dot index.
    ///
    /// - iOS: `.tabViewStyle(.page(indexDisplayMode: .never))`.
    /// - macOS: no-op — `PageTabViewStyle` is unavailable.
    @ViewBuilder
    func pagedTabView() -> some View {
        #if os(iOS)
        tabViewStyle(.page(indexDisplayMode: .never))
        #else
        self
        #endif
    }

    /// Swipeable paged `TabView` with a visible page-dot index.
    ///
    /// - iOS: `.tabViewStyle(.page(indexDisplayMode: .always))`.
    /// - macOS: no-op.
    @ViewBuilder
    func pagedTabViewWithIndex() -> some View {
        #if os(iOS)
        tabViewStyle(.page(indexDisplayMode: .always))
        #else
        self
        #endif
    }

    /// Page index dots with always-visible background.
    ///
    /// - iOS: `.indexViewStyle(.page(backgroundDisplayMode: .always))`.
    /// - macOS: no-op — `indexViewStyle` is unavailable.
    @ViewBuilder
    func pageIndexViewStyle() -> some View {
        #if os(iOS)
        indexViewStyle(.page(backgroundDisplayMode: .always))
        #else
        self
        #endif
    }

    /// Full-screen cover on iOS, sheet on macOS (fullScreenCover is unavailable there).
    @ViewBuilder
    func fullScreenCoverCompat<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #else
        sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #endif
    }
}
