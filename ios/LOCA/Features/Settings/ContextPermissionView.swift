//
//  ContextPermissionView.swift
//  LOCA
//
//  C3.2 — Permission framing for Calendar and Location access.
//  Mirrors the HealthKitPermissionView pattern: shown once before the
//  system dialogs so the user understands what each source unlocks.
//

import SwiftUI

struct ContextPermissionView: View {
    let onEnable: () async -> Void
    let onSkip: () -> Void

    private struct PermissionItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let insight: String
    }

    private let items: [PermissionItem] = [
        PermissionItem(
            icon: "calendar",
            label: "Calendar",
            insight: "Event density and social context shape your stress and energy signals"
        ),
        PermissionItem(
            icon: "location.fill",
            label: "Location",
            insight: "Place transitions reveal your daily rhythm and environment context"
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    Text("These sources add context that passive sensors alone can't see.")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(.horizontal, DS.Space.lg)
                        .padding(.top, DS.Space.md)

                    VStack(spacing: DS.Space.xs) {
                        ForEach(items) { item in
                            HStack(spacing: DS.Space.md) {
                                Image(systemName: item.icon)
                                    .font(.title3)
                                    .foregroundStyle(.tint)
                                    .frame(width: 32, alignment: .center)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.label)
                                        .font(DS.Text.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(DS.Color.textPrimary)

                                    Text(item.insight)
                                        .font(.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }

                                Spacer()
                            }
                            .padding(DS.Space.md)
                            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                            .padding(.horizontal, DS.Space.lg)
                        }
                    }

                    Text("Calendar attendee names are read locally to build your people model. No data leaves your device.")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(.horizontal, DS.Space.lg)

                    Spacer(minLength: DS.Space.xxxl)
                }
            }
            .navigationTitle("Context Access")
            .inlineNavigationTitleDisplay()
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: DS.Space.sm) {
                    Button {
                        Task { await onEnable() }
                    } label: {
                        Text("Enable Calendar & Location")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(DS.Space.md)
                            .background(.tint, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                            .foregroundStyle(.white)
                    }

                    Button(action: onSkip) {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.textSecondary)
                            .padding(.vertical, DS.Space.xs)
                    }
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.bottom, DS.Space.lg)
                .background(.ultraThinMaterial)
            }
        }
    }
}

#Preview {
    ContextPermissionView(onEnable: {}, onSkip: {})
}
