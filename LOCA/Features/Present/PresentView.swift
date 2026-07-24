//
//  PresentView.swift
//  LOCA
//
//  Phase 8, Session 8.1 — The Present.
//
//  The vantage the user arrives at every time they open the life surface.
//  Not a dashboard, not a summary, not a home screen of controls. A place.
//  Exactly two moves from here: Reach (into time) or Ask (a question).
//  At most one soft thread. Never more than one thing to read at a time.
//
//  The Present is "truthfully different every day" because it reads from
//  live data. Its aliveness is real, not decorative.
//

import SwiftUI
import SwiftData

// MARK: - Present View

struct PresentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scene: PresentScene = .empty
    @State private var isLoading = true
    @State private var showReach = false
    @State private var showAsk = false
    @State private var askPrefill: String = ""

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                // Top bar: dismiss only. No title, no navigation trail.
                topBar

                Spacer()

                // The scene: the present, composed.
                if isLoading {
                    loadingState
                } else {
                    sceneContent
                }

                Spacer()

                // The two moves.
                bottomBar
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showReach) {
            ReachView(scene: scene)
        }
        .sheet(isPresented: $showAsk) {
            AskView(prefill: askPrefill) { _ in
                askPrefill = ""
            }
        }
        .task { await loadScene() }
    }

    // MARK: - Background

    private var background: some View {
        // Time-of-day aware background: dim if night, warm if evening.
        let color: Color = {
            switch scene.timeOfDay {
            case .morning:   return Color(hue: 0.58, saturation: 0.04, brightness: 0.97)
            case .afternoon: return Color(hue: 0.0, saturation: 0.0, brightness: 0.98)
            case .evening:   return Color(hue: 0.07, saturation: 0.05, brightness: 0.96)
            case .night:     return Color(hue: 0.66, saturation: 0.06, brightness: 0.10)
            }
        }()
        return color.ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.body)
                    .foregroundStyle(textColor.opacity(0.4))
                    .padding(DS.Space.md)
            }

            Spacer()

            // Explore: secondary path to the structured browse surfaces.
            NavigationLink {
                PersonalLifeListView()
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.body)
                    .foregroundStyle(textColor.opacity(0.25))
                    .padding(DS.Space.md)
            }
        }
        .padding(.top, 52)
        .padding(.horizontal, DS.Space.sm)
    }

    // MARK: - Scene Content

    private var sceneContent: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            // Time context and chapter — anchoring the present.
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                if !scene.timeContext.isEmpty {
                    Text(scene.timeContext.capitalized)
                        .font(.caption)
                        .foregroundStyle(textColor.opacity(0.35))
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                if let chapter = scene.chapterName {
                    Text(chapter)
                        .font(.caption)
                        .foregroundStyle(textColor.opacity(0.45))
                }
            }

            // The headline — the primary observation.
            Text(scene.headline)
                .font(.title3)
                .fontWeight(.light)
                .foregroundStyle(textColor.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Support — a secondary observation.
            if let support = scene.support {
                Text(support)
                    .font(DS.Text.body)
                    .foregroundStyle(textColor.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Direction — quietly held beneath the present.
            if let dir = scene.directionStatement {
                Text("↗ \(dir)")
                    .font(.caption)
                    .foregroundStyle(textColor.opacity(0.30))
                    .italic()
            }

            // The soft thread — at most one. A gentle invitation, never a demand.
            if let thread = scene.softThread {
                softThreadButton(thread)
            }
        }
        .padding(.horizontal, DS.Space.xxxl)
        .animation(.easeInOut(duration: 0.4), value: scene.headline)
    }

    // MARK: - Soft Thread

    private func softThreadButton(_ thread: SoftThread) -> some View {
        Button {
            askPrefill = thread.prefilledQuestion
            showAsk = true
        } label: {
            Text(thread.label)
                .font(.caption)
                .foregroundStyle(textColor.opacity(0.45))
                .underline(color: textColor.opacity(0.2))
                .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        Text("…")
            .font(.title3)
            .foregroundStyle(textColor.opacity(0.3))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            // Reach — the time gesture.
            Button {
                showReach = true
            } label: {
                VStack(spacing: DS.Space.xs) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                    Text("Reach")
                        .font(.caption2)
                }
                .foregroundStyle(textColor.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.lg)
            }

            Divider()
                .frame(height: 32)
                .foregroundStyle(textColor.opacity(0.1))

            // Ask — a question.
            Button {
                askPrefill = ""
                showAsk = true
            } label: {
                VStack(spacing: DS.Space.xs) {
                    Image(systemName: "text.cursor")
                        .font(.title3)
                    Text("Ask")
                        .font(.caption2)
                }
                .foregroundStyle(textColor.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.lg)
            }
        }
        .background(.ultraThinMaterial)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private var textColor: Color {
        scene.timeOfDay == .night ? .white : .black
    }

    private func loadScene() async {
        isLoading = true
        scene = (try? PresentComposer.shared.compose(modelContext: modelContext)) ?? .empty
        withAnimation(.easeIn(duration: 0.3)) { isLoading = false }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PresentView()
    }
}
