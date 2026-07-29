//
//  MultiEntityComposer.swift
//  LOCA
//
//  Phase 5 — Cross-entity composition for the Personal Life view
//  Answers questions that span Chapters, Traits, People, and States together
//

import Foundation
import SwiftData
import os.log

// MARK: - Composed Scene

struct ComposedScene {
    let question: String
    let generatedAt: Date

    // Entity snapshots included in this scene
    let chapters: [ChapterSnapshot]
    let traits: [TraitSnapshot]
    let people: [PersonSnapshot]

    // Cross-entity insights
    let insights: [SceneInsight]
    let overallUncertainty: Double
    // C1.4: True when the scene has no real evidence — structurally distinct from
    // "high uncertainty measured scene." A scene can only be labeled absent here;
    // no composition path may substitute a default value on its behalf.
    let isDataAbsent: Bool
}

struct ChapterSnapshot {
    let chapter: Chapter
    let traitsForChapter: [TraitSnapshot]
    let peopleForChapter: [PersonSnapshot]
}

struct TraitSnapshot {
    let traitType: TraitType
    let value: Double
    let uncertainty: Double
    let chapterId: UUID?            // nil = global estimate
    let label: String               // Human-readable description of this value
}

struct PersonSnapshot {
    let person: Person
    let salienceInChapter: Double?  // Salience within a specific chapter context
    let moodCorrelation: Double?
}

struct SceneInsight {
    enum InsightType: String {
        case traitShift          // A trait changed significantly across chapters
        case personPresence      // A person was notably present/absent in a chapter
        case stateCorrelation    // A person correlates with state patterns
        case chapterContrast     // Two chapters differ markedly
    }

    let type: InsightType
    let text: String             // One-sentence human-readable observation
    let confidence: Double
    let entities: [String]       // Names of entities involved (chapter names, trait names, etc.)
}

// MARK: - Multi-Entity Composer

@MainActor
class MultiEntityComposer {
    static let shared = MultiEntityComposer()

    private let logger = Logger(subsystem: "com.loca.entities", category: "composer")
    private let traitShiftThreshold = 0.20  // Trait must shift by ≥20% to be noteworthy

    // MARK: - Compose Full Life Scene

    func composeLifeScene(modelContext: ModelContext) throws -> ComposedScene {
        let chapters = try fetchChapters(modelContext: modelContext)
        let globalTraits = try fetchGlobalTraits(modelContext: modelContext)
        let people = try fetchPeople(modelContext: modelContext)

        var chapterSnapshots: [ChapterSnapshot] = []

        for chapter in chapters {
            let traitsForChapter = try fetchTraits(for: chapter, modelContext: modelContext)
            let peopleForChapter = try peoplePresent(in: chapter, people: people, modelContext: modelContext)

            chapterSnapshots.append(ChapterSnapshot(
                chapter: chapter,
                traitsForChapter: traitsForChapter.isEmpty ? globalTraits : traitsForChapter,
                peopleForChapter: peopleForChapter
            ))
        }

        let insights = generateInsights(
            chapters: chapterSnapshots,
            globalTraits: globalTraits,
            allPeople: people
        )

        let uncertainty = computeSceneUncertainty(traits: globalTraits, people: people)
        // C1.4: The scene is "absent" when no chapters and no global traits exist.
        // This is structurally distinct from a scene with high uncertainty on real data.
        let isDataAbsent = chapters.isEmpty && globalTraits.isEmpty

        logger.info("Composed life scene: \(chapters.count) chapters, \(globalTraits.count) traits, \(people.count) people, \(insights.count) insights, absent=\(isDataAbsent)")

        return ComposedScene(
            question: "How has your life evolved across chapters?",
            generatedAt: Date(),
            chapters: chapterSnapshots,
            traits: globalTraits,
            people: people.map { PersonSnapshot(person: $0, salienceInChapter: nil, moodCorrelation: $0.moodCorrelation) },
            insights: insights,
            overallUncertainty: isDataAbsent ? 1.0 : uncertainty,
            isDataAbsent: isDataAbsent
        )
    }

    // MARK: - Fetch Helpers

    private func fetchChapters(modelContext: ModelContext) throws -> [Chapter] {
        let descriptor = FetchDescriptor<Chapter>(sortBy: [SortDescriptor(\.startDate)])
        return try modelContext.fetch(descriptor)
    }

    private func fetchGlobalTraits(modelContext: ModelContext) throws -> [TraitSnapshot] {
        let descriptor = FetchDescriptor<Trait>(
            predicate: #Predicate { trait in trait.chapterId == nil }
        )
        return try modelContext.fetch(descriptor).map { trait in
            TraitSnapshot(
                traitType: trait.traitType,
                value: trait.value,
                uncertainty: trait.uncertainty,
                chapterId: nil,
                label: traitLabel(value: trait.value, type: trait.traitType)
            )
        }
    }

    private func fetchTraits(for chapter: Chapter, modelContext: ModelContext) throws -> [TraitSnapshot] {
        let chapterId = chapter.id
        let descriptor = FetchDescriptor<Trait>(
            predicate: #Predicate { trait in trait.chapterId == chapterId }
        )
        return try modelContext.fetch(descriptor).map { trait in
            TraitSnapshot(
                traitType: trait.traitType,
                value: trait.value,
                uncertainty: trait.uncertainty,
                chapterId: chapterId,
                label: traitLabel(value: trait.value, type: trait.traitType)
            )
        }
    }

    private func fetchPeople(modelContext: ModelContext) throws -> [Person] {
        let descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\.salience, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    // MARK: - People in Chapter

    private func peoplePresent(
        in chapter: Chapter,
        people: [Person],
        modelContext: ModelContext
    ) throws -> [PersonSnapshot] {
        let start = chapter.startDate
        let end = chapter.endDate ?? Date()

        let descriptor = FetchDescriptor<PersonAppearance>(
            predicate: #Predicate { appearance in
                appearance.timestamp >= start && appearance.timestamp <= end
            }
        )

        let appearances = try modelContext.fetch(descriptor)
        var personAppearanceCounts: [UUID: Int] = [:]
        for a in appearances {
            personAppearanceCounts[a.personId, default: 0] += 1
        }

        let totalDays = max(1, chapter.durationInDays)

        return personAppearanceCounts.compactMap { (personId, count) -> PersonSnapshot? in
            guard let person = people.first(where: { $0.id == personId }) else { return nil }
            let salience = min(1.0, Double(count) / (Double(totalDays) * 0.5))
            return PersonSnapshot(
                person: person,
                salienceInChapter: salience,
                moodCorrelation: person.moodCorrelation
            )
        }.sorted { ($0.salienceInChapter ?? 0) > ($1.salienceInChapter ?? 0) }
    }

    // MARK: - Insight Generation

    private func generateInsights(
        chapters: [ChapterSnapshot],
        globalTraits: [TraitSnapshot],
        allPeople: [Person]
    ) -> [SceneInsight] {
        var insights: [SceneInsight] = []

        // Trait shift insights across consecutive chapters
        for i in 1..<chapters.count {
            let prev = chapters[i - 1]
            let curr = chapters[i]
            insights.append(contentsOf: traitShiftInsights(from: prev, to: curr))
        }

        // Person presence insights: who was most prominent in each chapter
        for snapshot in chapters {
            guard let chapterName = snapshot.chapter.name else { continue }
            if let topPerson = snapshot.peopleForChapter.first,
               let salience = topPerson.salienceInChapter, salience > 0.3 {
                insights.append(SceneInsight(
                    type: .personPresence,
                    text: "\(topPerson.person.name) was notably present during \(chapterName)",
                    confidence: min(0.9, salience),
                    entities: [topPerson.person.name, chapterName]
                ))
            }
        }

        // Mood correlation insight for high-salience people
        for person in allPeople.prefix(5) {
            if let corr = person.moodCorrelation, abs(corr) > 0.25,
               person.moodCorrelationSampleCount >= 5 {
                let direction = corr > 0 ? "associated with higher mood" : "associated with lower mood"
                insights.append(SceneInsight(
                    type: .stateCorrelation,
                    text: "\(person.name) is \(direction) when they appear in your life",
                    confidence: min(0.8, abs(corr) * 2),
                    entities: [person.name]
                ))
            }
        }

        return insights.sorted { $0.confidence > $1.confidence }
    }

    private func traitShiftInsights(from prev: ChapterSnapshot, to curr: ChapterSnapshot) -> [SceneInsight] {
        var insights: [SceneInsight] = []
        guard let prevName = prev.chapter.name, let currName = curr.chapter.name else {
            return insights
        }

        for currTrait in curr.traitsForChapter {
            guard let prevTrait = prev.traitsForChapter.first(where: { $0.traitType == currTrait.traitType }) else { continue }

            let delta = currTrait.value - prevTrait.value
            guard abs(delta) >= traitShiftThreshold else { continue }

            let direction = delta > 0 ? "increased" : "decreased"
            let confidence = min(0.85, (1.0 - currTrait.uncertainty) * (1.0 - prevTrait.uncertainty))

            insights.append(SceneInsight(
                type: .traitShift,
                text: "\(currTrait.traitType.displayName) \(direction) between \(prevName) and \(currName)",
                confidence: confidence,
                entities: [currTrait.traitType.rawValue, prevName, currName]
            ))
        }

        return insights
    }

    // MARK: - Uncertainty

    private func computeSceneUncertainty(traits: [TraitSnapshot], people: [Person]) -> Double {
        let traitUncertainty = traits.isEmpty ? 0.8 : traits.map { $0.uncertainty }.reduce(0, +) / Double(traits.count)
        let peopleConfidence = people.isEmpty ? 0.5 : min(1.0, Double(people.count) / 10.0)
        return traitUncertainty * 0.6 + (1 - peopleConfidence) * 0.4
    }

    // MARK: - Trait Label

    private func traitLabel(value: Double, type: TraitType) -> String {
        switch (type, value) {
        case (.resilience, 0.7...):    return "Bounces back quickly"
        case (.resilience, 0.4..<0.7): return "Moderate recovery"
        case (.resilience, _):         return "Slow to recover"

        case (.consistency, 0.7...):    return "Highly regular"
        case (.consistency, 0.4..<0.7): return "Somewhat variable"
        case (.consistency, _):         return "Irregular patterns"

        case (.socialDrive, 0.7...):    return "Strongly social"
        case (.socialDrive, 0.4..<0.7): return "Moderately social"
        case (.socialDrive, _):         return "Prefers solitude"

        case (.activityDrive, 0.7...):    return "Very active"
        case (.activityDrive, 0.4..<0.7): return "Moderately active"
        case (.activityDrive, _):         return "Mostly sedentary"

        case (.focusDepth, 0.7...):    return "Deep focus sessions"
        case (.focusDepth, 0.4..<0.7): return "Moderate concentration"
        case (.focusDepth, _):         return "Short attention spans"

        case (.moodStability, 0.7...):    return "Emotionally steady"
        case (.moodStability, 0.4..<0.7): return "Moderate fluctuation"
        case (.moodStability, _):         return "High mood volatility"

        default: return ""
        }
    }
}
