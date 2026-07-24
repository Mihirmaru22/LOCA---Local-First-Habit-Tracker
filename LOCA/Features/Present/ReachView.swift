//
//  ReachView.swift
//  LOCA
//
//  Phase 8, Session 8.2 — The Reach gesture.
//
//  One continuous gesture that moves through time. Near: moments, grainy.
//  Pull back: texture without discrete identity. Further: chapter shape.
//  All the way: the whole life, chapters as territories, events as seams.
//
//  Rules:
//  - No date picker. No slider. No discrete day/week/month modes.
//  - Navigate by meaning, not by date. Life events stay fixed as landmarks.
//  - The transition is smooth and continuous — you are not switching modes.
//  - What isn't there yet is shown honestly as thin, not faked as rich.
//

import SwiftUI
import SwiftData

// MARK: - Reach View

struct ReachView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let scene: PresentScene   // The composed Present — the starting point.

    @State private var depth: Double = 0.0          // 0 = now, 1 = oldest
    @GestureState private var dragDelta: Double = 0
    @State private var slices: [ReachSlice] = []

    private var currentDepth: Double {
        min(1.0, max(0.0, depth + dragDelta))
    }

    var body: some View {
        ZStack {
            depthBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(foregroundColor.opacity(0.35))
                            .padding(DS.Space.md)
                    }
                    Spacer()
                }
                .padding(.top, 52)
                .padding(.horizontal, DS.Space.sm)

                Spacer()

                // The content at the current depth.
                depthContent
                    .padding(.horizontal, DS.Space.xxxl)
                    .animation(.easeOut(duration: 0.18), value: depthBand)

                Spacer()

                // Depth track — shows where you are, invites the gesture.
                depthTrack
                    .padding(.horizontal, DS.Space.xl)
                    .padding(.bottom, DS.Space.xxl)
            }
        }
        // The reach gesture: vertical drag maps to depth.
        .gesture(
            DragGesture(minimumDistance: 8)
                .updating($dragDelta) { value, state, _ in
                    // Dragging up → going deeper (further back in time).
                    let sensitivity = 0.8 / UIScreen.main.bounds.height
                    state = -value.translation.height * sensitivity
                }
                .onEnded { value in
                    let sensitivity = 0.8 / UIScreen.main.bounds.height
                    depth = min(1.0, max(0.0, depth - value.translation.height * sensitivity))
                }
        )
        .task { loadSlices() }
    }

    // MARK: - Depth Band

    /// Four bands map to the four semantic depths.
    private var depthBand: Int {
        switch currentDepth {
        case ..<0.25: return 0   // present / recent days
        case ..<0.55: return 1   // recent weeks
        case ..<0.80: return 2   // chapter
        default:      return 3   // full life
        }
    }

    // MARK: - Background

    private var depthBackground: some View {
        // Background darkens as you go further back — depth is felt, not labeled.
        let darkness = 0.97 - currentDepth * 0.28
        return Color(hue: 0.61, saturation: 0.04, brightness: darkness)
    }

    private var foregroundColor: Color {
        currentDepth > 0.6 ? .white : .black
    }

    // MARK: - Content

    private var depthContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            depthLabel

            switch depthBand {
            case 0: presentDepthContent
            case 1: recentWeeksContent
            case 2: chapterContent
            default: fullLifeContent
            }
        }
    }

    private var depthLabel: some View {
        let labels = ["Now", "This week", "This chapter", "Your whole life"]
        return Text(labels[depthBand])
            .font(.caption)
            .foregroundStyle(foregroundColor.opacity(0.3))
            .textCase(.uppercase)
            .tracking(1.5)
    }

    // Depth 0 — mirrors the Present.
    private var presentDepthContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            Text(scene.headline)
                .font(.title3)
                .fontWeight(.light)
                .foregroundStyle(foregroundColor.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            if let support = scene.support {
                Text(support)
                    .font(DS.Text.body)
                    .foregroundStyle(foregroundColor.opacity(0.5))
            }

            Text("Pull up to reach further back.")
                .font(.caption2)
                .foregroundStyle(foregroundColor.opacity(0.2))
                .italic()
        }
    }

    // Depth 1 — recent week texture.
    private var recentWeeksContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            Text("The last seven days.")
                .font(.title3)
                .fontWeight(.light)
                .foregroundStyle(foregroundColor.opacity(0.85))

            if !scene.signals.isEmpty {
                weekSignalsView
            } else {
                Text("Not enough data to read the last week yet.")
                    .font(DS.Text.body)
                    .foregroundStyle(foregroundColor.opacity(0.4))
            }
        }
    }

    private var weekSignalsView: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            ForEach(scene.signals.filter { abs($0.delta) >= 0.03 }, id: \.dimension.rawValue) { signal in
                SignalRow(signal: signal, foreground: foregroundColor)
            }
        }
    }

    // Depth 2 — chapter shape.
    private var chapterContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            if let slice = slices.first(where: { $0.depth == .chapter }) {
                Text(slice.headline)
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(foregroundColor.opacity(0.85))

                if let body = slice.body {
                    Text(body)
                        .font(DS.Text.body)
                        .foregroundStyle(foregroundColor.opacity(0.5))
                }
            } else {
                Text("Your current chapter.")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(foregroundColor.opacity(0.85))
            }
        }
    }

    // Depth 3 — all chapters, landmarks.
    private var fullLifeContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            if let slice = slices.first(where: { $0.depth == .fullLife }) {
                Text(slice.headline)
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(foregroundColor.opacity(0.85))

                if let body = slice.body {
                    Text(body)
                        .font(DS.Text.body)
                        .foregroundStyle(foregroundColor.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !slice.landmarks.isEmpty {
                    landmarkList(slice.landmarks)
                }
            } else {
                Text("Your whole life.")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(foregroundColor.opacity(0.85))
                Text("Not enough history yet to see chapters. It builds over time.")
                    .font(DS.Text.body)
                    .foregroundStyle(foregroundColor.opacity(0.4))
            }
        }
    }

    private func landmarkList(_ landmarks: [LifeLandmark]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            ForEach(landmarks) { lm in
                HStack(spacing: DS.Space.sm) {
                    Image(systemName: lm.isEvent ? "diamond.fill" : "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(foregroundColor.opacity(lm.isEvent ? 0.7 : 0.4))
                    Text(lm.label)
                        .font(.caption)
                        .foregroundStyle(foregroundColor.opacity(lm.isEvent ? 0.7 : 0.45))
                }
            }
        }
    }

    // MARK: - Depth Track

    private var depthTrack: some View {
        VStack(spacing: DS.Space.sm) {
            Text(depthHint)
                .font(.caption2)
                .foregroundStyle(foregroundColor.opacity(0.2))
                .italic()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 3)
                        .foregroundStyle(foregroundColor.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: geo.size.width * currentDepth, height: 3)
                        .foregroundStyle(foregroundColor.opacity(0.3))
                }
            }
            .frame(height: 3)

            HStack {
                Text("Now")
                Spacer()
                Text("Your whole life")
            }
            .font(.caption2)
            .foregroundStyle(foregroundColor.opacity(0.18))
        }
    }

    private var depthHint: String {
        switch depthBand {
        case 0: return "Drag up to reach further back in time"
        case 1: return "The grain of individual days"
        case 2: return "The shape of this chapter"
        case 3: return "Chapters as distinct territories"
        default: return ""
        }
    }

    // MARK: - Data

    private func loadSlices() {
        slices = (try? PresentComposer.shared.reachSlices(modelContext: modelContext)) ?? []
    }
}

// MARK: - Signal Row

private struct SignalRow: View {
    let signal: StateSignal
    let foreground: Color

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Text(signal.dimension.label)
                .font(.caption)
                .foregroundStyle(foreground.opacity(0.5))
                .frame(width: 52, alignment: .leading)

            // Bar: centered on 0, extends left (below) or right (above) baseline.
            GeometryReader { geo in
                let half = geo.size.width / 2
                let magnitude = min(1.0, abs(signal.delta) / 0.3)
                let barColor = signal.delta > 0
                    ? Color(hex: "#10B981").opacity(0.7)
                    : Color(hex: "#EF4444").opacity(0.7)

                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .frame(height: 3)
                        .foregroundStyle(foreground.opacity(0.08))

                    HStack(spacing: 0) {
                        HStack {
                            Spacer(minLength: 0)
                            if signal.delta < 0 {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .frame(width: half * magnitude, height: 3)
                                    .foregroundStyle(barColor)
                            }
                        }
                        .frame(width: half)

                        HStack {
                            if signal.delta >= 0 {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .frame(width: half * magnitude, height: 3)
                                    .foregroundStyle(barColor)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(width: half)
                    }
                }
            }
            .frame(height: 3)

            if signal.trending {
                Image(systemName: signal.delta > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8))
                    .foregroundStyle(foreground.opacity(0.3))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReachView(scene: .empty)
}
