//
//  LifeEmptyState.swift
//  LOCA
//
//  P1-C — Reusable empty state for Life surfaces.
//
//  Every Life empty state must answer three questions:
//    1. What is this screen?
//    2. Why is it empty?
//    3. What should I do next?
//
//  Use LifeEmptyStateAction only when there is a concrete next step the user
//  can take right now (e.g. "Set my direction"). Omit it when the honest answer
//  is "check in consistently and wait" — a button that says "Check in" but
//  switches tabs is more disruptive than helpful.
//

import SwiftUI

// MARK: - LifeEmptyState

struct LifeEmptyState: View {
    let icon: String
    let headline: String
    let body: String
    var action: LifeEmptyStateAction? = nil

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text(headline)
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(body)
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            if let action {
                Button(action.label, action: action.perform)
                    .buttonStyle(.bordered)
                    .font(.caption)
            }
        }
        .padding(DS.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - LifeEmptyStateAction

struct LifeEmptyStateAction {
    let label: String
    let perform: () -> Void
}
