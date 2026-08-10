//
//  EventsView.swift
//  LOCA
//
//  Phase F3 — Events surface.
//
//  Detected life events (regime shifts) were previously visible only as bare
//  landmarks on the answer timeline. This surface shows each event with its honest
//  C6B confidence AND the three evidence legs behind it — anomaly strength,
//  persistence, and classification margin — so the confidence is explainable, not
//  asserted. Every value here is a real LifeEvent field; nothing is decorative.
//

import SwiftUI
import SwiftData

struct EventsView: View {
    @Query(sort: \LifeEvent.timestamp, order: .reverse) private var events: [LifeEvent]

    var body: some View {
        Group {
            if events.isEmpty {
                emptyState
            } else {
                eventList
            }
        }
        .navigationTitle("Events")
        .inlineNavigationTitleDisplay()
    }

    private var eventList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                Text("Shifts LOCA detected in your life's rhythm")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                ForEach(events) { event in
                    EventCard(event: event)
                        .padding(.horizontal, DS.Space.lg)
                }

                Spacer(minLength: DS.Space.xxxl)
            }
        }
    }

    private var emptyState: some View {
        LifeEmptyState(
            icon: "flag.slash",
            headline: "No significant shifts detected yet",
            message: "Events appear when LOCA notices a real change in your patterns — like a new chapter starting or a sustained shift in energy. They take a few weeks of check-ins to appear."
        )
    }
}

// MARK: - Event Card

private struct EventCard: View {
    let event: LifeEvent

    private var confidenceLevel: ConfidenceLevel {
        ConfidenceLevel(uncertainty: 1.0 - event.confidence)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack(alignment: .top) {
                Image(systemName: event.eventType.iconName)
                    .font(.body)
                    .foregroundStyle(.tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.eventType.displayName)
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(event.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Spacer()

                ConfidenceChip(level: confidenceLevel)
            }

            // The three C6B evidence legs — the event's confidence is the weakest of
            // these (Rule D), so showing them explains the chip above.
            VStack(spacing: 6) {
                EvidenceLeg(label: "Anomaly",     value: anomalyConfidence(anomalyScore: event.anomalyScore))
                EvidenceLeg(label: "Persistence", value: persistenceConfidence(distance: event.persistenceScore))
                EvidenceLeg(label: "Type match",  value: event.classificationScore)
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Evidence Leg

/// One leg of an event's confidence, as a small labeled bar. Reflects a C6B
/// calibrated signal (0–1); not a decorative gauge.
private struct EvidenceLeg: View {
    let label: String
    let value: Double

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 84, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundStyle(DS.Color.surfaceRecessed)

                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: geo.size.width * max(0, min(1, value)), height: 4)
                        .foregroundStyle(.tint)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventsView()
    }
}
