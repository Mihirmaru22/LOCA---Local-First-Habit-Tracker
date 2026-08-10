//
//  HealthKitPermissionView.swift
//  LOCA
//
//  C3.1 — Permission framing for HealthKit access.
//  Shown once, before the system HealthKit dialog, so the user understands
//  exactly which view each data type unlocks. Dismissing with "Not Now"
//  is a valid choice — all sources degrade gracefully.
//

import SwiftUI

// MARK: - HealthKitPermissionView

struct HealthKitPermissionView: View {
    let onEnable: () async -> Void
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Understand your energy, stress, and focus passively — no journaling required. Each data type unlocks one layer of your personal life model.")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                    VStack(spacing: DS.Space.xs) {
                        ForEach(HealthKitPermissionItem.all) { item in
                            HealthKitPermissionRow(item: item)
                                .padding(.horizontal, DS.Space.lg)
                        }
                    }

                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("All processing happens on your device. LOCA never sends health data to a server.")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(.horizontal, DS.Space.lg)

                    Spacer(minLength: DS.Space.xxxl)
                }
            }
            .navigationTitle("Health Access")
            .inlineNavigationTitleDisplay()
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: DS.Space.sm) {
                    Button {
                        Task { await onEnable() }
                    } label: {
                        Text("Enable Health Access")
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

// MARK: - Permission Item Model

struct HealthKitPermissionItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let insight: String

    static let all: [HealthKitPermissionItem] = [
        HealthKitPermissionItem(
            icon: "moon.zzz.fill",
            label: "Sleep",
            insight: "Unlocks nightly recovery and energy scores"
        ),
        HealthKitPermissionItem(
            icon: "heart.fill",
            label: "Heart Rate",
            insight: "Unlocks stress and readiness tracking"
        ),
        HealthKitPermissionItem(
            icon: "waveform.path.ecg",
            label: "Heart Rate Variability",
            insight: "Unlocks nervous system state and recovery depth"
        ),
        HealthKitPermissionItem(
            icon: "figure.walk",
            label: "Steps",
            insight: "Unlocks activity rhythm and movement patterns"
        ),
        HealthKitPermissionItem(
            icon: "figure.run",
            label: "Workouts",
            insight: "Unlocks effort and training load signals"
        ),
        HealthKitPermissionItem(
            icon: "brain.head.profile",
            label: "Mindful Minutes",
            insight: "Unlocks focus and calm baseline"
        ),
    ]
}

// MARK: - Permission Row

private struct HealthKitPermissionRow: View {
    let item: HealthKitPermissionItem

    var body: some View {
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
    }
}

// MARK: - Preview

#Preview {
    HealthKitPermissionView(
        onEnable: {},
        onSkip: {}
    )
}
