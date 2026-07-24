//
//  DirectionCaptureView.swift
//  LOCA
//
//  Phase 7, Session 7.1 — Capture the Direction.
//
//  One question, three gentle follow-ups, all skippable. The capture is a
//  gift — not interrogation. Nothing is required; the user may close at any
//  step and what they've written is kept.
//
//  The manifesto's refusals are architectural here: there is no submit button
//  that nudges, no validation that blocks, no required field. The "Skip" path
//  is always the same size as the "Continue" path.
//

import SwiftUI
import SwiftData

// MARK: - Direction Capture View

struct DirectionCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // The chapter this Direction will be linked to (typically the current chapter).
    let currentChapterId: UUID?

    // Called when the user completes or skips.
    let onComplete: (Direction?) -> Void

    @State private var step: CaptureStep = .whereAreYou
    @State private var statement = ""
    @State private var valuesText = ""        // comma-separated
    @State private var intentionsText = ""    // comma-separated
    @State private var settledness: Double = 0.5

    enum CaptureStep: CaseIterable {
        case whereAreYou  // "Where are you in your life right now?"
        case values       // "What matters to you?"
        case intentions   // "What are you moving toward?"
        case settledness  // "How settled does this feel?"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator — subtle, not a progress bar.
                stepDots
                    .padding(.top, DS.Space.md)

                Spacer(minLength: DS.Space.xl)

                // The current step's content.
                Group {
                    switch step {
                    case .whereAreYou: whereAreYouStep
                    case .values:      valuesStep
                    case .intentions:  intentionsStep
                    case .settledness: settledStep
                    }
                }
                .padding(.horizontal, DS.Space.xl)
                .animation(.easeInOut(duration: 0.25), value: step)

                Spacer()

                // Navigation: Skip (always left-weight) and Continue / Done.
                actionRow
                    .padding(.horizontal, DS.Space.xl)
                    .padding(.bottom, DS.Space.xxxl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { finish(save: !statement.isEmpty) }
                }
            }
        }
    }

    // MARK: - Step Dots

    private var stepDots: some View {
        HStack(spacing: DS.Space.xs) {
            ForEach(CaptureStep.allCases, id: \.self) { s in
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(s == step ? Color.primary : DS.Color.textTertiary)
            }
        }
    }

    // MARK: - Step Views

    private var whereAreYouStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            Text("Where are you\nin your life right now?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            Text("One phrase is enough. You can change it later.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

            TextField("e.g. finding my footing after the move", text: $statement, axis: .vertical)
                .font(DS.Text.body)
                .lineLimit(3...6)
                .padding(DS.Space.md)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
        }
    }

    private var valuesStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            Text("What matters\nto you?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            Text("A few words or phrases, separated by commas. You'll see these when looking back at this time.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

            TextField("e.g. clarity, deep work, staying present", text: $valuesText, axis: .vertical)
                .font(DS.Text.body)
                .lineLimit(2...4)
                .padding(DS.Space.md)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
        }
    }

    private var intentionsStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            Text("What are you\nmoving toward?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            Text("Not goals — intentions. Things you feel yourself reaching for, even if you're not sure how.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

            TextField("e.g. shipping something I'm proud of", text: $intentionsText, axis: .vertical)
                .font(DS.Text.body)
                .lineLimit(2...4)
                .padding(DS.Space.md)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
        }
    }

    private var settledStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            Text("How settled does\nthis feel?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)

            Text("Not a rating — just a sense. LOCA uses this to know how much to lean on your stated direction vs. what it infers.")
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)

            VStack(spacing: DS.Space.sm) {
                Slider(value: $settledness, in: 0...1)
                    .tint(settledColor)

                HStack {
                    Text("Figuring it out")
                    Spacer()
                    Text("I know where I'm going")
                }
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
            }
        }
    }

    private var settledColor: Color {
        settledness < 0.4 ? DS.Color.textTertiary : .tint
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: DS.Space.md) {
            Button("Skip") { advanceOrFinish(save: false) }
                .font(DS.Text.body)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(DS.Space.md)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))

            Button(step == .settledness ? "Done" : "Continue") {
                advanceOrFinish(save: true)
            }
            .font(DS.Text.body)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(DS.Space.md)
            .background(.tint, in: RoundedRectangle(cornerRadius: DS.Radius.control))
            .foregroundStyle(.white)
            .disabled(step == .whereAreYou && statement.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Navigation

    private func advanceOrFinish(save: Bool) {
        switch step {
        case .whereAreYou: step = .values
        case .values:      step = .intentions
        case .intentions:  step = .settledness
        case .settledness: finish(save: save || !statement.isEmpty)
        }
    }

    private func finish(save: Bool) {
        guard save, !statement.trimmingCharacters(in: .whitespaces).isEmpty else {
            onComplete(nil)
            dismiss()
            return
        }

        // Deactivate any existing active Direction before inserting the new one.
        let descriptor = FetchDescriptor<Direction>(
            predicate: #Predicate { $0.isActive }
        )
        if let existing = try? modelContext.fetch(descriptor) {
            for d in existing { d.isActive = false }
        }

        let parsed = parseTokens
        let dir = Direction(
            statement: statement.trimmingCharacters(in: .whitespaces),
            values: parsed.values,
            intentions: parsed.intentions,
            settledness: settledness,
            chapterId: currentChapterId
        )
        modelContext.insert(dir)
        try? modelContext.save()

        onComplete(dir)
        dismiss()
    }

    private var parseTokens: (values: [String], intentions: [String]) {
        func split(_ text: String) -> [String] {
            text.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return (split(valuesText), split(intentionsText))
    }
}

// MARK: - Preview

#Preview {
    DirectionCaptureView(currentChapterId: nil) { _ in }
}
