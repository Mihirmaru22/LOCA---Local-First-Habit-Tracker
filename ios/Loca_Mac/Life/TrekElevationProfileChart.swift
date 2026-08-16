import SwiftUI
import Charts

// MARK: - TrekElevationProfileChart

/// High-fidelity SwiftCharts alpine elevation visualizer for Pluto's Trek Atlas.
/// Features glowing cyan/purple gradient terrain fills, peak summit milestones,
/// and responsive layout.
struct TrekElevationProfileChart: View {

    let trek: TrekRecord
    let points: [ElevationPoint]
    var onScrubPoint: ((ElevationPoint?) -> Void)? = nil

    @State private var scrubbedDistance: Double? = nil
    @State private var isExpanded: Bool = false

    private var maxPoint: ElevationPoint? {
        points.max(by: { $0.elevationMeters < $1.elevationMeters })
    }

    private var minElevation: Double {
        let minVal = points.map(\.elevationMeters).min() ?? 0
        return max(0, minVal - (minVal * 0.1))
    }

    private var maxElevation: Double {
        let maxVal = points.map(\.elevationMeters).max() ?? 1000
        return maxVal + (maxVal * 0.15)
    }

    private var totalDistance: Double {
        points.last?.distanceKm ?? (trek.trailDistanceKm ?? 10.0)
    }

    private var currentScrubbedPoint: ElevationPoint? {
        guard let dist = scrubbedDistance else { return nil }
        return points.min(by: { abs($0.distanceKm - dist) < abs($1.distanceKm - dist) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Header with Altitude Range or Active Scrub HUD
            HStack {
                if let pt = currentScrubbedPoint {
                    // Active Scrubbing HUD
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Text("📍")
                                .font(.system(size: 9))
                            Text(String(format: "%.1f km", pt.distanceKm))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white)
                        }

                        HStack(spacing: 3) {
                            Text("⛰️")
                                .font(.system(size: 9))
                            Text("\(Int(pt.elevationMeters).formatted()) m")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.cyan)
                        }

                        HStack(spacing: 3) {
                            Text(pt.formattedGrade)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(gradeColor(for: pt.gradePercentage))
                            Text(gradeDescription(for: pt.gradePercentage))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cyan.opacity(0.3), lineWidth: 0.5))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.cyan)
                        Text("ELEVATION PROFILE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    Spacer()

                    if let maxPoint {
                        Text("Peak: \(Int(maxPoint.elevationMeters).formatted()) m")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.cyan)
                    }

                    Button {
                        isExpanded = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding(2)
                    }
                    .buttonStyle(.plain)
                    .help("Expand Elevation Study")
                }
            }

            // Main Chart Canvas
            Chart {
                // 1. Terrain Gradient Area Fill
                ForEach(points) { pt in
                    AreaMark(
                        x: .value("Distance", pt.distanceKm),
                        yStart: .value("Baseline", minElevation),
                        yEnd: .value("Elevation", pt.elevationMeters)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.38),
                                Color.purple.opacity(0.18),
                                Color.purple.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                }

                // 2. Neon Ridge Line Mark
                ForEach(points) { pt in
                    LineMark(
                        x: .value("Distance", pt.distanceKm),
                        y: .value("Elevation", pt.elevationMeters)
                    )
                    .foregroundStyle(Color.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }

                // 3. Peak Summit Milestone Annotation
                if let maxPoint {
                    PointMark(
                        x: .value("Distance", maxPoint.distanceKm),
                        y: .value("Elevation", maxPoint.elevationMeters)
                    )
                    .symbol {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .shadow(color: Color.cyan, radius: 4)
                    }
                    .annotation(position: .top) {
                        HStack(spacing: 3) {
                            Text("⛰️ Summit")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("\(Int(maxPoint.elevationMeters))m")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.cyan)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cyan.opacity(0.5), lineWidth: 0.5))
                    }
                }

                // 4. Interactive Rule Scrub Line
                if let scrubbedDistance {
                    RuleMark(x: .value("ScrubDistance", scrubbedDistance))
                        .foregroundStyle(Color.cyan.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                    if let pt = currentScrubbedPoint {
                        PointMark(
                            x: .value("Distance", pt.distanceKm),
                            y: .value("Elevation", pt.elevationMeters)
                        )
                        .symbol {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                                .shadow(color: Color.cyan, radius: 6)
                        }
                    }
                }
            }
            .chartYScale(domain: minElevation...maxElevation)
            .chartXScale(domain: 0...max(0.1, totalDistance))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        if let ele = value.as(Double.self) {
                            Text("\(Int(ele))m")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        if let dist = value.as(Double.self) {
                            Text(String(format: "%.1f km", dist))
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geo[proxy.plotFrame!].origin
                                    let locationX = value.location.x - origin.x
                                    if let distance: Double = proxy.value(atX: locationX) {
                                        let clamped = max(0, min(totalDistance, distance))
                                        self.scrubbedDistance = clamped
                                        self.onScrubPoint?(self.currentScrubbedPoint)
                                    }
                                }
                                .onEnded { _ in
                                    self.scrubbedDistance = nil
                                    self.onScrubPoint?(nil)
                                }
                        )
                }
            }
            .frame(height: 130)
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(DS.Color.surfaceRecessed.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .sheet(isPresented: $isExpanded) {
            TrekElevationExpandedModal(
                trek: trek,
                points: points,
                onScrubPoint: onScrubPoint,
                onDismiss: {
                    isExpanded = false
                }
            )
        }
    }

    private func gradeColor(for grade: Double) -> Color {
        let absGrade = abs(grade)
        if absGrade < 8.0 {
            return Color.green
        } else if absGrade < 18.0 {
            return Color.cyan
        } else if absGrade < 30.0 {
            return Color.orange
        } else {
            return Color.red
        }
    }

    private func gradeDescription(for grade: Double) -> String {
        let absGrade = abs(grade)
        let direction = grade >= 0 ? "Ascent" : "Descent"
        if absGrade < 5.0 {
            return "Gentle \(direction)"
        } else if absGrade < 15.0 {
            return "Moderate \(direction)"
        } else if absGrade < 28.0 {
            return "Steep \(direction)"
        } else {
            return "Alpine Expert"
        }
    }
}
