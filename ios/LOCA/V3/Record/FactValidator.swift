import Foundation

// MARK: - FactValidating protocol

/// Validates a FactDraft before it can enter the Record.
/// Validation is a pure, synchronous function — no side effects,
/// no Record access, no network. It either passes or rejects.
///
/// The contract: a draft that fails validation is returned to the caller
/// with a specific reason. Drafts are NEVER silently repaired.
protocol FactValidating: Sendable {
    func validate(_ draft: FactDraft) -> Result<FactDraft, ValidationError>
}

// MARK: - DefaultFactValidator

/// The canonical validator for all FactDraft kinds.
/// One validator per kind; dispatches by draft.kind.
struct DefaultFactValidator: FactValidating {

    func validate(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        // Verify payload kind matches draft kind
        guard payloadMatchesKind(draft) else {
            return .failure(.malformedPayload(
                "Payload type does not match kind '\(draft.kind.rawValue)'"
            ))
        }

        // Per-kind validation
        switch draft.kind {
        case .habitLogged:            return validateHabitLogged(draft)
        case .reflectionWritten:      return validateReflectionWritten(draft)
        case .stateCheckedIn:         return validateStateCheckedIn(draft)
        case .correctionSubmitted:    return validateCorrectionSubmitted(draft)
        case .directionChanged:       return validateDirectionChanged(draft)
        case .questionAsked:          return validateQuestionAsked(draft)
        case .permissionChanged:      return validatePermissionChanged(draft)
        case .calendarEventImported:  return validateCalendarEventImported(draft)
        case .healthSampleImported:   return validateHealthSampleImported(draft)
        case .consentChanged:         return validateConsentChanged(draft)
        case .confirmationSubmitted:  return validateConfirmationSubmitted(draft)
        case .deletionRequested:      return validateDeletionRequested(draft)
        }
    }

    // MARK: - Kind-payload consistency

    private func payloadMatchesKind(_ draft: FactDraft) -> Bool {
        switch (draft.kind, draft.payload) {
        case (.habitLogged,           .habitLogged):           return true
        case (.reflectionWritten,     .reflectionWritten):     return true
        case (.stateCheckedIn,        .stateCheckedIn):        return true
        case (.correctionSubmitted,   .correctionSubmitted):   return true
        case (.directionChanged,      .directionChanged):      return true
        case (.questionAsked,         .questionAsked):         return true
        case (.permissionChanged,     .permissionChanged):     return true
        case (.calendarEventImported, .calendarEventImported): return true
        case (.healthSampleImported,  .healthSampleImported):  return true
        case (.consentChanged,        .consentChanged):        return true
        case (.confirmationSubmitted, .confirmationSubmitted): return true
        case (.deletionRequested,     .deletionRequested):     return true
        default:                                               return false
        }
    }

    // MARK: - Per-kind rules

    private func validateHabitLogged(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .habitLogged(let p) = draft.payload else {
            return .failure(.malformedPayload("habitLogged"))
        }
        guard p.value >= 0 else {
            return .failure(.fieldOutOfBounds(field: "value", allowed: ">= 0"))
        }
        if let note = p.note, note.count > 2_000 {
            return .failure(.fieldOutOfBounds(field: "note", allowed: "<= 2000 characters"))
        }
        return .success(draft)
    }

    private func validateReflectionWritten(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .reflectionWritten(let p) = draft.payload else {
            return .failure(.malformedPayload("reflectionWritten"))
        }
        let trimmed = p.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.missingRequiredField(field: "text"))
        }
        if p.text.count > 10_000 {
            return .failure(.fieldOutOfBounds(field: "text", allowed: "<= 10000 characters"))
        }
        return .success(draft)
    }

    private func validateStateCheckedIn(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .stateCheckedIn(let p) = draft.payload else {
            return .failure(.malformedPayload("stateCheckedIn"))
        }
        for (name, value) in [("mood", p.mood), ("energy", p.energy),
                               ("focus", p.focus), ("stress", p.stress)] {
            if let v = value, v < 1 || v > 5 {
                return .failure(.fieldOutOfBounds(field: name, allowed: "1–5 or nil"))
            }
        }
        let hasAnyValue = p.mood != nil || p.energy != nil || p.focus != nil
                        || p.stress != nil || p.note != nil
        guard hasAnyValue else {
            return .failure(.missingRequiredField(
                field: "at least one of: mood, energy, focus, stress, note"
            ))
        }
        return .success(draft)
    }

    private func validateCorrectionSubmitted(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .correctionSubmitted(let p) = draft.payload else {
            return .failure(.malformedPayload("correctionSubmitted"))
        }
        guard !p.field.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.missingRequiredField(field: "field"))
        }
        guard !p.correctedValue.isEmpty else {
            return .failure(.missingRequiredField(field: "correctedValue"))
        }
        return .success(draft)
    }

    private func validateDirectionChanged(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .directionChanged(let p) = draft.payload else {
            return .failure(.malformedPayload("directionChanged"))
        }
        let trimmed = p.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.missingRequiredField(field: "title"))
        }
        if p.title.count > 500 {
            return .failure(.fieldOutOfBounds(field: "title", allowed: "<= 500 characters"))
        }
        return .success(draft)
    }

    private func validateQuestionAsked(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .questionAsked(let p) = draft.payload else {
            return .failure(.malformedPayload("questionAsked"))
        }
        let trimmed = p.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.missingRequiredField(field: "text"))
        }
        return .success(draft)
    }

    private func validatePermissionChanged(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .permissionChanged(let p) = draft.payload else {
            return .failure(.malformedPayload("permissionChanged"))
        }
        guard !p.permission.isEmpty else {
            return .failure(.missingRequiredField(field: "permission"))
        }
        return .success(draft)
    }

    private func validateCalendarEventImported(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .calendarEventImported(let p) = draft.payload else {
            return .failure(.malformedPayload("calendarEventImported"))
        }
        guard !p.externalID.isEmpty else {
            return .failure(.missingRequiredField(field: "externalID"))
        }
        guard !p.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.missingRequiredField(field: "title"))
        }
        if let end = p.endDate, end < p.startDate {
            return .failure(.fieldOutOfBounds(field: "endDate", allowed: ">= startDate"))
        }
        return .success(draft)
    }

    private func validateHealthSampleImported(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .healthSampleImported(let p) = draft.payload else {
            return .failure(.malformedPayload("healthSampleImported"))
        }
        guard !p.sampleType.isEmpty else {
            return .failure(.missingRequiredField(field: "sampleType"))
        }
        guard p.value >= 0 else {
            return .failure(.fieldOutOfBounds(field: "value", allowed: ">= 0"))
        }
        guard !p.unit.isEmpty else {
            return .failure(.missingRequiredField(field: "unit"))
        }
        guard p.endDate >= p.startDate else {
            return .failure(.fieldOutOfBounds(field: "endDate", allowed: ">= startDate"))
        }
        return .success(draft)
    }

    private func validateConsentChanged(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .consentChanged(let p) = draft.payload else {
            return .failure(.malformedPayload("consentChanged"))
        }
        guard !p.source.isEmpty else {
            return .failure(.missingRequiredField(field: "source"))
        }
        return .success(draft)
    }

    private func validateConfirmationSubmitted(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .confirmationSubmitted = draft.payload else {
            return .failure(.malformedPayload("confirmationSubmitted"))
        }
        return .success(draft)
    }

    private func validateDeletionRequested(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        guard case .deletionRequested = draft.payload else {
            return .failure(.malformedPayload("deletionRequested"))
        }
        return .success(draft)
    }
}
