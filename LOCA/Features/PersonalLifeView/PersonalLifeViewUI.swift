//
//  PersonalLifeViewUI.swift
//  LOCA
//
//  Phase 4 — Personal Life View UI renderer
//  Renders ComposedView as bendable interactive scene
//

import SwiftUI

struct PersonalLifeViewUI: View {
    let composedView: ComposedView
    @State private var isShowingCounterfactual = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    // MARK: - Question/Title
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Personal Perspective")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .textCase(.uppercase)

                        Text(composedView.question)
                            .font(DS.Text.heading)
                            .foregroundStyle(DS.Color.textPrimary)
                    }

                    Divider()

                    // MARK: - Timeline Visualization
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        // Stress underlay
                        StressUnderlayView(timeline: composedView.stressTimeline)
                            .frame(height: 120)

                        // Energy line (main)
                        EnergyTimelineView(timeline: composedView.energyTimeline)
                            .frame(height: 140)

                        // Mood dots
                        MoodDotsView(timeline: composedView.moodTimeline)
                            .frame(height: 80)
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // MARK: - Life Event Markers
                    if !composedView.eventMarkers.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("Key Moments")
                                .font(DS.Text.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(DS.Color.textPrimary)

                            ForEach(composedView.eventMarkers, id: \.timestamp) { marker in
                                EventMarkerRow(marker: marker)
                            }
                        }
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                    }

                    // MARK: - Annotations
                    if !composedView.annotations.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            Text("Notable Patterns")
                                .font(DS.Text.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(DS.Color.textPrimary)

                            ForEach(composedView.annotations, id: \.timestamp) { annotation in
                                AnnotationRow(annotation: annotation)
                            }
                        }
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                    }

                    // MARK: - Counterfactual Toggle
                    if let counterfactualVar = composedView.counterfactualVariable {
                        VStack(alignment: .leading, spacing: DS.Space.sm) {
                            HStack {
                                Text("Explore Counterfactual")
                                    .font(DS.Text.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(DS.Color.textPrimary)

                                Spacer()

                                Toggle("", isOn: $isShowingCounterfactual)
                                    .onChange(of: isShowingCounterfactual) { oldValue, newValue in
                                        // Trigger counterfactual re-composition
                                    }
                            }

                            if isShowingCounterfactual {
                                Text(counterfactualVar)
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .italic()
                            }
                        }
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                    }

                    // MARK: - Uncertainty Legend
                    UncertaintyLegendView()

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle("Your Life")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Stress Underlay

private struct StressUnderlayView: View {
    let timeline: [TimelinePoint]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background (stress intensity)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#FEE2E2").withAlphaComponent(0.1),
                    Color(hex: "#EF4444").withAlphaComponent(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(timeline, id: \.timestamp) { point in
                    VStack(spacing: 0) {
                        Spacer()

                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: CGFloat(point.value * 100))
                            .foregroundStyle(Color(hex: "#EF4444"))
                            .opacity(opacityForConfidence(point.confidence))
                    }
                    .frame(height: 120)
                }
            }
            .padding(DS.Space.sm)
        }
        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
    }

    private func opacityForConfidence(_ confidence: ConfidenceLevel) -> Double {
        switch confidence {
        case .crisp: return 0.6
        case .soft: return 0.4
        case .speculative: return 0.2
        }
    }
}

// MARK: - Energy Timeline

private struct EnergyTimelineView: View {
    let timeline: [TimelinePoint]

    var body: some View {
        Canvas { context in
            guard timeline.count > 1 else { return }

            let width = context.size.width
            let height = context.size.height
            let points = timeline

            // Draw line
            var path = Path()
            for (index, point) in points.enumerated() {
                let x = (CGFloat(index) / CGFloat(points.count - 1)) * width
                let y = height - (CGFloat(point.value) * height)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Render with confidence-based styling
            let strokeColor = Color(hex: "#10B981")

            for (index, point) in points.enumerated() {
                let x = (CGFloat(index) / CGFloat(points.count - 1)) * width
                let y = height - (CGFloat(point.value) * height)

                let opacity = opacityForConfidence(point.confidence)
                let size = sizeForConfidence(point.confidence)

                var pointPath = Path(ellipseIn: CGRect(
                    x: x - size / 2,
                    y: y - size / 2,
                    width: size,
                    height: size
                ))

                context.fill(
                    pointPath,
                    with: .color(strokeColor.opacity(opacity))
                )
            }

            var strokeStyle = StrokeStyle(lineWidth: 2)
            context.stroke(path, with: .color(strokeColor.opacity(0.8)), style: strokeStyle)
        }
    }

    private func opacityForConfidence(_ confidence: ConfidenceLevel) -> Double {
        switch confidence {
        case .crisp: return 1.0
        case .soft: return 0.6
        case .speculative: return 0.25
        }
    }

    private func sizeForConfidence(_ confidence: ConfidenceLevel) -> CGFloat {
        switch confidence {
        case .crisp: return 5
        case .soft: return 4
        case .speculative: return 3
        }
    }
}

// MARK: - Mood Dots

private struct MoodDotsView: View {
    let timeline: [TimelinePoint]

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ForEach(timeline, id: \.timestamp) { point in
                VStack(spacing: 4) {
                    Circle()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color(hex: "#F59E0B"))
                        .opacity(opacityForConfidence(point.confidence))

                    Text(formattedValue(point.value))
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            Spacer()
        }
    }

    private func opacityForConfidence(_ confidence: ConfidenceLevel) -> Double {
        switch confidence {
        case .crisp: return 1.0
        case .soft: return 0.6
        case .speculative: return 0.3
        }
    }

    private func formattedValue(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}

// MARK: - Event Marker Row

private struct EventMarkerRow: View {
    let marker: EventMarker

    var body: some View {
        HStack(spacing: DS.Space.md) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(.accentColor)

                    Text(marker.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                Text(formattedDate(marker.timestamp))
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Annotation Row

private struct AnnotationRow: View {
    let annotation: AnnotationPoint

    var body: some View {
        HStack(spacing: DS.Space.md) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(annotation.text)
                    .font(.caption)
                    .foregroundStyle(DS.Color.textPrimary)

                Text(formattedDate(annotation.timestamp))
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Uncertainty Legend

private struct UncertaintyLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Reading the View")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: DS.Space.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 3)
                        .frame(width: 40)
                        .foregroundStyle(.gray)
                        .opacity(1.0)

                    Text("Certain")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 3)
                        .frame(width: 40)
                        .foregroundStyle(.gray)
                        .opacity(0.6)

                    Text("Uncertain")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 3)
                        .frame(width: 40)
                        .foregroundStyle(.gray)
                        .opacity(0.25)

                    Text("Speculative")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Text("Fainter lines indicate less certain inferences. Solid lines show logged data or high-confidence predictions.")
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0
        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Preview

#Preview {
    let sampleTimeline = (0..<20).map { i in
        TimelinePoint(
            timestamp: Date().addingTimeInterval(Double(i) * 3600),
            value: Double.random(in: 0.3...0.8),
            uncertainty: Double.random(in: 0.1...0.4),
            confidence: ConfidenceLevel(uncertainty: Double.random(in: 0.1...0.4)),
            renderingStyle: "crisp"
        )
    }

    let sampleView = ComposedView(
        question: "Am I happier since starting the internship?",
        startDate: Date().addingTimeInterval(-60 * 86400),
        endDate: Date(),
        energyTimeline: sampleTimeline,
        stressTimeline: sampleTimeline,
        focusTimeline: sampleTimeline,
        moodTimeline: sampleTimeline,
        eventMarkers: [
            EventMarker(
                timestamp: Date().addingTimeInterval(-30 * 86400),
                eventType: "workChange",
                label: "Started Internship",
                metadata: ["summary": "Major schedule shift"]
            )
        ],
        annotations: []
    )

    PersonalLifeViewUI(composedView: sampleView)
}
