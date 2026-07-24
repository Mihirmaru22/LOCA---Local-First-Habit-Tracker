//
//  SignalCollectionStatusView.swift
//  LOCA
//
//  Phase 4 — Signal collection status display
//  Shows user the on-device signal ingestion status
//

import SwiftUI

struct SignalCollectionStatusView: View {
    @StateObject private var coordinator = SignalCollectionCoordinator.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("On-Device Learning")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("LOCA learns from your passive signals: sleep, location, calendar, activity.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Divider()

            // Status
            HStack(spacing: 12) {
                Image(systemName: coordinator.isCollecting ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        coordinator.isCollecting ? Color.green : DS.Color.textTertiary
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(coordinator.isCollecting ? "Collecting" : "Standby")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    if let lastTime = coordinator.lastCollectionTime {
                        Text("Last: \(formattedTime(lastTime))")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))

            // Permissions
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: 12) {
                    Image(systemName: permissionIcon(coordinator.permissionStatus))
                        .font(.caption)
                        .foregroundStyle(permissionColor(coordinator.permissionStatus))

                    Text(coordinator.permissionStatus.rawValue)
                        .font(.caption)
                        .foregroundStyle(permissionColor(coordinator.permissionStatus))

                    Spacer()
                }
            }

            // Error message (if any)
            if let error = coordinator.collectionError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                InfoRow(icon: "moon.zzz.fill", label: "Sleep", status: "HealthKit")
                InfoRow(icon: "calendar", label: "Events", status: "Calendar")
                InfoRow(icon: "location.fill", label: "Location", status: "On-device")
                InfoRow(icon: "figure.walk", label: "Activity", status: "Motion sensor")
            }

            Spacer()

            // Privacy note
            Text("All signal processing happens on your device. No data leaves LOCA without your consent.")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(8)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(DS.Space.lg)
    }

    private func permissionIcon(_ status: SignalCollectionCoordinator.PermissionStatus) -> String {
        switch status {
        case .granted: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .requesting: return "ellipsis.circle"
        case .notRequested: return "circle"
        }
    }

    private func permissionColor(_ status: SignalCollectionCoordinator.PermissionStatus) -> Color {
        switch status {
        case .granted: return .green
        case .denied: return .red
        case .requesting: return .yellow
        case .notRequested: return DS.Color.textTertiary
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let status: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .frame(width: 20)
                .foregroundStyle(DS.Color.textSecondary)

            Text(label)
                .font(.caption)
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            Text(status)
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignalCollectionStatusView()
            .navigationTitle("Learning Status")
    }
}
