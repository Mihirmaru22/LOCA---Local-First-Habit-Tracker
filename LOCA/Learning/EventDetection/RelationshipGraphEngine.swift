//
//  RelationshipGraphEngine.swift
//  LOCA
//
//  Phase 6, Session 6.4 — The relationship graph.
//
//  Associations between States and People, computed *within regime* (chapter)
//  and checked for a Life Event as a common cause. Edges are held as revisable
//  hypotheses: the graph is recomputed on demand, never persisted, so a newly
//  detected event can overturn an association the next time it is built.
//
//  The core honesty rule (the plan's "done when"): a cross-event confound —
//  two things that both shift at a Life Event and therefore look correlated in
//  the pooled history — must NOT manufacture a false edge. We detect this by
//  comparing the pooled correlation against the sample-weighted within-regime
//  correlation; when the pooled link is strong but each regime's is not, the
//  edge is marked confounded and is never asserted.
//

import Foundation
import SwiftData

// MARK: - Graph Value Types

/// The relationship graph. Computed on demand; nothing here is stored in the
/// schema, because every edge is an explicitly revisable hypothesis.
struct RelationshipGraph {
    let nodes: [RelationshipNode]
    let edges: [RelationshipEdge]
    let generatedAt: Date

    /// Real within-regime associations a Life Event does not explain away.
    var assertedEdges: [RelationshipEdge] {
        edges.filter { !$0.isConfounded }.sorted { $0.confidence > $1.confidence }
    }

    /// Associations that dissolve within each regime — a Life Event is the
    /// common cause. Surfaced honestly, never asserted as a real link.
    var confoundedEdges: [RelationshipEdge] {
        edges.filter { $0.isConfounded }.sorted { abs($0.pooledStrength) > abs($1.pooledStrength) }
    }

    var isEmpty: Bool { edges.isEmpty }
}

struct RelationshipNode: Identifiable, Hashable {
    enum Kind: Hashable { case state, person }
    let id: String
    let label: String
    let kind: Kind
}

struct RelationshipEdge: Identifiable {
    let id: String
    let fromLabel: String
    let toLabel: String
    /// Signed within-regime association, roughly −1…1.
    let strength: Double
    /// 0…1 — how much we trust the association (magnitude × evidence).
    let confidence: Double
    /// True → a life change explains the pooled link; the edge is not asserted.
    let isConfounded: Bool
    /// The naive cross-regime association, kept for transparency.
    let pooledStrength: Double
    let sampleCount: Int
    let explanation: String
}

// MARK: - Engine

@MainActor
final class RelationshipGraphEngine {
    static let shared = RelationshipGraphEngine()

    // Tuning constants. Deliberately conservative: the graph would rather stay
    // silent than assert a shaky edge.
    private let minTotalSamples = 20        // states needed before we compute anything
    private let minSamplesPerRegime = 10    // states needed in a chapter to trust its correlation
    private let assertMagnitude = 0.25      // |within-regime r| required to assert a state↔state edge
    private let confoundPooled = 0.40       // pooled |r| that looks like a relationship…
    private let confoundWithin = 0.18       // …but a within-regime |r| this small ⇒ confounded

    private enum StateDim: String, CaseIterable {
        case energy, stress, focus, mood

        var label: String {
            switch self {
            case .energy: return "Energy"
            case .stress: return "Stress"
            case .focus:  return "Focus"
            case .mood:   return "Mood"
            }
        }

        var nodeId: String { "state.\(rawValue)" }

        func value(_ state: InferredState) -> Double {
            switch self {
            case .energy: return state.energy
            case .stress: return state.stress
            case .focus:  return state.focus
            case .mood:   return state.mood
            }
        }
    }

    // MARK: - Public API

    func computeGraph(modelContext: ModelContext) throws -> RelationshipGraph {
        let states = try modelContext.fetch(
            FetchDescriptor<InferredState>(sortBy: [SortDescriptor(\.timestamp)])
        )
        guard states.count >= minTotalSamples else {
            return RelationshipGraph(nodes: [], edges: [], generatedAt: Date())
        }

        let chapters = try modelContext.fetch(
            FetchDescriptor<Chapter>(sortBy: [SortDescriptor(\.startDate)])
        )

        let regimes = regimeBuckets(states: states, chapters: chapters)

        // C2.4: only state-state edges are asserted. Person-state edges were removed
        // because "this person is associated with lower/higher mood" is a verdict
        // about relationship meaning — an unfillable claim (taxonomy §3.3).
        let nodes: [RelationshipNode] = StateDim.allCases.map {
            RelationshipNode(id: $0.nodeId, label: $0.label, kind: .state)
        }
        let edges: [RelationshipEdge] = stateStateEdges(states: states, regimes: regimes)

        return RelationshipGraph(nodes: nodes, edges: edges, generatedAt: Date())
    }

    // MARK: - Regime Bucketing

    /// Splits the state history into per-chapter buckets. With no chapters yet,
    /// the whole history is a single regime — pooled equals within, so nothing is
    /// wrongly asserted or rejected until real regime structure exists.
    private func regimeBuckets(states: [InferredState], chapters: [Chapter]) -> [[InferredState]] {
        guard !chapters.isEmpty else { return [states] }

        var buckets: [[InferredState]] = []
        for chapter in chapters {
            let end = chapter.endDate ?? Date.distantFuture
            let inChapter = states.filter { $0.timestamp >= chapter.startDate && $0.timestamp < end }
            if inChapter.count >= minSamplesPerRegime {
                buckets.append(inChapter)
            }
        }
        return buckets.isEmpty ? [states] : buckets
    }

    // MARK: - State × State Edges

    private func stateStateEdges(states: [InferredState], regimes: [[InferredState]]) -> [RelationshipEdge] {
        var edges: [RelationshipEdge] = []
        let dims = StateDim.allCases

        for i in 0..<dims.count {
            for j in (i + 1)..<dims.count {
                let a = dims[i]
                let b = dims[j]

                guard let pooled = pearson(states.map(a.value), states.map(b.value)) else { continue }

                // Sample-weighted mean of each regime's correlation.
                var weightedSum = 0.0
                var weight = 0.0
                for regime in regimes where regime.count >= minSamplesPerRegime {
                    guard let r = pearson(regime.map(a.value), regime.map(b.value)) else { continue }
                    let w = Double(regime.count)
                    weightedSum += r * w
                    weight += w
                }
                guard weight > 0 else { continue }
                let within = weightedSum / weight
                let sampleCount = Int(weight)

                let confounded = abs(pooled) >= confoundPooled && abs(within) < confoundWithin
                let asserted = abs(within) >= assertMagnitude
                guard asserted || confounded else { continue }

                let confidence = correlationConfidence(magnitude: abs(within), sampleCount: sampleCount)
                edges.append(
                    RelationshipEdge(
                        id: "ss.\(a.rawValue).\(b.rawValue)",
                        fromLabel: a.label,
                        toLabel: b.label,
                        strength: within,
                        confidence: confounded ? min(confidence, 0.4) : confidence,
                        isConfounded: confounded,
                        pooledStrength: pooled,
                        sampleCount: sampleCount,
                        explanation: stateEdgeExplanation(a: a, b: b, within: within, confounded: confounded)
                    )
                )
            }
        }
        return edges
    }

    // MARK: - Explanations

    private func stateEdgeExplanation(a: StateDim, b: StateDim, within: Double, confounded: Bool) -> String {
        if confounded {
            return "\(a.label) and \(b.label) rise and fall together across your whole history, but the link disappears inside each chapter — a life change moved both, they aren't tied to each other."
        }
        let direction = within < 0 ? "lower" : "higher"
        return "Within a chapter, higher \(a.label.lowercased()) tends to go with \(direction) \(b.label.lowercased())."
    }

    // MARK: - Statistics Helpers

    private func pearson(_ xs: [Double], _ ys: [Double]) -> Double? {
        let n = min(xs.count, ys.count)
        guard n >= 3 else { return nil }

        let meanX = xs.reduce(0, +) / Double(n)
        let meanY = ys.reduce(0, +) / Double(n)

        var numerator = 0.0
        var denomX = 0.0
        var denomY = 0.0
        for i in 0..<n {
            let dx = xs[i] - meanX
            let dy = ys[i] - meanY
            numerator += dx * dy
            denomX += dx * dx
            denomY += dy * dy
        }
        guard denomX > 0, denomY > 0 else { return nil }
        return numerator / (sqrt(denomX) * sqrt(denomY))
    }

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Confidence in a correlation edge: more evidence and a stronger association
    /// both raise it, but a small sample caps it hard.
    private func correlationConfidence(magnitude: Double, sampleCount: Int) -> Double {
        let sizeFactor = min(1.0, Double(sampleCount) / 150.0)
        let strengthFactor = min(1.0, magnitude / 0.6)
        return min(1.0, (0.35 + 0.65 * strengthFactor) * sizeFactor)
    }

    private func clampUnit(_ value: Double) -> Double {
        max(-1.0, min(1.0, value))
    }
}
