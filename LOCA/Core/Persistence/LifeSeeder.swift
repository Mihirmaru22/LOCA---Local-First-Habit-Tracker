#if DEBUG
import SwiftData
import Foundation

// MARK: - LifeSeeder

/// Populates the Personal Life Model with a deterministic ~180-day life on Debug
/// builds, so the whole vertical — States, the Life Event, Chapters, People,
/// Traits, and the Phase 6.4 relationship graph — is visible and testable
/// without waiting weeks for real sensor data to accrue.
///
/// This is the production analog of the plan's Phase 1 fixture (LOCA-Life
/// Implementation Plan §2.4 "the seeded life store"): a fixed, reviewable life
/// rather than random noise. It is entirely excluded from Release via the
/// `#if DEBUG` around the whole file, and no-ops if any inferred state already
/// exists, so it seeds exactly once per fresh store and never touches real data.
///
/// ## The shape of the seeded life
/// A single clear Life Event — "Started internship" at day 90 — splits the
/// history into two chapters. Energy, stress, focus, and mood all step up after
/// the event. Two relationships are built in deliberately:
///
/// - **Real, within-regime:** stress ↔ mood move oppositely *inside each
///   chapter*, and energy ↔ focus move together inside each chapter. The graph
///   should assert these.
/// - **Confounded:** energy and stress both jump at the event but are otherwise
///   independent within each chapter, so their pooled correlation is strong while
///   their within-chapter correlation is ~0. The graph should refuse to assert
///   this and label it "explained by a life change." Likewise, "Sarah" appears
///   only in the internship chapter, so her apparent mood lift is really the
///   chapter, not her.
enum LifeSeeder {

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        // No-op if the life model already has data — never overwrite real history.
        var probe = FetchDescriptor<InferredState>()
        probe.fetchLimit = 1
        guard let existing = try? context.fetch(probe), existing.isEmpty else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = 180
        let eventDay = 90
        let hoursOfDay = [8, 12, 18, 22]

        func date(forDay day: Int, hour: Int = 0) -> Date {
            // day 0 → 180 days ago; day 179 → yesterday. Keeps the most recent
            // seeded state ~1 day old so the past-day inference pass doesn't clear it.
            let base = calendar.date(byAdding: .day, value: -(totalDays - day), to: today) ?? today
            return calendar.date(byAdding: .hour, value: hour, to: base) ?? base
        }

        // MARK: States

        for day in 0..<totalDays {
            let after = day >= eventDay
            let eNoise = noise(day, 1) * 0.12
            let sNoise = noise(day, 2) * 0.12
            let fNoise = noise(day, 3) * 0.10
            let mNoise = noise(day, 4) * 0.10

            let baseEnergy = after ? 0.66 : 0.46
            let baseStress = after ? 0.60 : 0.40
            let baseFocus  = after ? 0.64 : 0.50
            let baseMood   = after ? 0.62 : 0.54

            for hour in hoursOfDay {
                let jitter = noise(day * 4 + hour, 5) * 0.03
                let energy = baseEnergy + eNoise + jitter
                let stress = baseStress + sNoise + jitter
                // focus tracks energy within a chapter; mood moves opposite to stress.
                let focus = baseFocus + 0.5 * eNoise + fNoise + jitter
                let mood = baseMood - 0.5 * sNoise + mNoise + jitter

                context.insert(
                    InferredState(
                        timestamp: date(forDay: day, hour: hour),
                        energy: energy, energyUncertainty: 0.16,
                        stress: stress, stressUncertainty: 0.18,
                        focus: focus, focusUncertainty: 0.20,
                        mood: mood, moodUncertainty: 0.17
                    )
                )
            }
        }

        // MARK: Life Event

        let event = LifeEvent(
            timestamp: date(forDay: eventDay, hour: 9),
            eventType: .workChange,
            confidence: 0.85,
            anomalyScore: 2.4,
            persistenceScore: 0.82,
            classificationScore: 0.85,
            metadata: ["summary": "Started internship"]
        )
        context.insert(event)

        // MARK: Chapters

        let before = Chapter(startDate: date(forDay: 0), name: "Before the Internship")
        before.endDate = date(forDay: eventDay)
        before.closingEventId = event.id
        before.isCurrentChapter = false
        before.baselineEnergy = 0.46
        before.baselineStress = 0.40
        before.baselineFocus = 0.50
        before.baselineMood = 0.54
        before.volatility = 0.12
        before.activityLevel = 0.45
        before.socialEngagement = 0.40
        before.scheduleRegularity = 0.50
        context.insert(before)

        let internship = Chapter(
            startDate: date(forDay: eventDay),
            name: "The Internship",
            openingEventId: event.id
        )
        internship.isCurrentChapter = true
        internship.baselineEnergy = 0.66
        internship.baselineStress = 0.60
        internship.baselineFocus = 0.64
        internship.baselineMood = 0.62
        internship.volatility = 0.14
        internship.activityLevel = 0.60
        internship.socialEngagement = 0.62
        internship.scheduleRegularity = 0.72
        context.insert(internship)

        // MARK: People + Appearances

        // Mom: across both chapters; genuinely lifts mood within each chapter.
        seedPerson(
            context: context,
            name: "Mom",
            primaryContext: .family,
            salience: 0.6,
            chapterId: nil,
            appearanceDays: stride(from: 3, to: totalDays, by: 7).map { $0 },
            moodDelta: 0.10,
            dateForDay: { date(forDay: $0, hour: 18) },
            dayMood: { dayMood($0) }
        )

        // Sarah: only in the internship chapter. Her apparent mood lift is really
        // the chapter — a confounded person→mood edge the graph should reject.
        seedPerson(
            context: context,
            name: "Sarah",
            primaryContext: .work,
            salience: 0.7,
            chapterId: internship.id,
            appearanceDays: stride(from: 92, to: totalDays, by: 3).map { $0 },
            moodDelta: 0.0,
            dateForDay: { date(forDay: $0, hour: 12) },
            dayMood: { dayMood($0) }
        )

        // Alex: across both chapters, neutral.
        seedPerson(
            context: context,
            name: "Alex",
            primaryContext: .social,
            salience: 0.4,
            chapterId: nil,
            appearanceDays: stride(from: 6, to: totalDays, by: 11).map { $0 },
            moodDelta: 0.0,
            dateForDay: { date(forDay: $0, hour: 20) },
            dayMood: { dayMood($0) }
        )

        // MARK: Traits (global estimates)

        let traits: [(TraitType, Double, Double)] = [
            (.resilience, 0.60, 0.20),
            (.consistency, 0.70, 0.18),
            (.socialDrive, 0.55, 0.24),
            (.activityDrive, 0.50, 0.25),
            (.focusDepth, 0.62, 0.20),
            (.moodStability, 0.66, 0.19),
        ]
        for (type, value, uncertainty) in traits {
            context.insert(
                Trait(traitType: type, value: value, uncertainty: uncertainty, windowDays: 180, sampleCount: totalDays * 4)
            )
        }

        // MARK: Signals (recent, for realism + validation surfaces)

        for day in (totalDays - 14)..<totalDays {
            context.insert(
                SignalEvent(
                    timestamp: date(forDay: day, hour: 7),
                    source: .sleep,
                    value: 0.5 + noise(day, 6) * 0.2,
                    uncertainty: 0.1,
                    metadata: ["duration": "7h"]
                )
            )
            context.insert(
                SignalEvent(
                    timestamp: date(forDay: day, hour: 17),
                    source: .motionActivity,
                    value: 0.5 + noise(day, 7) * 0.2,
                    uncertainty: 0.12,
                    metadata: ["steps": "\(6000 + Int(noise(day, 8) * 2000))"]
                )
            )
        }

        do {
            try context.save()
        } catch {
            // Debug-only convenience seeding — a failure here just means the app
            // launches with an empty life model, same as if seeding never ran.
        }
    }

    // MARK: - Person Seeding Helper

    @MainActor
    private static func seedPerson(
        context: ModelContext,
        name: String,
        primaryContext: RelationshipContext,
        salience: Double,
        chapterId: UUID?,
        appearanceDays: [Int],
        moodDelta: Double,
        dateForDay: (Int) -> Date,
        dayMood: (Int) -> Double
    ) {
        guard let firstDay = appearanceDays.first, let lastDay = appearanceDays.last else { return }

        let person = Person(name: name, primaryContext: primaryContext)
        person.salience = salience
        person.salienceUncertainty = 0.2
        person.chapterId = chapterId
        person.appearanceCount = appearanceDays.count
        person.firstSeenDate = dateForDay(firstDay)
        person.lastSeenDate = dateForDay(lastDay)
        context.insert(person)

        for day in appearanceDays {
            let appearance = PersonAppearance(
                personId: person.id,
                timestamp: dateForDay(day),
                source: "calendar",
                context: primaryContext,
                rawText: nil
            )
            appearance.moodAtTime = max(0, min(1, dayMood(day) + moodDelta))
            appearance.stressAtTime = nil
            context.insert(appearance)
        }
    }

    // MARK: - Deterministic Generators

    /// The mean mood on a given day, matching the state-generation formula (the
    /// hourly jitter averages out, so the day-level value is base − 0.5·sNoise).
    private static func dayMood(_ day: Int) -> Double {
        let after = day >= 90
        let sNoise = noise(day, 2) * 0.12
        let mNoise = noise(day, 4) * 0.10
        let baseMood = after ? 0.62 : 0.54
        return baseMood - 0.5 * sNoise + mNoise
    }

    /// Deterministic pseudo-random value in −1…1 from a day index and a channel.
    /// A fixed hash, so every run seeds an identical life.
    private static func noise(_ day: Int, _ channel: Int) -> Double {
        var x = UInt64(bitPattern: Int64(day &* 6_364_136_223_846_793_005 &+ channel &* 1_442_695_040_888_963_407))
        x ^= x >> 33
        x = x &* 0xff51_afd7_ed55_8ccd
        x ^= x >> 33
        let unit = Double(x % 10_000) / 10_000.0
        return unit * 2.0 - 1.0
    }
}
#endif
