//
//  ViewRenderingSpecification.swift
//  LOCA
//
//  Phase 3 — View rendering specification
//  Defines visual grammar for rendering uncertain inferences as bendable Views
//

import Foundation

// MARK: - Rendering Instruction

struct RenderingInstruction {
    let value: Double
    let uncertainty: Double
    let confidence: ConfidenceLevel
    let renderingStyle: RenderingStyle
}

enum RenderingStyle {
    case crisp             // Fully opaque, sharp edges, saturated color
    case soft              // Partially transparent, blurred edges, desaturated
    case speculative       // Very faint, ghosted, near-invisible
    case uncertain         // Surrounded by halo/ring proportional to uncertainty

    static func from(confidence: ConfidenceLevel) -> RenderingStyle {
        switch confidence {
        case .crisp: return .crisp
        case .soft: return .soft
        case .speculative: return .speculative
        }
    }
}

// MARK: - Rendering Specification

struct ViewRenderingSpec {
    // Line rendering (for state timelines)
    let lineThickness: CGFloat
    let lineOpacity: Double
    let lineSaturation: Double
    let lineBlur: CGFloat

    // Point rendering (for discrete values)
    let pointRadius: CGFloat
    let pointOpacity: Double
    let pointBorderWidth: CGFloat
    let haloRadius: CGFloat

    // Color guidance
    let baseColor: String     // hex or named color
    let colorShift: String    // for desaturation in uncertain ranges

    static func crisp() -> ViewRenderingSpec {
        ViewRenderingSpec(
            lineThickness: 2.0,
            lineOpacity: 1.0,
            lineSaturation: 1.0,
            lineBlur: 0,
            pointRadius: 4,
            pointOpacity: 1.0,
            pointBorderWidth: 2,
            haloRadius: 0,
            baseColor: "#primary",
            colorShift: ""
        )
    }

    static func soft() -> ViewRenderingSpec {
        ViewRenderingSpec(
            lineThickness: 1.5,
            lineOpacity: 0.6,
            lineSaturation: 0.7,
            lineBlur: 1.5,
            pointRadius: 3,
            pointOpacity: 0.7,
            pointBorderWidth: 1,
            haloRadius: 0,
            baseColor: "#primary",
            colorShift: "desaturate(0.3)"
        )
    }

    static func speculative() -> ViewRenderingSpec {
        ViewRenderingSpec(
            lineThickness: 1,
            lineOpacity: 0.25,
            lineSaturation: 0.4,
            lineBlur: 2.5,
            pointRadius: 2.5,
            pointOpacity: 0.3,
            pointBorderWidth: 0.5,
            haloRadius: 0,
            baseColor: "#primary",
            colorShift: "desaturate(0.6)"
        )
    }

    static func uncertain(confidence: Double) -> ViewRenderingSpec {
        let baseSpec = ViewRenderingSpec.soft()
        let haloSize = max(4, (1.0 - confidence) * 16)
        return ViewRenderingSpec(
            lineThickness: baseSpec.lineThickness,
            lineOpacity: baseSpec.lineOpacity,
            lineSaturation: baseSpec.lineSaturation,
            lineBlur: baseSpec.lineBlur,
            pointRadius: baseSpec.pointRadius,
            pointOpacity: baseSpec.pointOpacity,
            pointBorderWidth: baseSpec.pointBorderWidth,
            haloRadius: haloSize,
            baseColor: baseSpec.baseColor,
            colorShift: baseSpec.colorShift
        )
    }
}

// MARK: - View Composition Guidance

struct ViewCompositionGuidance {
    // Layer ordering (depth)
    static let layerOrder: [String] = [
        "stress_underlay",        // Behind energy line
        "energy_line",            // Main temporal signal
        "mood_dots",              // Discrete points
        "event_markers",          // Vertical regime-shift lines
        "annotations",            // Callouts to spikes/anomalies
    ]

    // Annotation guidelines
    struct AnnotationStyle {
        let maxAnnotationsPerView: Int = 3
        let annotationOffset: CGFloat = 40  // pixels from spike
        let fontSize: CGFloat = 12
        let maxTextLength: Int = 40
    }

    // Color scheme per state
    static let stateColors: [String: String] = [
        "energy": "#10B981",      // Emerald (vitality)
        "stress": "#EF4444",      // Red (arousal)
        "focus": "#3B82F6",       // Blue (clarity)
        "mood": "#F59E0B",        // Amber (warmth)
    ]

    // Counterfactual rendering (for bendable interactions)
    struct CounterfactualStyle {
        let desaturation: Double = 0.4
        let opacityReduction: Double = 0.4
        let labelText: String = "if you hadn't..."
    }
}

// MARK: - Uncertainty Halo Rendering

struct UncertaintyHalo {
    let centerValue: Double
    let uncertainty: Double
    let radiusRange: ClosedRange<CGFloat>  // min and max halo sizes

    var haloRadius: CGFloat {
        let minRadius = radiusRange.lowerBound
        let maxRadius = radiusRange.upperBound
        return minRadius + (uncertainty * (maxRadius - minRadius))
    }

    var haloOpacity: Double {
        0.15 * uncertainty  // More uncertain = less visible halo
    }

    var haloColor: String {
        if uncertainty < 0.3 {
            return "#A0AEC0"  // Light gray for slight uncertainty
        } else if uncertainty < 0.6 {
            return "#6B7280"  // Medium gray
        } else {
            return "#4B5563"  // Dark gray for high uncertainty
        }
    }
}

// MARK: - Render Instruction Generator

@MainActor
class RenderInstructionGenerator {
    func generateForState(
        state: InferredState,
        dataType: String  // "energy", "stress", "focus", "mood"
    ) -> RenderingInstruction {
        let (value, uncertainty) = extractStateData(state: state, dataType: dataType)
        let confidence = ConfidenceLevel(uncertainty: uncertainty)
        let style = RenderingStyle.from(confidence: confidence)

        return RenderingInstruction(
            value: value,
            uncertainty: uncertainty,
            confidence: confidence,
            renderingStyle: style
        )
    }

    private func extractStateData(
        state: InferredState,
        dataType: String
    ) -> (Double, Double) {
        switch dataType {
        case "energy":
            return (state.energy, state.energyUncertainty)
        case "stress":
            return (state.stress, state.stressUncertainty)
        case "focus":
            return (state.focus, state.focusUncertainty)
        case "mood":
            return (state.mood, state.moodUncertainty)
        default:
            return (0, 1.0)
        }
    }

    func generateAnnotation(
        for event: LifeEvent,
        guidance: ViewCompositionGuidance.AnnotationStyle
    ) -> String? {
        guard event.confidence >= 0.7 else { return nil }

        let eventType = event.eventType.rawValue
        let note = event.metadata["summary"] ?? eventType

        let truncated = note.prefix(guidance.maxTextLength)
        return String(truncated)
    }
}
