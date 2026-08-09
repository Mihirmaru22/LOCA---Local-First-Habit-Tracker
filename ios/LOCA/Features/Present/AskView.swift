//
//  AskView.swift
//  LOCA
//
//  Phase 8, Session 8.3 — Ask → View.
//
//  The ask affordance: a single open text line. No form, no date picker,
//  no submit-and-wait spinner. The user aims a question at their life and
//  a View composes — a scene they read and conclude from, not a verdict.
//
//  Uncertain parts render soft (blurred/muted). No sentence ever ends with
//  a recommendation. The "no preacher" refusal is architectural: there is
//  no code path that produces prescriptive output.
//

import SwiftUI
import SwiftData

// MARK: - Ask View

struct AskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let prefill: String
    let onComposed: (ComposedView?) -> Void

    @State private var question: String = ""
    @State private var composedView: ComposedView?
    @State private var isComposing = false
    @State private var composeFailed = false
    @FocusState private var fieldFocused: Bool

    @State private var showCalibrationSheet = false
    @State private var selectedAnnotation: AnnotationPoint?
    @State private var calibrationLabel: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let view = composedView {
                    // The composed View.
                    composedScene(view)
                } else {
                    askInput
                }
            }
            .inlineNavigationTitleDisplay()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onComposed(composedView)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            question = prefill
            if prefill.isEmpty { fieldFocused = true }
        }
        .sheet(isPresented: $showCalibrationSheet) {
            if let annotation = selectedAnnotation {
                CalibrationSheet(
                    annotation: annotation,
                    label: $calibrationLabel,
                    isPresented: $showCalibrationSheet,
                    onSave: { saveCalibration(annotation, label: $0) }
                )
            }
        }
    }

    // MARK: - Ask Input

    private var askInput: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            Spacer()

            VStack(alignment: .leading, spacing: DS.Space.lg) {
                Text("What would you like to look at?")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(DS.Color.textPrimary)

                TextField("e.g. Am I happier since starting my internship?", text: $question, axis: .vertical)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(2...5)
                    .focused($fieldFocused)
                    .submitLabel(.done)
                    .onSubmit { if !question.isEmpty { Task { await compose() } } }

                Divider()
                    .foregroundStyle(DS.Color.border)

                Text("LOCA will compose a scene you look at and conclude from yourself. Not a verdict — a view.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    Task { await compose() }
                } label: {
                    Group {
                        if isComposing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Compose")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(width: 120)
                    .padding(.vertical, DS.Space.md)
                    .background(.tint, in: Capsule())
                    .foregroundStyle(.white)
                }
                .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || isComposing)
            }

            if composeFailed {
                Text("Couldn't compose a view right now — not enough data to answer this yet.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Spacer(minLength: DS.Space.xxxl)
        }
        .padding(.horizontal, DS.Space.xl)
    }

    // MARK: - Composed Scene

    private func composedScene(_ view: ComposedView) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {
                // The question — anchors the scene.
                Text(view.question)
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundStyle(DS.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, DS.Space.lg)

                Divider()

                // Notable patterns (annotations) — soft elements to pull.
                if !view.annotations.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Space.lg) {
                        ForEach(view.annotations, id: \.timestamp) { annotation in
                            SoftAnnotationRow(
                                annotation: annotation,
                                onPullThread: { pullAnnotationThread(annotation) },
                                onCalibrate: { openCalibration(for: annotation) }
                            )
                        }
                    }
                } else if !view.eventMarkers.isEmpty {
                    // Fall back to event markers if no annotations.
                    VStack(alignment: .leading, spacing: DS.Space.md) {
                        ForEach(view.eventMarkers, id: \.timestamp) { marker in
                            Text(marker.label)
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary.opacity(0.75))
                        }
                    }
                } else {
                    Text("The model doesn't have enough to compose a clear view on this yet.")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // Honesty footer when data is thin.
                if meanConfidence(view) < 0.55 {
                    Text("Parts of this view are soft — based on limited data. They'll sharpen with time.")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                        .italic()
                }

                // Pull a different thread.
                Button("Ask something else") {
                    composedView = nil
                    question = ""
                    fieldFocused = true
                }
                .font(.caption)
                .foregroundStyle(.tint)
                .padding(.top, DS.Space.sm)

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(.horizontal, DS.Space.xl)
        }
    }

    // MARK: - Thread Pulling

    private func pullAnnotationThread(_ annotation: AnnotationPoint) {
        let nextQuestion = "Tell me more about: \(annotation.text)"
        composedView = nil
        question = nextQuestion
        Task { await compose() }
    }

    private func openCalibration(for annotation: AnnotationPoint) {
        selectedAnnotation = annotation
        calibrationLabel = ""
        showCalibrationSheet = true
    }

    private func saveCalibration(_ annotation: AnnotationPoint, label: String) {
        guard !label.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let calibration = Calibration(
                elementType: "annotation",
                elementText: annotation.text,
                label: label,
                dimension: annotation.targetState
            )
            modelContext.insert(calibration)
            try modelContext.save()
            showCalibrationSheet = false
        } catch {
            // Silently fail for now
        }
    }

    private func meanConfidence(_ view: ComposedView) -> Double {
        let all = view.moodTimeline.map { 1.0 - $0.uncertainty }
        guard !all.isEmpty else { return 0.5 }
        return all.reduce(0, +) / Double(all.count)
    }

    // MARK: - Composition

    private func compose() async {
        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isComposing = true
        composeFailed = false
        fieldFocused = false

        do {
            let engine = ViewCompositionEngine.shared
            engine.setModelContext(modelContext)

            let sixMonthsAgo = Date().addingTimeInterval(-183 * 86400)
            let view = try await engine.composeView(
                question: question,
                startDate: sixMonthsAgo,
                endDate: Date(),
                modelContext: modelContext
            )
            modelContext.insert(view)
            try modelContext.save()

            await MainActor.run {
                composedView = view
                isComposing = false
            }
        } catch {
            await MainActor.run {
                isComposing = false
                composeFailed = true
            }
        }
    }
}

// MARK: - Soft Annotation Row

/// One annotation (pattern) in the composed View — soft where uncertain,
/// pull-able as a thread into the next question.
private struct SoftAnnotationRow: View {
    let annotation: AnnotationPoint
    let onPullThread: () -> Void
    let onCalibrate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(alignment: .top, spacing: DS.Space.md) {
                Button(action: onPullThread) {
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text(annotation.text)
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textPrimary.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("pull to explore →")
                            .font(.caption2)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onCalibrate) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                        .padding(DS.Space.xs)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Calibration Sheet

private struct CalibrationSheet: View {
    let annotation: AnnotationPoint
    @Binding var label: String
    @Binding var isPresented: Bool
    let onSave: (String) -> Void

    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                Text("Sharpen this observation")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text(annotation.text)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(DS.Space.md)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("Your context")
                        .font(.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                        .textCase(.uppercase)

                    TextField("e.g., This was during the stressful project...", text: $label, axis: .vertical)
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(2...6)
                        .focused($fieldFocused)
                        .padding(DS.Space.md)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                }

                Spacer()

                HStack(spacing: DS.Space.md) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DS.Space.md)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    .foregroundStyle(DS.Color.textPrimary)

                    Button("Save") {
                        onSave(label)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DS.Space.md)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    .foregroundStyle(.white)
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(DS.Space.xl)
            .inlineNavigationTitleDisplay()
        }
        .onAppear { fieldFocused = true }
    }
}

// MARK: - Preview

#Preview {
    AskView(prefill: "") { _ in }
}
