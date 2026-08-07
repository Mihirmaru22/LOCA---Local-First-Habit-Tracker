//
//  InferenceTypes.swift
//  LOCA
//
//  Shared value types for the inference layer.
//  This file is compiled into both the main app and LOCAWidgetExtension
//  so that InferredStateModel (which is also shared) can reference these types.
//

import Foundation

// MARK: - Inference Provenance (C1.2)

/// What produced an inferred value: which sources contributed, how many samples,
/// over what time window, and whether the residual uncertainty is reducible.
/// Carried on every .measured result so callers can answer "where did this come
/// from?" without a second query.
struct InferenceProvenance: Codable {
    let sources: [String]               // SignalSource.rawValue for each contributing source
    let sampleCount: Int                // total samples across all contributing sources
    let windowStart: Date
    let windowEnd: Date
    // C1.3: whether the remaining uncertainty is epistemic (reducible via more data)
    // or aleatoric (inherent noise; more data won't help).
    let uncertaintyType: UncertaintyType

    var contributingSourceSet: Set<SignalSource> {
        Set(sources.compactMap { SignalSource(rawValue: $0) })
    }

    static let zero = InferenceProvenance(
        sources: [],
        sampleCount: 0,
        windowStart: .distantPast,
        windowEnd: .distantPast,
        uncertaintyType: .epistemic
    )

    /// C1.3: Factory that assigns uncertainty type from sample count.
    /// sampleCount < 3 → .epistemic (reducible: more data would help).
    /// sampleCount >= 3 → .aleatoric (inherent: more data won't eliminate the spread).
    static func create(
        sources: [String],
        sampleCount: Int,
        windowStart: Date,
        windowEnd: Date
    ) -> InferenceProvenance {
        let type: UncertaintyType = sampleCount < 3 ? .epistemic : .aleatoric
        return InferenceProvenance(
            sources: sources,
            sampleCount: sampleCount,
            windowStart: windowStart,
            windowEnd: windowEnd,
            uncertaintyType: type
        )
    }

    func jsonEncoded() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decode(from json: String) -> InferenceProvenance? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(InferenceProvenance.self, from: data)
    }
}

// MARK: - Inference Result

/// C1.1: Absence-carrying result type.
/// `.absent` = no evidence arrived (structurally distinct from measured-neutral).
/// `.measured` = at least one real signal or user log contributed, with provenance.
enum InferenceResult {
    case absent(uncertainty: Double)
    case measured(value: Double, uncertainty: Double, provenance: InferenceProvenance)

    /// 0.0 when absent; the inferred value otherwise.
    var value: Double {
        switch self {
        case .absent: return 0.0
        case .measured(let v, _, _): return v
        }
    }

    /// Full uncertainty for absent states (1.0); inferred uncertainty otherwise.
    var uncertainty: Double {
        switch self {
        case .absent(let u): return u
        case .measured(_, let u, _): return u
        }
    }

    var isAbsent: Bool {
        if case .absent = self { return true }
        return false
    }

    var provenance: InferenceProvenance {
        switch self {
        case .absent: return .zero
        case .measured(_, _, let p): return p
        }
    }

    var provenanceJSON: String? {
        provenance.jsonEncoded()
    }
}
