package com.loca.record

import kotlinx.coroutines.test.runTest
import kotlinx.datetime.Clock
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.uuid.Uuid

class RecordEngineTest {

    // ── Helpers ───────────────────────────────────────────────────────────────

    private suspend fun makeEngine(): RecordEngine {
        val engine = RecordEngine(InMemoryRecordStore())
        engine.initialize()
        return engine
    }

    private fun habitDraft(
        id: Uuid = Uuid.random(),
        habitID: Uuid = Uuid.random(),
        value: Double = 1.0
    ) = FactDraft(
        id          = id,
        kind        = FactKind.HABIT_LOGGED,
        payload     = FactPayload.HabitLogged(habitID = habitID, value = value),
        occurredAt  = Clock.System.now(),
        source      = FactSource.USER_ENTRY,
        author      = FactAuthor.PERSON,
        entryMethod = EntryMethod.EXPLICIT,
        confidence  = FactConfidence.KNOWN
    )

    // ── Append ────────────────────────────────────────────────────────────────

    @Test
    fun testAppendReturnsFactWithCorrectID() = runTest {
        val engine = makeEngine()
        val draft = habitDraft()
        val fact = engine.append(draft)
        assertEquals(draft.id, fact.id)
    }

    @Test
    fun testAppendedFactHasCorrectKind() = runTest {
        val engine = makeEngine()
        val fact = engine.append(habitDraft())
        assertEquals(FactKind.HABIT_LOGGED, fact.kind)
    }

    @Test
    fun testAppendedFactHasRecordedAt() = runTest {
        val engine = makeEngine()
        val fact = engine.append(habitDraft())
        assertNotNull(fact.recordedAt)
    }

    @Test
    fun testDuplicateIDThrows() = runTest {
        val engine = makeEngine()
        val id = Uuid.random()
        engine.append(habitDraft(id = id))
        assertFailsWith<RecordError.DuplicateFact> {
            engine.append(habitDraft(id = id))
        }
    }

    @Test
    fun testCountIncreasesAfterAppend() = runTest {
        val engine = makeEngine()
        assertEquals(0, engine.count())
        engine.append(habitDraft())
        assertEquals(1, engine.count())
        engine.append(habitDraft())
        assertEquals(2, engine.count())
    }

    // ── Payload validation ────────────────────────────────────────────────────

    @Test
    fun testMismatchedPayloadThrowsValidationFailure() = runTest {
        val engine = makeEngine()
        val draft = FactDraft(
            kind        = FactKind.HABIT_LOGGED,
            payload     = FactPayload.ReflectionWritten(text = "wrong payload"),
            occurredAt  = Clock.System.now(),
            source      = FactSource.USER_ENTRY,
            author      = FactAuthor.PERSON,
            entryMethod = EntryMethod.EXPLICIT,
            confidence  = FactConfidence.KNOWN
        )
        assertFailsWith<RecordError.ValidationFailure> {
            engine.append(draft)
        }
    }

    // ── New FactKinds ─────────────────────────────────────────────────────────

    @Test
    fun testHabitDefinedAppends() = runTest {
        val engine = makeEngine()
        val draft = FactDraft(
            kind        = FactKind.HABIT_DEFINED,
            payload     = FactPayload.HabitDefined(
                habitID = Uuid.random(), name = "Run 5K",
                targetValue = 1.0, frequency = HabitFrequency.DAILY
            ),
            occurredAt  = Clock.System.now(),
            source      = FactSource.USER_ENTRY,
            author      = FactAuthor.PERSON,
            entryMethod = EntryMethod.EXPLICIT,
            confidence  = FactConfidence.KNOWN
        )
        val fact = engine.append(draft)
        assertEquals(FactKind.HABIT_DEFINED, fact.kind)
    }

    @Test
    fun testMemorableMomentAppends() = runTest {
        val engine = makeEngine()
        val draft = FactDraft(
            kind        = FactKind.MEMORABLE_MOMENT_CAPTURED,
            payload     = FactPayload.MemorableMomentCaptured(text = "Won the game"),
            occurredAt  = Clock.System.now(),
            source      = FactSource.USER_ENTRY,
            author      = FactAuthor.PERSON,
            entryMethod = EntryMethod.EXPLICIT,
            confidence  = FactConfidence.KNOWN
        )
        val fact = engine.append(draft)
        assertEquals(FactKind.MEMORABLE_MOMENT_CAPTURED, fact.kind)
    }

    @Test
    fun testTodoCreatedAppends() = runTest {
        val engine = makeEngine()
        val draft = FactDraft(
            kind        = FactKind.TODO_CREATED,
            payload     = FactPayload.TodoCreated(todoID = Uuid.random(), title = "Buy groceries"),
            occurredAt  = Clock.System.now(),
            source      = FactSource.USER_ENTRY,
            author      = FactAuthor.PERSON,
            entryMethod = EntryMethod.EXPLICIT,
            confidence  = FactConfidence.KNOWN
        )
        val fact = engine.append(draft)
        assertEquals(FactKind.TODO_CREATED, fact.kind)
    }

    @Test
    fun testCorrectionSubmittedUsedForTodoEdit() = runTest {
        val engine = makeEngine()
        val todoFactID = Uuid.random()
        val draft = FactDraft(
            kind        = FactKind.CORRECTION_SUBMITTED,
            payload     = FactPayload.CorrectionSubmitted(
                targetFactID    = todoFactID,
                field           = "title",
                correctedValue  = "Buy organic groceries"
            ),
            occurredAt  = Clock.System.now(),
            source      = FactSource.USER_ENTRY,
            author      = FactAuthor.PERSON,
            entryMethod = EntryMethod.EXPLICIT,
            confidence  = FactConfidence.KNOWN
        )
        val fact = engine.append(draft)
        assertEquals(FactKind.CORRECTION_SUBMITTED, fact.kind)
    }

    // ── Ordering (G4) ─────────────────────────────────────────────────────────

    @Test
    fun testReplayableFactsAreInInsertionOrder() = runTest {
        val engine = makeEngine()
        val d1 = habitDraft(); val d2 = habitDraft(); val d3 = habitDraft()
        engine.append(d1); engine.append(d2); engine.append(d3)

        val facts = engine.replayableFacts()
        assertEquals(3, facts.size)
        assertEquals(d1.id, facts[0].id)
        assertEquals(d2.id, facts[1].id)
        assertEquals(d3.id, facts[2].id)
    }

    // ── Query ─────────────────────────────────────────────────────────────────

    @Test
    fun testQueryByKindFilters() = runTest {
        val engine = makeEngine()
        engine.append(habitDraft())
        engine.append(FactDraft(
            kind        = FactKind.REFLECTION_WRITTEN,
            payload     = FactPayload.ReflectionWritten(text = "today was good"),
            occurredAt  = Clock.System.now(),
            source      = FactSource.USER_ENTRY,
            author      = FactAuthor.PERSON,
            entryMethod = EntryMethod.EXPLICIT,
            confidence  = FactConfidence.KNOWN
        ))

        val habits = engine.facts(RecordQuery.forKind(FactKind.HABIT_LOGGED))
        val reflections = engine.facts(RecordQuery.forKind(FactKind.REFLECTION_WRITTEN))

        assertEquals(1, habits.size)
        assertEquals(1, reflections.size)
        assertTrue(habits.all { it.kind == FactKind.HABIT_LOGGED })
    }

    @Test
    fun testQueryByPillarFilters() = runTest {
        val engine = makeEngine()
        engine.append(habitDraft())
        engine.append(FactDraft(
            kind        = FactKind.MEMORABLE_MOMENT_CAPTURED,
            payload     = FactPayload.MemorableMomentCaptured(text = "Great day"),
            occurredAt  = Clock.System.now(),
            source      = FactSource.USER_ENTRY,
            author      = FactAuthor.PERSON,
            entryMethod = EntryMethod.EXPLICIT,
            confidence  = FactConfidence.KNOWN
        ))

        val journalFacts = engine.facts(RecordQuery.forPillar(Pillar.JOURNAL))
        assertEquals(1, journalFacts.size)
        assertEquals(FactKind.MEMORABLE_MOMENT_CAPTURED, journalFacts[0].kind)
    }
}
