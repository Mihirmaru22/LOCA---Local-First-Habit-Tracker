//
//  SensorConflictView.swift
//  LOCA
//
//  C2.2 — Sensor conflict inspectability.
//  Surfaces stored SensorConflict records so disagreements between
//  sensor-derived values and user self-reports are inspectable, not
//  silently discarded. Shows evidence only — no verdict about which
//  value is correct. The sensor value remains authoritative for
//  InferredState; this view is the transparency layer.
//

import SwiftUI
import SwiftData

struct SensorConflictView: View {
    @Query(sort: \SensorConflict.recordedAt, order: .reverse)
    private var conflicts: [SensorConflict]

    var body: some View {
        Group {
            if conflicts.isEmpty {
                emptyState
            } else {
                conflictContent
            }
        }
        .navigationTitle("Sensor Gaps")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content

    private var conflictContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                Text("Where sensors and self-reports differed")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                dimensionSummarySection

                recentSection

                Spacer(minLength: DS.Space.xxxl)
            }
        }
    }

    // MARK: - Dimension Summary

    private var dimensionSummarySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            SectionHeader(title: "By Dimension")

            VStack(spacing: DS.Space.sm) {
                ForEach(dimensionSummaries, id: \.dimension) { summary in
                    DimensionSummaryRow(summary: summary)
                        .padding(.horizontal, DS.Space.lg)
                }
            }
        }
    }

    // MARK: - Recent Conflicts

    private var recentSection: some View {
        let shown = Array(conflicts.prefix(30))
        return VStack(alignment: .leading, spacing: DS.Space.sm) {
            SectionHeader(
                title: conflicts.count > 30
                    ? "Recent (30 of \(conflicts.count))"
                    : "All Conflicts (\(conflicts.count))"
            )

            VStack(spacing: DS.Space.xs) {
                ForEach(shown) { conflict in
                    ConflictRow(conflict: conflict)
                        .padding(.horizontal, DS.Space.lg)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text("No Gaps")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Sensors and self-reports have agreed within the detection threshold whenever both were available.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DS.Space.xl)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Computed

    private var dimensionSummaries: [DimensionSummary] {
        let grouped = Dictionary(grouping: conflicts) { $0.dimension }
        return ["energy", "stress", "focus", "mood"].compactMap { dim -> DimensionSummary? in
            guard let entries = grouped[dim], !entries.isEmpty else { return nil }
            let mean = entries.map { $0.magnitude }.reduce(0, +) / Double(entries.count)
            return DimensionSummary(dimension: dim, count: entries.count, meanMagnitude: mean)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DS.Text.caption)
            .foregroundStyle(DS.Color.textSecondary)
            .textCase(.uppercase)
            .padding(.horizontal, DS.Space.lg)
    }
}

// MARK: - Dimension Summary Model

private struct DimensionSummary {
    let dimension: String
    let count: Int
    let meanMagnitude: Double
}

// MARK: - Dimension Summary Row

private struct DimensionSummaryRow: View {
    let summary: DimensionSummary

    var body: some View {
        HStack(spacing: DS.Space.md) {
            Text(summary.dimension.capitalized)
                .font(DS.Text.body)
                .fontWeight(.medium)
                .foregroundStyle(DS.Color.textPrimary)
                .frame(width: 56, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundStyle(DS.Color.surfaceRecessed)

                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: geo.size.width * min(1, summary.meanMagnitude), height: 4)
                        .foregroundStyle(magnitudeColor(summary.meanMagnitude))
                }
            }
            .frame(height: 4)

            Text(String(format: "%.0f%%", summary.meanMagnitude * 100))
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(width: 32, alignment: .trailing)

            Text("\(summary.count)×")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
    }

    private func magnitudeColor(_ magnitude: Double) -> Color {
        if magnitude >= 0.4 { return Color(hex: "#EF4444") }
        if magnitude >= 0.2 { return Color(hex: "#F59E0B") }
        return Color(hex: "#10B981")
    }
}

// MARK: - Conflict Row

private struct ConflictRow: View {
    let conflict: SensorConflict

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DS.Space.xs) {
                    Text(conflict.dimension.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(conflict.recordedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                }

                HStack(spacing: 6) {
                    Label(
                        String(format: "%.2f", conflict.sensorValue),
                        systemImage: "sensor.tag.radiowaves.forward"
                    )
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)

                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)

                    Label(
                        String(format: "%.2f", conflict.userValue),
                        systemImage: "person"
                    )
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Spacer()

            Text(String(format: "Δ%.2f", conflict.magnitude))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(magnitudeColor(conflict.magnitude))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(magnitudeColor(conflict.magnitude).opacity(0.1), in: Capsule())
        }
        .padding(DS.Space.xs)
    }

    private func magnitudeColor(_ magnitude: Double) -> Color {
        if magnitude >= 0.4 { return Color(hex: "#EF4444") }
        if magnitude >= 0.2 { return Color(hex: "#F59E0B") }
        return Color(hex: "#10B981")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SensorConflictView()
    }
}
