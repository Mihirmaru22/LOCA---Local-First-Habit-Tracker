import SwiftUI
import Charts

// MARK: - TrekElevationExpandedModal

/// Full-width panoramic elevation study drawer for Pluto's Trek Atlas.
/// Displays high-resolution terrain gradients, alpine zone breakdowns,
/// average/max slope grades, and interactive scrubbing.
struct TrekElevationExpandedModal: View {

    let trek: TrekRecord
    let points: [ElevationPoint]
    var onScrubPoint: ((ElevationPoint?) -> Void)? = nil
    let onDismiss: () -> Void

    @State private var scrubbedDistance: Double? = nil

    private var maxPoint: ElevationPoint? {
        points.max(by: { $0.elevationMeters < $1.elevationMeters })
    }

    private var minPoint: ElevationPoint? {
        points.min(by: { $0.elevationMeters < $1.elevationMeters })
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

    private var maxGrade: Double {
        points.map { abs($0.gradePercentage) }.max() ?? 0.0
    }

    private var avgGrade: Double {
        guard !points.isEmpty else { return 0.0 }
        let total = points.map { abs($0.gradePercentage) }.reduce(0, +)
        return total / Double(points.count)
    }

    var body: some View {
        ZStack {

            // Backdrop
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 0) {

                // Top Header Bar
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(trek.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Panoramic Elevation Study")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
                        }

                        Text("\(trek.region), \(trek.country) · \(trek.formattedElevation)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DS.Space.xl)
                .padding(.vertical, DS.Space.lg)
                .background(.ultraThinMaterial.opacity(0.8))

                Divider().overlay(Color.white.opacity(0.1))

                // Scrollable Content
                ScrollView {
                    VStack(spacing: DS.Space.lg) {

                        // 6-Grid Telemetry Cards
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            TelemetryPill(title: "PEAK ALTITUDE", value: "\(Int(trek.elevationMeters).formatted()) m", color: .cyan)
                            TelemetryPill(title: "TRAIL DISTANCE", value: String(format: "%.1f km", totalDistance), color: .white)
                            TelemetryPill(title: "VERT GAIN", value: trek.formattedGain ?? "+0 m", color: .purple)
                            TelemetryPill(title: "MAX GRADE", value: String(format: "%.1f%%", maxGrade), color: .orange)
                        }

                        // Main High-Res Panoramic Chart
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("TOPOGRAPHICAL ASCENT CURVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)

                                Spacer()

                                if let pt = currentScrubbedPoint {
                                    HStack(spacing: 6) {
                                        Text("Distance: \(String(format: "%.1f km", pt.distanceKm))")
                                        Text("·")
                                        Text("Altitude: \(Int(pt.elevationMeters))m")
                                        Text("·")
                                        Text("Grade: \(pt.formattedGrade)")
                                            .foregroundStyle(Color.cyan)
                                    }
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.cyan.opacity(0.15), in: Capsule())
                                }
                            }

                            Chart {
                                ForEach(points) { pt in
                                    AreaMark(
                                        x: .value("Distance", pt.distanceKm),
                                        yStart: .value("Baseline", minElevation),
                                        yEnd: .value("Elevation", pt.elevationMeters)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color.cyan.opacity(0.45),
                                                Color.purple.opacity(0.22),
                                                Color.purple.opacity(0.02)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.monotone)

                                    LineMark(
                                        x: .value("Distance", pt.distanceKm),
                                        y: .value("Elevation", pt.elevationMeters)
                                    )
                                    .foregroundStyle(Color.cyan)
                                    .lineStyle(StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))
                                    .interpolationMethod(.monotone)
                                }

                                if let maxPoint {
                                    PointMark(
                                        x: .value("Distance", maxPoint.distanceKm),
                                        y: .value("Elevation", maxPoint.elevationMeters)
                                    )
                                    .symbol {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 10, height: 10)
                                            .overlay(Circle().stroke(Color.cyan, lineWidth: 2.5))
                                            .shadow(color: Color.cyan, radius: 8)
                                    }
                                    .annotation(position: .top) {
                                        Text("⛰️ Peak · \(Int(maxPoint.elevationMeters))m")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
                                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.cyan, lineWidth: 1))
                                    }
                                }

                                if let scrubbedDistance {
                                    RuleMark(x: .value("ScrubDistance", scrubbedDistance))
                                        .foregroundStyle(Color.cyan)
                                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                                    if let pt = currentScrubbedPoint {
                                        PointMark(
                                            x: .value("Distance", pt.distanceKm),
                                            y: .value("Elevation", pt.elevationMeters)
                                        )
                                        .symbol {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 10, height: 10)
                                                .overlay(Circle().stroke(Color.cyan, lineWidth: 3))
                                                .shadow(color: Color.cyan, radius: 10)
                                        }
                                    }
                                }
                            }
                            .chartYScale(domain: minElevation...maxElevation)
                            .chartXScale(domain: 0...max(0.1, totalDistance))
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                        .foregroundStyle(Color.white.opacity(0.1))
                                    AxisValueLabel {
                                        if let ele = value.as(Double.self) {
                                            Text("\(Int(ele))m")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.7))
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks(position: .bottom, values: .automatic(desiredCount: 6)) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                        .foregroundStyle(Color.white.opacity(0.1))
                                    AxisValueLabel {
                                        if let dist = value.as(Double.self) {
                                            Text(String(format: "%.1f km", dist))
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.7))
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
                            .frame(height: 220)
                            .padding(12)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(DS.Space.xl)
                }
            }
            .frame(width: 680, height: 480)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
        }
    }
}

// MARK: - TelemetryPill

private struct TelemetryPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(DS.Color.textTertiary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
}
