//
//  ChapterListView.swift
//  LOCA
//
//  Phase 5 — Browse life chapters
//  Shows the user's life segmented into named intervals
//

import SwiftUI
import SwiftData

struct ChapterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chapter.startDate, order: .reverse) private var chapters: [Chapter]

    @State private var selectedChapter: Chapter?
    @State private var showRenameSheet = false

    var body: some View {
        Group {
            if chapters.isEmpty {
                emptyState
            } else {
                chapterList
            }
        }
        .navigationTitle("Chapters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: rebuildChapters) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
        }
        .sheet(item: $selectedChapter) { chapter in
            ChapterDetailView(chapter: chapter)
        }
    }

    // MARK: - Chapter List

    private var chapterList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                Text("Your life in chapters")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                ForEach(chapters) { chapter in
                    ChapterCard(chapter: chapter)
                        .padding(.horizontal, DS.Space.lg)
                        .onTapGesture {
                            selectedChapter = chapter
                        }
                }

                Spacer(minLength: DS.Space.xxxl)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(DS.Color.textTertiary)

            VStack(spacing: DS.Space.sm) {
                Text("No Chapters Yet")
                    .font(.headline)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Chapters appear automatically when LOCA detects a significant shift in your life pattern.")
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DS.Space.xl)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Rebuild

    private func rebuildChapters() {
        try? ChapterBuilder.shared.buildChapters(modelContext: modelContext)
    }
}

// MARK: - Chapter Card

struct ChapterCard: View {
    let chapter: Chapter

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if chapter.isCurrentChapter {
                        Text("CURRENT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.tint)
                    }

                    if let name = chapter.name {
                        Text(name)
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)
                    } else {
                        Text("Name this chapter →")
                            .font(DS.Text.body)
                            .fontWeight(.regular)
                            .italic()
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    Text(dateRangeLabel(chapter))
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Text("\(chapter.durationInDays)d")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            // Baseline state bars
            VStack(spacing: 6) {
                StateBar(label: "Energy", value: chapter.baselineEnergy, color: Color(hex: "#10B981"))
                StateBar(label: "Stress", value: chapter.baselineStress, color: Color(hex: "#EF4444"))
                StateBar(label: "Mood",   value: chapter.baselineMood,   color: Color(hex: "#F59E0B"))
            }

            // Volatility hint
            if chapter.volatility > 0.25 {
                HStack(spacing: 4) {
                    Image(systemName: "waveform.path")
                        .font(.caption2)
                    Text("Turbulent period")
                        .font(.caption2)
                }
                .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(
                    chapter.isCurrentChapter ? Color.accentColor.opacity(0.4) : DS.Color.border,
                    lineWidth: chapter.isCurrentChapter ? 1.5 : 1
                )
        )
    }

    private func dateRangeLabel(_ chapter: Chapter) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        let start = formatter.string(from: chapter.startDate)

        if let end = chapter.endDate {
            return "\(start) – \(formatter.string(from: end))"
        } else {
            return "\(start) – Now"
        }
    }
}

// MARK: - State Bar

private struct StateBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 44, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundStyle(DS.Color.surfaceRecessed)

                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: geo.size.width * value, height: 4)
                        .foregroundStyle(color)
                }
            }
            .frame(height: 4)

            Text(String(format: "%.0f%%", value * 100))
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - Chapter Detail

struct ChapterDetailView: View {
    @Bindable var chapter: Chapter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var editingName = false
    @State private var draftName = ""
    @State private var openingEvent: LifeEvent?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    // Duration
                    HStack {
                        Label("\(chapter.durationInDays) days", systemImage: "calendar")
                        Spacer()
                        if chapter.isCurrentChapter {
                            Text("Ongoing")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                    // F3: the detected event that opened this chapter, with its honest
                    // C6B confidence. A chapter is the room; the event is the door.
                    if let event = openingEvent {
                        HStack(spacing: DS.Space.sm) {
                            Image(systemName: event.eventType.iconName)
                                .font(.caption)
                                .foregroundStyle(.tint)
                            Text("Opened by a \(event.eventType.displayName.lowercased())")
                                .font(.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                            Spacer()
                            ConfidenceChip(level: ConfidenceLevel(uncertainty: 1.0 - event.confidence))
                        }
                        .padding(DS.Space.sm)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }

                    Divider()

                    // Baseline states
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Your Baseline This Chapter")
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)

                        StateBar(label: "Energy", value: chapter.baselineEnergy, color: Color(hex: "#10B981"))
                        StateBar(label: "Stress", value: chapter.baselineStress, color: Color(hex: "#EF4444"))
                        StateBar(label: "Focus",  value: chapter.baselineFocus,  color: Color(hex: "#3B82F6"))
                        StateBar(label: "Mood",   value: chapter.baselineMood,   color: Color(hex: "#F59E0B"))
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // Characterization
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Character")
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)

                        CharacterRow(label: "Activity",   value: chapter.activityLevel)
                        CharacterRow(label: "Social",     value: chapter.socialEngagement)
                        CharacterRow(label: "Regularity", value: chapter.scheduleRegularity)
                        CharacterRow(label: "Volatility", value: chapter.volatility, inverted: true)
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // Notes
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        Text("Your Notes")
                            .font(DS.Text.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.textPrimary)

                        TextEditor(text: Binding(
                            get: { chapter.userDescription ?? "" },
                            set: { chapter.userDescription = $0.isEmpty ? nil : $0 }
                        ))
                        .font(DS.Text.body)
                        .frame(minHeight: 80)
                        .padding(DS.Space.sm)
                        .background(
                            DS.Color.surfaceRecessed,
                            in: RoundedRectangle(cornerRadius: DS.Radius.control)
                        )
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle(chapter.name ?? "Unnamed Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(chapter.name == nil ? "Name" : "Rename") {
                        draftName = chapter.name ?? ""
                        editingName = true
                    }
                }
            }
            .alert(chapter.name == nil ? "Name This Chapter" : "Rename Chapter", isPresented: $editingName) {
                TextField("e.g. The Internship", text: $draftName)
                Button("Save") {
                    let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                    chapter.name = trimmed.isEmpty ? nil : trimmed
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            }
            .task { await loadOpeningEvent() }
        }
    }

    /// Resolve the LifeEvent that opened this chapter (if any) so its detected type
    /// and honest C6B confidence can be shown. One id lookup — no engine call.
    private func loadOpeningEvent() async {
        guard let id = chapter.openingEventId else { return }
        let descriptor = FetchDescriptor<LifeEvent>(predicate: #Predicate { $0.id == id })
        openingEvent = (try? modelContext.fetch(descriptor))?.first
    }
}

private struct CharacterRow: View {
    let label: String
    let value: Double
    var inverted: Bool = false

    private var displayValue: Double { inverted ? 1.0 - value : value }

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Text(label)
                .font(.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundStyle(DS.Color.surfaceRecessed)

                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: geo.size.width * displayValue, height: 4)
                        .foregroundStyle(.tint)
                }
            }
            .frame(height: 4)

            Text(String(format: "%.0f%%", displayValue * 100))
                .font(.caption2)
                .foregroundStyle(DS.Color.textTertiary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChapterListView()
    }
}
