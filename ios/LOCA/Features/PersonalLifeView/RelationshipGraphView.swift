//
//  RelationshipGraphView.swift
//  LOCA
//
//  Phase 6, Session 6.4 — Browse the relationship graph.
//
//  Shows the associations LOCA is willing to assert (real, within-regime links),
//  and — separately and honestly — the ones it refuses to assert because a life
//  change explains them. The refusal is the point: it is what keeps the graph
//  from manufacturing false connections out of coincidental co-movement.
//

import SwiftUI
import SwiftData

struct RelationshipGraphView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var graph: RelationshipGraph?
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Finding connections…")
                    .frame(maxHeight: .infinity, alignment: .center)
            } else if let graph, !graph.isEmpty {
                content(graph)
            } else {
                emptyState
            }
        }
        .navigationTitle("Connections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: refresh) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .disabled(isLoading)
            }
        }
        .task {
            if graph == nil { await compute() }
        }
    }

    // MARK: - Content

    private func content(_ graph: RelationshipGraph) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                Text("What moves with what in your life, measured inside each chapter so a big change doesn't fake a connection.")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                if graph.assertedEdges.isEmpty {
                    Text("No connections hold up within a single chapter yet.")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(.horizontal, DS.Space.lg)
                } else {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        SectionLabel(text: "Connections that hold up")
                        ForEach(graph.assertedEdges) { edge in
                            EdgeCard(edge: edge)
                        }
                    }
                    .padding(.horizontal, DS.Space.lg)
                }

                if !graph.confoundedEdges.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        SectionLabel(text: "Explained by a life change")
                        ForEach(graph.confoundedEdges) { edge in
                            EdgeCard(edge: edge)
                        }
                    }
                    .padding(.horizontal, DS.Space.lg)
                }

                Spacer(minLength: DS.Space.xxxl)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text("No Connections Yet")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("LOCA needs enough state history — ideally spanning more than one chapter — before it can tell a real connection from a coincidence.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Look for Connections") { Task { await compute() } }
                .buttonStyle(.bordered)
        }
        .padding(DS.Space.xl)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Actions

    private func refresh() {
        Task { await compute() }
    }

    private func compute() async {
        isLoading = true
        graph = try? RelationshipGraphEngine.shared.computeGraph(modelContext: modelContext)
        isLoading = false
    }
}

// MARK: - Section Label

private struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.Text.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.textSecondary)
            .textCase(.uppercase)
    }
}

// MARK: - Edge Card

private struct EdgeCard: View {
    let edge: RelationshipEdge

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack(spacing: DS.Space.sm) {
                Text(edge.fromLabel)
                    .font(DS.Text.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)

                Image(systemName: linkIcon)
                    .font(.caption)
                    .foregroundStyle(linkColor)

                Text(edge.toLabel)
                    .font(DS.Text.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                if edge.isConfounded {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }

            // Strength bar (bidirectional from the midpoint).
            StrengthBar(strength: edge.strength, confounded: edge.isConfounded)

            Text(edge.explanation)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DS.Space.md) {
                Label(confidenceLabel, systemImage: "gauge.medium")
                Label("\(edge.sampleCount) obs", systemImage: "number")
            }
            .font(.caption2)
            .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
        .opacity(edge.isConfounded ? 0.7 : 1.0)
    }

    private var linkIcon: String {
        "arrow.left.and.right"
    }

    private var linkColor: Color {
        if edge.isConfounded { return DS.Color.textTertiary }
        return edge.strength < 0 ? Color(hex: "#EF4444") : Color(hex: "#10B981")
    }

    private var confidenceLabel: String {
        "\(Int((edge.confidence * 100).rounded()))% confidence"
    }
}

// MARK: - Strength Bar

private struct StrengthBar: View {
    let strength: Double     // −1…1
    let confounded: Bool

    var body: some View {
        GeometryReader { geo in
            let half = geo.size.width / 2
            let magnitude = min(1.0, abs(strength))
            let barColor: Color = confounded
                ? DS.Color.textTertiary
                : (strength < 0 ? Color(hex: "#EF4444") : Color(hex: "#10B981"))

            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 2)
                    .frame(height: 4)
                    .foregroundStyle(DS.Color.surfaceRecessed)

                HStack(spacing: 0) {
                    // Left half fills for negative associations.
                    HStack {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: strength < 0 ? half * magnitude : 0, height: 4)
                            .foregroundStyle(barColor)
                    }
                    .frame(width: half)

                    // Right half fills for positive associations.
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: strength >= 0 ? half * magnitude : 0, height: 4)
                            .foregroundStyle(barColor)
                        Spacer(minLength: 0)
                    }
                    .frame(width: half)
                }
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RelationshipGraphView()
    }
}
