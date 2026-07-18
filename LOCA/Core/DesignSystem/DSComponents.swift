//
//  DSComponents.swift
//  LOCA
//
//  Phase 11 — Foundational, module-agnostic components.
//
//  These primitives make the design language enforceable rather than aspirational.
//  Every screen and every future module composes from these instead of one-off
//  layouts. A run, a sleep score, or a macro count drops into `MetricTile` and
//  `LOCACard` unchanged — the components assume nothing about Habits.
//

import SwiftUI

// MARK: - LOCACard

/// The single sanctioned card container.
///
/// LOCA prefers hairline separators and whitespace over nested rounded rectangles
/// (container restraint — identity dimension #2). Use `LOCACard` ONLY when its
/// contents form a single tappable/cohesive unit. If you are reaching for a card
/// just to draw a background, use a divider or spacing instead.
struct LOCACard<Content: View>: View {

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DS.Space.lg)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }
}

// MARK: - SectionHeader

/// The one section-title treatment used across every screen.
///
/// Decisive typographic hierarchy (identity dimension #7): a section header is a
/// confident `heading`, optionally trailed by an accessory (e.g. a "See all").
struct SectionHeader<Accessory: View>: View {

    private let title: String
    private let accessory: Accessory

    init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DS.Text.heading)
                .foregroundStyle(DS.Color.textPrimary)
            Spacer(minLength: DS.Space.sm)
            accessory
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

extension SectionHeader where Accessory == EmptyView {
    /// Section header with no trailing accessory.
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

// MARK: - MetricTile

/// A labeled value tile — LOCA's numeric voice in component form.
///
/// Module-agnostic: Habits use it for streaks, Fitness will use it for pace, Sleep
/// for hours. Value renders in rounded numerals (`ValueText`); label is a caption.
/// Optional accent tints the icon.
struct MetricTile: View {

    let icon: String
    let value: String
    let label: String
    var accent: Color = DS.Color.textSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: icon)
                    .font(DS.Text.caption)
                    .foregroundStyle(accent)
                Text(label.uppercased())
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
            }

            ValueText(value, font: DS.Text.value)
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
