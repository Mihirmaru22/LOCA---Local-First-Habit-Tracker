//
//  ReflectionComponents.swift
//  LOCA
//
//  Phase F (Frontend Reflection) — shared "honesty primitives".
//
//  A single set of components so every surface shows uncertainty the same way,
//  instead of each screen inventing its own dialect (bare %, halo, dot). These
//  render REAL backend fields (C1–C5): a ConfidenceLevel band, a value with its
//  uncertainty halo, and optionally the epistemic/aleatoric distinction (C1.3).
//
//  These replace the previously-private ConfidenceChip (TraitSummaryView) and
//  ConfidenceDot (LifeSceneView) so the exemplar treatment is reused, not copied.
//

import SwiftUI
import SwiftData

// MARK: - ConfidenceLevel presentation

extension ConfidenceLevel {
    /// Human-readable band label. Deliberately non-numeric: the backend's
    /// confidence is a band, not a false-precision percentage.
    var label: String {
        switch self {
        case .crisp:       return "Confident"
        case .soft:        return "Emerging"
        case .speculative: return "Uncertain"
        }
    }

    var tint: Color {
        switch self {
        case .crisp:       return Color(hex: "#10B981")
        case .soft:        return Color(hex: "#F59E0B")
        case .speculative: return Color(hex: "#6B7280")
        }
    }
}

// MARK: - Confidence Chip

/// A small band label ("Confident" / "Emerging" / "Uncertain"). Prefer this over a
/// raw "NN%" — the backend's certainty is a band, and a percentage overstates it.
struct ConfidenceChip: View {
    let level: ConfidenceLevel

    init(level: ConfidenceLevel) { self.level = level }
    /// Convenience: build directly from a 0–1 uncertainty.
    init(uncertainty: Double) { self.level = ConfidenceLevel(uncertainty: uncertainty) }

    var body: some View {
        Text(level.label)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(level.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(level.tint.opacity(0.12), in: Capsule())
    }
}

// MARK: - Confidence Dot

/// A minimal certainty indicator for dense rows where a chip is too heavy.
/// Uses the same band thresholds as ConfidenceChip via ConfidenceLevel.
struct ConfidenceDot: View {
    let level: ConfidenceLevel

    init(level: ConfidenceLevel) { self.level = level }
    /// Convenience for callers holding a 0–1 confidence (not uncertainty).
    init(confidence: Double) { self.level = ConfidenceLevel(uncertainty: 1.0 - confidence) }

    var body: some View {
        Circle()
            .frame(width: 6, height: 6)
            .foregroundStyle(level.tint)
    }
}

// MARK: - Uncertainty Bar

/// A 0–1 value rendered with its uncertainty as a translucent halo around the
/// point estimate — the treatment proven on Traits. The halo makes "we think X,
/// give or take" legible without a number.
struct UncertaintyBar: View {
    let value: Double
    let uncertainty: Double
    var color: Color = .accentColor
    /// Some surfaces (salience) want a gentler halo; scale it here.
    var haloScale: Double = 1.0
    var showMarker: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .frame(height: 6)
                    .foregroundStyle(DS.Color.surfaceRecessed)

                // Uncertainty halo around the point estimate.
                let halo = uncertainty * haloScale
                let haloStart = max(0, value - halo)
                let haloEnd = min(1, value + halo)
                RoundedRectangle(cornerRadius: 3)
                    .frame(width: geo.size.width * (haloEnd - haloStart), height: 6)
                    .offset(x: geo.size.width * haloStart)
                    .foregroundStyle(color.opacity(0.25))

                // Point estimate.
                RoundedRectangle(cornerRadius: 3)
                    .frame(width: geo.size.width * value, height: 6)
                    .foregroundStyle(color)

                if showMarker {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(color)
                        .offset(x: geo.size.width * value - 5, y: -2)
                }
            }
        }
        .frame(height: showMarker ? 10 : 6)
    }
}

// MARK: - Evidence Summary (C1.2 provenance)

/// A compact roll-up of what evidence underlies a composed view: which sources
/// contributed and how many present readings back it. Aggregated from provenance
/// already stored on InferredState — no new backend plumbing.
struct EvidenceSummary {
    let sources: [String]    // SignalSource rawValues, most-frequent first
    let readingCount: Int    // present inferred states that contributed any source
}

/// Roll up InferenceProvenance across a set of states without extra queries.
func summarizeEvidence(states: [InferredState]) -> EvidenceSummary {
    var counts: [String: Int] = [:]
    var readings = 0
    for state in states {
        let provenances = [
            state.energyProvenance, state.stressProvenance,
            state.focusProvenance, state.moodProvenance
        ].compactMap { $0 }

        var contributed = false
        for provenance in provenances where !provenance.sources.isEmpty {
            for source in provenance.sources { counts[source, default: 0] += 1 }
            contributed = true
        }
        if contributed { readings += 1 }
    }
    let ordered = counts.sorted { $0.value > $1.value }.map { $0.key }
    return EvidenceSummary(sources: ordered, readingCount: readings)
}

/// Human-readable name for a stored SignalSource rawValue.
func friendlyEvidenceSource(_ raw: String) -> String {
    switch raw {
    case "sleep":               return "Sleep"
    case "heartRateVariability": return "HRV"
    case "heartRate":           return "Heart rate"
    case "location":            return "Location"
    case "calendar":            return "Calendar"
    case "deviceActivity":      return "Screen time"
    case "explicitLog":         return "Your logs"
    case "motionActivity":      return "Movement"
    case "steps":               return "Steps"
    case "workout":             return "Workouts"
    case "mindfulSession":      return "Mindfulness"
    case "daylight":            return "Daylight"
    default:                    return raw.capitalized
    }
}

/// "What this draws on" — the sources and reading count behind a view. Renders
/// nothing when there is no provenance to claim (honest about absence).
struct EvidenceSummaryRow: View {
    let summary: EvidenceSummary

    var body: some View {
        if summary.sources.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("What this draws on")
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(DS.Color.textTertiary)

                Text(summary.sources.prefix(6).map(friendlyEvidenceSource).joined(separator: " · "))
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(summary.readingCount) reading\(summary.readingCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }
}

// MARK: - Uncertainty Type Note (C1.3)

/// One line distinguishing reducible from irreducible uncertainty — the
/// distinction the backend computes (UncertaintyType) but the UI usually collapses.
/// Only meaningful when the value is actually uncertain; callers gate on that.
struct UncertaintyTypeNote: View {
    let type: UncertaintyType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type == .epistemic ? "arrow.down.circle" : "waveform.path")
                .font(.caption2)
            Text(type == .epistemic
                 ? "More data will sharpen this"
                 : "Naturally variable — more data won't narrow it")
                .font(.caption2)
        }
        .foregroundStyle(DS.Color.textTertiary)
    }
}
