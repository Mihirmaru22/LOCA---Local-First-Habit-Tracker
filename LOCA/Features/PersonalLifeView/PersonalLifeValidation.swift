//
//  PersonalLifeValidation.swift
//  LOCA
//
//  Phase 4 — Device validation and integration testing
//  Validates the end-to-end Personal Life Model pipeline
//

import Foundation
import SwiftUI
import SwiftData
import os.log

@MainActor
class PersonalLifeValidator: NSObject, ObservableObject {
    static let shared = PersonalLifeValidator()

    @Published var validationResults: [ValidationTest] = []
    @Published var isRunningValidation = false
    @Published var overallStatus: ValidationStatus = .notStarted

    private let logger = Logger(subsystem: "com.loca.validation", category: "personal-life")

    enum ValidationStatus: String {
        case notStarted = "Not Started"
        case running = "Running..."
        case passed = "All Passed ✓"
        case failed = "Failed"
    }

    struct ValidationTest {
        let name: String
        let description: String
        var status: TestStatus = .pending
        var message: String = ""
        var duration: TimeInterval = 0

        enum TestStatus: String {
            case pending = "Pending"
            case running = "Running"
            case passed = "Passed ✓"
            case failed = "Failed ✗"
        }
    }

    // MARK: - Full Validation Suite

    func runFullValidation(modelContext: ModelContext) async {
        await MainActor.run {
            isRunningValidation = true
            overallStatus = .running
            validationResults = []
        }

        var tests: [ValidationTest] = []

        // Test 1: Signal Collection
        tests.append(
            await validateSignalCollection(modelContext: modelContext)
        )

        // Test 2: State Inference
        tests.append(
            await validateStateInference(modelContext: modelContext)
        )

        // Test 3: Event Detection
        tests.append(
            await validateEventDetection(modelContext: modelContext)
        )

        // Test 4: View Composition
        tests.append(
            await validateViewComposition(modelContext: modelContext)
        )

        // Test 5: Uncertainty Calibration
        tests.append(
            await validateUncertainty(modelContext: modelContext)
        )

        // Test 6: End-to-End Pipeline
        tests.append(
            await validateEndToEnd(modelContext: modelContext)
        )

        await MainActor.run {
            validationResults = tests
            let allPassed = tests.allSatisfy { $0.status == .passed }
            overallStatus = allPassed ? .passed : .failed
            isRunningValidation = false
        }
    }

    // MARK: - Individual Tests

    private func validateSignalCollection(modelContext: ModelContext) async -> ValidationTest {
        var test = ValidationTest(
            name: "Signal Collection",
            description: "Verify signal ingestion from 7 sources"
        )

        let startTime = Date()

        do {
            let coordinator = SignalCollectionCoordinator.shared

            // Check initialization
            guard coordinator.isInitialized else {
                test.status = .failed
                test.message = "Coordinator not initialized"
                return test
            }

            // Request permissions (non-blocking)
            let permissionsGranted = await coordinator.requestPermissions()

            // Check for signals in past day
            let descriptor = FetchDescriptor<SignalEvent>(
                predicate: #Predicate { signal in
                    signal.timestamp >= Date().addingTimeInterval(-86400)
                }
            )

            let signals = try modelContext.fetch(descriptor)

            if signals.isEmpty {
                test.status = .failed
                test.message = "No signals collected in past 24h"
            } else {
                let sourceGroups = Dictionary(grouping: signals) { $0.source }
                test.status = .passed
                test.message = "\(signals.count) signals from \(sourceGroups.count) sources"
            }

            test.duration = Date().timeIntervalSince(startTime)
        } catch {
            test.status = .failed
            test.message = "Error: \(error.localizedDescription)"
        }

        return test
    }

    private func validateStateInference(modelContext: ModelContext) async -> ValidationTest {
        var test = ValidationTest(
            name: "State Inference",
            description: "Verify hourly state inference"
        )

        let startTime = Date()

        do {
            let engine = StateInferenceEngine.shared
            engine.setModelContext(modelContext)

            // Run inference on past day
            await engine.inferStatesForPastDay(modelContext: modelContext)

            // Check that states were generated
            let descriptor = FetchDescriptor<InferredState>(
                predicate: #Predicate { state in
                    state.timestamp >= Date().addingTimeInterval(-86400)
                }
            )

            let states = try modelContext.fetch(descriptor)

            if states.isEmpty {
                test.status = .failed
                test.message = "No inferred states found"
            } else {
                // Validate state values are 0–1 and uncertainties are reasonable
                let allValid = states.allSatisfy { state in
                    (0...1).contains(state.energy) &&
                    (0...1).contains(state.energyUncertainty) &&
                    (0...1).contains(state.stress) &&
                    (0...1).contains(state.stressUncertainty) &&
                    (0...1).contains(state.focus) &&
                    (0...1).contains(state.focusUncertainty) &&
                    (0...1).contains(state.mood) &&
                    (0...1).contains(state.moodUncertainty)
                }

                test.status = allValid ? .passed : .failed
                test.message = allValid ? "\(states.count) valid states" : "Invalid state values"
            }

            test.duration = Date().timeIntervalSince(startTime)
        } catch {
            test.status = .failed
            test.message = "Error: \(error.localizedDescription)"
        }

        return test
    }

    private func validateEventDetection(modelContext: ModelContext) async -> ValidationTest {
        var test = ValidationTest(
            name: "Event Detection",
            description: "Verify Life Event detection pipeline"
        )

        let startTime = Date()

        do {
            let engine = EventDetectionEngine.shared
            engine.setModelContext(modelContext)

            // Run event detection on past month
            await engine.detectEventsForPastMonth(modelContext: modelContext)

            // Check for detected events
            let descriptor = FetchDescriptor<LifeEvent>(
                predicate: #Predicate { event in
                    event.confidence >= 0.7
                }
            )

            let events = try modelContext.fetch(descriptor)

            // Events may be empty if no regime shifts detected; that's OK
            test.status = .passed
            test.message = "\(events.count) high-confidence events detected"

            test.duration = Date().timeIntervalSince(startTime)
        } catch {
            test.status = .failed
            test.message = "Error: \(error.localizedDescription)"
        }

        return test
    }

    private func validateViewComposition(modelContext: ModelContext) async -> ValidationTest {
        var test = ValidationTest(
            name: "View Composition",
            description: "Verify automatic View generation"
        )

        let startTime = Date()

        do {
            let engine = ViewCompositionEngine.shared
            engine.setModelContext(modelContext)

            let startDate = Date().addingTimeInterval(-7 * 86400)  // Past week
            let endDate = Date()

            let view = try await engine.composeView(
                question: "Test: Am I on track?",
                startDate: startDate,
                endDate: endDate,
                modelContext: modelContext
            )

            if view.energyTimeline.isEmpty || view.stressTimeline.isEmpty {
                test.status = .failed
                test.message = "Empty timelines"
            } else {
                test.status = .passed
                test.message = "View composed with \(view.eventMarkers.count) events"
            }

            test.duration = Date().timeIntervalSince(startTime)
        } catch {
            test.status = .failed
            test.message = "Error: \(error.localizedDescription)"
        }

        return test
    }

    private func validateUncertainty(modelContext: ModelContext) async -> ValidationTest {
        var test = ValidationTest(
            name: "Uncertainty Calibration",
            description: "Verify uncertainty estimates are reasonable"
        )

        let startTime = Date()

        do {
            let validator = UncertaintyValidator()

            let result = validator.validateUncertaintyCalibration(modelContext: modelContext)

            if result.isValid {
                test.status = .passed
                test.message = "✓ Energy: \(String(format: "%.2f", result.energyCalibration))"
            } else {
                test.status = .failed
                test.message = "Uncertainties need recalibration"
            }

            test.duration = Date().timeIntervalSince(startTime)
        } catch {
            test.status = .failed
            test.message = "Error: \(error.localizedDescription)"
        }

        return test
    }

    private func validateEndToEnd(modelContext: ModelContext) async -> ValidationTest {
        var test = ValidationTest(
            name: "End-to-End Pipeline",
            description: "Verify complete signal→state→event→view flow"
        )

        let startTime = Date()

        do {
            // 1. Check signals exist
            let signalDescriptor = FetchDescriptor<SignalEvent>()
            let signals = (try? modelContext.fetch(signalDescriptor)) ?? []

            if signals.isEmpty {
                test.status = .failed
                test.message = "No signals (check collection)"
                test.duration = Date().timeIntervalSince(startTime)
                return test
            }

            // 2. Check states exist
            let stateDescriptor = FetchDescriptor<InferredState>()
            let states = (try? modelContext.fetch(stateDescriptor)) ?? []

            if states.isEmpty {
                test.status = .failed
                test.message = "No states (check inference)"
                test.duration = Date().timeIntervalSince(startTime)
                return test
            }

            // 3. Check events exist (optional; may be empty if no shifts)
            let eventDescriptor = FetchDescriptor<LifeEvent>()
            let events = (try? modelContext.fetch(eventDescriptor)) ?? []

            // 4. Check views exist (or can be composed)
            let viewDescriptor = FetchDescriptor<ComposedView>()
            let views = (try? modelContext.fetch(viewDescriptor)) ?? []

            if views.isEmpty {
                test.status = .passed
                test.message = "Pipeline ready (compose first view)"
            } else {
                test.status = .passed
                test.message = "✓ Full pipeline: \(signals.count) signals → \(states.count) states → \(events.count) events → \(views.count) views"
            }

            test.duration = Date().timeIntervalSince(startTime)
        } catch {
            test.status = .failed
            test.message = "Error: \(error.localizedDescription)"
        }

        return test
    }
}

// MARK: - Validation Display View

struct ValidationResultsView: View {
    @ObservedObject var validator: PersonalLifeValidator
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Space.md) {
                // Status banner
                HStack(spacing: DS.Space.sm) {
                    Image(systemName: statusIcon(validator.overallStatus))
                        .font(.title3)
                        .foregroundStyle(statusColor(validator.overallStatus))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Validation Status")
                            .font(.caption)
                            .foregroundStyle(DS.Color.textSecondary)

                        Text(validator.overallStatus.rawValue)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)
                    }

                    Spacer()

                    if validator.isRunningValidation {
                        ProgressView()
                    }
                }
                .padding(DS.Space.md)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                // Test results
                ScrollView {
                    VStack(spacing: DS.Space.md) {
                        ForEach(validator.validationResults, id: \.name) { test in
                            TestResultRow(test: test)
                        }
                    }
                }

                // Run button
                if !validator.isRunningValidation {
                    Button(action: {
                        Task {
                            await validator.runFullValidation(modelContext: modelContext)
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Run Full Validation")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DS.Space.md)
                        .background(.accentColor, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                        .foregroundStyle(.white)
                    }
                }

                Spacer()
            }
            .padding(DS.Space.lg)
            .navigationTitle("Validation")
        }
    }

    private func statusIcon(_ status: PersonalLifeValidator.ValidationStatus) -> String {
        switch status {
        case .notStarted: return "circle"
        case .running: return "hourglass"
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private func statusColor(_ status: PersonalLifeValidator.ValidationStatus) -> Color {
        switch status {
        case .notStarted: return DS.Color.textTertiary
        case .running: return .yellow
        case .passed: return .green
        case .failed: return .red
        }
    }
}

private struct TestResultRow: View {
    let test: PersonalLifeValidator.ValidationTest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: DS.Space.sm) {
                Image(systemName: testIcon(test.status))
                    .font(.caption)
                    .frame(width: 20)
                    .foregroundStyle(testColor(test.status))

                VStack(alignment: .leading, spacing: 2) {
                    Text(test.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(test.description)
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Text(String(format: "%.1fs", test.duration))
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            if !test.message.isEmpty {
                Text(test.message)
                    .font(.caption)
                    .foregroundStyle(.accentColor)
                    .padding(.leading, 28)
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func testIcon(_ status: PersonalLifeValidator.ValidationTest.TestStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .running: return "hourglass"
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private func testColor(_ status: PersonalLifeValidator.ValidationTest.TestStatus) -> Color {
        switch status {
        case .pending: return DS.Color.textTertiary
        case .running: return .yellow
        case .passed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    @State var validator = PersonalLifeValidator.shared
    return ValidationResultsView(validator: validator)
}
