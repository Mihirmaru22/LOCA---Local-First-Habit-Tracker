//
//  InterventionNarrator.swift
//  LOCA
//
//  Phase 5.4 — Optional LLM narration (grounded only).
//
//  Thin layer on structured output. Kill-switch if output can't be grounded.
//  If LLM is unavailable or output isn't grounded, fall back to templates.
//

import Foundation

/// Generates intervention text, optionally using LLM but with grounding validation.
/// Falls back to templates if LLM unavailable or output ungrounded.
struct InterventionNarrator {

    /// Generate intervention text from a prediction.
    /// Attempts LLM narration if enabled; falls back to template.
    static func narrate(
        prediction: RelapsePrediction,
        useLLM: Bool = false  // Opt-in, defaults to template
    ) -> String {
        // If LLM disabled, use template directly
        guard useLLM else {
            return InterventionGenerator.generateIntervention(from: prediction)
        }

        // Attempt LLM narration with grounding validation
        if let llmNarration = attemptLLMNarration(for: prediction) {
            // Validate that narration is grounded in the data
            if isGrounded(narration: llmNarration, prediction: prediction) {
                return llmNarration
            }
        }

        // Fallback: template (safe, always grounded)
        return InterventionGenerator.generateIntervention(from: prediction)
    }

    // MARK: - LLM integration (optional)

    /// Attempt to generate narration via LLM (Phase 5.4).
    /// In production, this would call Claude/GPT API.
    /// For now, returns nil (feature not yet integrated).
    private static func attemptLLMNarration(for prediction: RelapsePrediction) -> String? {
        // TODO: Integrate LLM API here (Claude, GPT, etc.)
        // Example prompt:
        //   "Generate one dismissible sentence for: \(prediction.reasoning)"
        //   Constraints: <100 chars, action-oriented, not preachy

        // For now: LLM is disabled (returns nil)
        return nil
    }

    /// Validate that LLM output is grounded in the prediction data (Phase 5.4).
    /// Kill-switch: if narration contains claims not in reasoning, suppress.
    private static func isGrounded(narration: String, prediction: RelapsePrediction) -> Bool {
        // Check that narration doesn't make ungrounded claims
        let lower = narration.lowercased()

        // Example checks:
        // - If narration mentions "8 days streak" but prediction says 7, it's not grounded
        // - If narration makes a causal claim ("sleep affects running"), check it's in reasoning

        // For now: basic validation
        // In production, this would be more sophisticated (NLP, structured claim extraction)

        // Check that narration doesn't introduce new numbers/facts not in reasoning
        let reasoningWords = Set(prediction.reasoning.lowercased().split(separator: " ").map { String($0) })
        let narrationWords = Set(lower.split(separator: " ").map { String($0) })

        // If narration adds > 20% new vocabulary, it's likely adding ungrounded claims
        let newWords = narrationWords.subtracting(reasoningWords).count
        let totalWords = narrationWords.count
        let newRatio = Double(newWords) / Double(max(totalWords, 1))

        // Threshold: allow up to 30% new words (reframing is OK, new facts are not)
        return newRatio < 0.3
    }
}

/// Validator for ensuring LLM output is grounded (Phase 5.4).
struct GroundingValidator {

    /// Claims in the prediction data (facts we know are true).
    let claimsInData: Set<String>

    /// Check if an LLM output only uses grounded claims.
    func validate(_ text: String) -> Bool {
        // Extract claims from text (simplified: noun phrases)
        let textClaims = extractClaims(from: text)

        // All claims must either:
        // 1. Be in the data, OR
        // 2. Be a rephasing (synonyms, passive voice, etc.)

        // For now: simple substring check
        return !textClaims.contains { claim in
            !claimsInData.contains(where: { groundedClaim in
                claim.contains(groundedClaim) || groundedClaim.contains(claim)
            })
        }
    }

    private func extractClaims(from text: String) -> [String] {
        // Simplified claim extraction: split by common conjunctions
        return text.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }
    }
}
