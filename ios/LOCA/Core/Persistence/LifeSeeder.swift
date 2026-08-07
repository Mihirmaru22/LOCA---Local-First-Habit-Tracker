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
/// `#if DEBUG` around the whole file.
///
/// ## P0 Idempotency model (per-tier guards)
/// Each entity family is gated independently: states, events, chapters, people,
/// traits, and direction. This fixes the "No Events Yet" stale-store bug where
/// old stores that were seeded before events were added had states but no events
/// and the old single-probe guard suppressed the entire seeder.
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

    // MARK: - Public API

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        // Per-tier probes — each entity family is seeded independently.
        var stateProbe = FetchDescriptor<InferredState>(); stateProbe.fetchLimit = 1
        var eventProbe = FetchDescriptor<LifeEvent>(); eventProbe.fetchLimit = 1
        var chapterProbe = FetchDescriptor<Chapter>(); chapterProbe.fetchLimit = 1
        var personProbe = FetchDescriptor<Person>(); personProbe.fetchLimit = 1
        var traitProbe = FetchDescriptor<Trait>(); traitProbe.fetchLimit = 1
        var directionProbe = FetchDescriptor<Direction>(); directionProbe.fetchLimit = 1

        let hasStates    = (try? context.fetch(stateProbe))?.isEmpty == false
        let hasEvents    = (try? context.fetch(eventProbe))?.isEmpty == false
        let hasChapters  = (try? context.fetch(chapterProbe))?.isEmpty == false
        let hasPeople    = (try? context.fetch(personProbe))?.isEmpty == false
        let hasTraits    = (try? context.fetch(traitProbe))?.isEmpty == false
        let hasDirection = (try? context.fetch(directionProbe))?.isEmpty == false

        // All tiers present — nothing to do.
        guard !hasStates || !hasEvents || !hasChapters || !hasPeople || !hasTraits || !hasDirection else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = 180
        let eventDay = 90
        let hoursOfDay = [8, 12, 18, 22]

        func date(forDay day: Int, hour: Int = 0) -> Date {
            let base = calendar.date(byAdding: .day, value: -(totalDays - day), to: today) ?? today
            return calendar.date(byAdding: .hour, value: hour, to: base) ?? base
        }

        // MARK: States

        if !hasStates {
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
                    let ts = date(forDay: day, hour: hour)
                    let windowStart = ts.addingTimeInterval(-3600)

                    let state = InferredState(
                        timestamp: ts,
                        energy: baseEnergy + eNoise + jitter,
                        energyUncertainty: 0.16,
                        stress: baseStress + sNoise + jitter,
                        stressUncertainty: 0.18,
                        focus: baseFocus + 0.5 * eNoise + fNoise + jitter,
                        focusUncertainty: 0.20,
                        mood: baseMood - 0.5 * sNoise + mNoise + jitter,
                        moodUncertainty: 0.17
                    )

                    // P0: Seed provenance (C1.2) and uncertainty type (C1.3) so
                    // F2a/F2b surfaces show evidence on seeded data. sampleCount ≥ 3
                    // → aleatoric (inherent noise, more data won't eliminate it).
                    let eProv = InferenceProvenance.create(
                        sources: [SignalSource.sleep.rawValue, SignalSource.motionActivity.rawValue],
                        sampleCount: 4, windowStart: windowStart, windowEnd: ts
                    )
                    let sProv = InferenceProvenance.create(
                        sources: [SignalSource.heartRate.rawValue, SignalSource.motionActivity.rawValue],
                        sampleCount: 4, windowStart: windowStart, windowEnd: ts
                    )
                    let fProv = InferenceProvenance.create(
                        sources: [SignalSource.sleep.rawValue, SignalSource.calendar.rawValue],
                        sampleCount: 4, windowStart: windowStart, windowEnd: ts
                    )
                    let mProv = InferenceProvenance.create(
                        sources: [SignalSource.deviceActivity.rawValue, SignalSource.motionActivity.rawValue],
                        sampleCount: 4, windowStart: windowStart, windowEnd: ts
                    )

                    state.energyProvenanceJSON    = eProv.jsonEncoded()
                    state.stressProvenanceJSON    = sProv.jsonEncoded()
                    state.focusProvenanceJSON     = fProv.jsonEncoded()
                    state.moodProvenanceJSON      = mProv.jsonEncoded()
                    state.energyUncertaintyTypeRaw = eProv.uncertaintyType.rawValue
                    state.stressUncertaintyTypeRaw = sProv.uncertaintyType.rawValue
                    state.focusUncertaintyTypeRaw  = fProv.uncertaintyType.rawValue
                    state.moodUncertaintyTypeRaw   = mProv.uncertaintyType.rawValue

                    context.insert(state)
                }
            }
        }

        // MARK: Life Event

        // Resolve the event — either create fresh (if missing) or fetch the existing
        // one so that chapters can reference its stable UUID.
        let event: LifeEvent
        if !hasEvents {
            let freshEvent = LifeEvent(
                timestamp: date(forDay: eventDay, hour: 9),
                eventType: .workChange,
                confidence: 0.85,
                anomalyScore: 2.4,
                persistenceScore: 0.82,
                classificationScore: 0.85,
                metadata: ["summary": "Started internship"]
            )
            context.insert(freshEvent)
            event = freshEvent
        } else {
            // Fetch the existing event to get its stable ID for chapter links.
            guard let existingEvent = (try? context.fetch(FetchDescriptor<LifeEvent>()))?.first else {
                // Should not happen (hasEvents was true), but skip safely.
                try? context.save()
                return
            }
            event = existingEvent
        }

        // MARK: Chapters
        //
        // Track the internship chapter ID locally so the direction tier can reference
        // it even before context.save() makes it queryable via a predicate fetch.
        var seededInternshipId: UUID? = nil

        if !hasChapters {
            let before = Chapter(startDate: date(forDay: 0))
            before.name = "Before the Internship"
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
                openingEventId: event.id
            )
            internship.name = "The Internship"
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
            seededInternshipId = internship.id
        }

        // MARK: People + Appearances

        if !hasPeople {
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
                chapterId: nil,
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
        }

        // MARK: Traits

        if !hasTraits {
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
        }

        // MARK: Direction + Forks

        if !hasDirection {
            // Resolve the internship chapter ID: prefer the local variable set above
            // (chapters just seeded in this run); fall back to a fetch if chapters
            // already existed in the store.
            let internshipChapterId: UUID?
            if let freshId = seededInternshipId {
                internshipChapterId = freshId
            } else {
                var chapterDesc = FetchDescriptor<Chapter>()
                chapterDesc.predicate = #Predicate { $0.isCurrentChapter }
                chapterDesc.fetchLimit = 1
                internshipChapterId = (try? context.fetch(chapterDesc))?.first?.id
            }

            let direction = Direction(
                statement: "Growing into the internship — figuring out what kind of work I actually want to do",
                values: ["deep work", "clarity", "building things that matter"],
                intentions: ["ship something I'm proud of", "understand what energizes me"],
                settledness: 0.45,
                chapterId: internshipChapterId
            )
            direction.capturedAt = date(forDay: eventDay + 2, hour: 20)
            direction.updatedAt  = date(forDay: eventDay + 2, hour: 20)
            context.insert(direction)

            let forkTookOffer = Fork(
                statement: "Decided to take the internship offer instead of staying in school",
                kind: .decision,
                directionId: direction.id,
                chapterId: nil
            )
            forkTookOffer.timestamp = date(forDay: eventDay - 10, hour: 19)
            forkTookOffer.resolved = true
            forkTookOffer.resolution = "Took it. Harder than expected in week one, but settling."
            context.insert(forkTookOffer)

            let forkTeamChange = Fork(
                statement: "Should I ask to move to the other team?",
                kind: .question,
                directionId: direction.id,
                chapterId: internshipChapterId
            )
            forkTeamChange.timestamp = date(forDay: eventDay + 45, hour: 21)
            context.insert(forkTeamChange)
        }

        // MARK: Signals (recent, for realism + validation surfaces)

        var signalProbe = FetchDescriptor<SignalEvent>(); signalProbe.fetchLimit = 1
        if (try? context.fetch(signalProbe))?.isEmpty != false {
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
        }

        do {
            try context.save()
        } catch {
            // Debug-only convenience seeding — a failure here just means the app
            // launches with an empty life model, same as if seeding never ran.
        }
    }

    // MARK: - Reset & Reseed (DEBUG only)

    /// Deletes all seeded entity families and re-seeds from scratch.
    /// Exposed for the P0 Runtime Self-Check "Reset & Reseed" affordance.
    @MainActor
    static func resetAndReseed(context: ModelContext) {
        for s in (try? context.fetch(FetchDescriptor<InferredState>())) ?? [] { context.delete(s) }
        for e in (try? context.fetch(FetchDescriptor<LifeEvent>()))    ?? [] { context.delete(e) }
        for c in (try? context.fetch(FetchDescriptor<Chapter>()))      ?? [] { context.delete(c) }
        for p in (try? context.fetch(FetchDescriptor<Person>()))       ?? [] { context.delete(p) }
        for a in (try? context.fetch(FetchDescriptor<PersonAppearance>())) ?? [] { context.delete(a) }
        for t in (try? context.fetch(FetchDescriptor<Trait>()))        ?? [] { context.delete(t) }
        for d in (try? context.fetch(FetchDescriptor<Direction>()))    ?? [] { context.delete(d) }
        for f in (try? context.fetch(FetchDescriptor<Fork>()))         ?? [] { context.delete(f) }
        for sig in (try? context.fetch(FetchDescriptor<SignalEvent>())) ?? [] { context.delete(sig) }
        try? context.save()

        seedIfNeeded(context: context)
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

        let person = Person(name: name)
        person.primaryContext = primaryContext
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

    /// The mean mood on a given day, matching the state-generation formula.
    private static func dayMood(_ day: Int) -> Double {
        let after = day >= 90
        let sNoise = noise(day, 2) * 0.12
        let mNoise = noise(day, 4) * 0.10
        let baseMood = after ? 0.62 : 0.54
        return baseMood - 0.5 * sNoise + mNoise
    }

    /// Deterministic pseudo-random value in −1…1 from a day index and a channel.
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
