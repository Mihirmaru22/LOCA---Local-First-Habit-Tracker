package com.loca.signal

import com.loca.record.EntryMethod
import com.loca.record.FactAuthor
import com.loca.record.FactConfidence
import com.loca.record.FactDraft
import com.loca.record.FactKind
import com.loca.record.FactPayload
import com.loca.record.FactSource
import com.loca.record.InMemoryRecordStore
import com.loca.record.RecordEngine
import kotlinx.coroutines.test.runTest
import kotlinx.datetime.Clock
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.uuid.Uuid

class SignalEngineTest {

    // ── Helpers ───────────────────────────────────────────────────────────────

    private suspend fun makeRecord(): RecordEngine {
        val engine = RecordEngine(InMemoryRecordStore())
        engine.initialize()
        return engine
    }

    private suspend fun makeSignals(): SignalEngine {
        val engine = SignalEngine(InMemorySignalStore())
        engine.initialize()
        return engine
    }

    private fun draft(
        kind: FactKind,
        payload: FactPayload,
        id: Uuid = Uuid.random()
    ) = FactDraft(
        id          = id,
        kind        = kind,
        payload     = payload,
        occurredAt  = Clock.System.now(),
        source      = FactSource.USER_ENTRY,
        author      = FactAuthor.PERSON,
        entryMethod = EntryMethod.EXPLICIT,
        confidence  = FactConfidence.KNOWN
    )

    private fun habitDraft(id: Uuid = Uuid.random()) =
        draft(FactKind.HABIT_LOGGED, FactPayload.HabitLogged(Uuid.random(), 1.0), id)

    // ── S1: one signal per fact / idempotency ──────────────────────────────────

    @Test
    fun testProcessProducesSignalWithSameID() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(habitDraft())

        val signal = signals.process(fact)
        assertNotNull(signal)
        assertEquals(fact.id, signal.id)
        assertEquals(SignalKind.HABIT_COMPLETION, signal.kind)
    }

    @Test
    fun testProcessingSameFactTwiceIsIdempotent() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(habitDraft())

        val first = signals.process(fact)
        val second = signals.process(fact)
        assertNotNull(first)
        assertNull(second)
        assertEquals(1, signals.count())
    }

    // ── S2: determinism ─────────────────────────────────────────────────────────

    @Test
    fun testDeterministicIDAndPayloadAcrossReplay() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(habitDraft())
        signals.process(fact)
        val before = signals.allSignals().single()

        signals.replay(from = record.replayableFacts())
        val after = signals.allSignals().single()

        assertEquals(before.id, after.id)
        assertEquals(before.kind, after.kind)
        assertEquals(before.payload, after.payload)
    }

    // ── S3: replay completeness ─────────────────────────────────────────────────

    @Test
    fun testReplayReproducesSameSignalSet() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        repeat(5) { record.append(habitDraft()) }
        val facts = record.replayableFacts()
        signals.processAll(facts)
        val idsBefore = signals.allSignals().map { it.id }.toSet()

        signals.replay(from = facts)
        val idsAfter = signals.allSignals().map { it.id }.toSet()

        assertEquals(5, idsAfter.size)
        assertEquals(idsBefore, idsAfter)
    }

    // ── S4: provenance completeness ─────────────────────────────────────────────

    @Test
    fun testEverySignalCarriesProvenance() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(habitDraft())
        val signal = signals.process(fact)!!

        assertEquals(fact.id, signal.provenance.sourceFactID)
        assertEquals(FactKind.HABIT_LOGGED, signal.provenance.sourceFactKind)
        assertEquals(FactSource.USER_ENTRY, signal.provenance.factSource)
        assertEquals(SignalPipeline.VERSION, signal.provenance.pipelineVersion)
    }

    // ── S6: no orphan signals (validator) ───────────────────────────────────────

    @Test
    fun testValidatorPassesForCleanSet() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        repeat(3) { record.append(habitDraft()) }
        val facts = record.replayableFacts()
        signals.processAll(facts)

        SignalContract.validateInvariants(
            signals = signals.allSignals(),
            facts = facts,
            expectedCount = 3
        )
    }

    @Test
    fun testValidatorDetectsOrphan() = runTest {
        val signals = makeSignals()
        val record = makeRecord()
        val fact = record.append(habitDraft())
        signals.process(fact)

        // Validate against an empty fact set — the signal is now an orphan.
        val result = SignalValidator().validate(signals.allSignals(), facts = emptyList())
        assertTrue(result.orphanSignals.isNotEmpty())
        assertTrue(!result.isValid)
    }

    @Test
    fun testContractThrowsOnCountMismatch() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(habitDraft())
        signals.process(fact)

        assertFailsWith<SignalContractError.CountMismatch> {
            SignalContract.validateInvariants(
                signals = signals.allSignals(),
                facts = record.replayableFacts(),
                expectedCount = 99
            )
        }
    }

    // ── New pillar signals ──────────────────────────────────────────────────────

    @Test
    fun testHabitDefinedProducesHabitDefinitionSignal() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(draft(
            FactKind.HABIT_DEFINED,
            FactPayload.HabitDefined(habitID = Uuid.random(), name = "Run 5K")
        ))
        val signal = signals.process(fact)!!
        assertEquals(SignalKind.HABIT_DEFINITION, signal.kind)
        assertTrue(signal.payload is SignalPayload.HabitDefinition)
    }

    @Test
    fun testMemorableMomentProducesMemorableMomentSignal() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(draft(
            FactKind.MEMORABLE_MOMENT_CAPTURED,
            FactPayload.MemorableMomentCaptured(text = "Won the game", tags = listOf("sport"))
        ))
        val signal = signals.process(fact)!!
        assertEquals(SignalKind.MEMORABLE_MOMENT, signal.kind)
        val payload = signal.payload as SignalPayload.MemorableMoment
        assertEquals("Won the game", payload.text)
        assertEquals(listOf("sport"), payload.tags)
    }

    @Test
    fun testIntentionProducesIntentionSignal() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(draft(
            FactKind.INTENTION_SET,
            FactPayload.IntentionSet(text = "Read every day")
        ))
        val signal = signals.process(fact)!!
        assertEquals(SignalKind.INTENTION, signal.kind)
    }

    @Test
    fun testTodoCreatedProducesTodoCreationSignal() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val todoID = Uuid.random()
        val fact = record.append(draft(
            FactKind.TODO_CREATED,
            FactPayload.TodoCreated(todoID = todoID, title = "Buy groceries")
        ))
        val signal = signals.process(fact)!!
        assertEquals(SignalKind.TODO_CREATION, signal.kind)
        assertEquals(todoID, (signal.payload as SignalPayload.TodoCreation).todoID)
    }

    @Test
    fun testTodoCompletedProducesTodoCompletionSignal() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val todoID = Uuid.random()
        val fact = record.append(draft(
            FactKind.TODO_COMPLETED,
            FactPayload.TodoCompleted(todoID = todoID)
        ))
        val signal = signals.process(fact)!!
        assertEquals(SignalKind.TODO_COMPLETION, signal.kind)
    }

    @Test
    fun testCorrectionForTodoEditProducesCorrectionSignal() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        val fact = record.append(draft(
            FactKind.CORRECTION_SUBMITTED,
            FactPayload.CorrectionSubmitted(
                targetFactID = Uuid.random(),
                field = "title",
                correctedValue = "Buy organic groceries"
            )
        ))
        val signal = signals.process(fact)!!
        assertEquals(SignalKind.CORRECTION, signal.kind)
        assertEquals("title", (signal.payload as SignalPayload.Correction).field)
    }

    // ── Batch + mixed pillars ───────────────────────────────────────────────────

    @Test
    fun testProcessAllAcrossPillars() = runTest {
        val record = makeRecord()
        val signals = makeSignals()
        record.append(habitDraft())
        record.append(draft(FactKind.REFLECTION_WRITTEN, FactPayload.ReflectionWritten("good day")))
        record.append(draft(FactKind.TODO_CREATED, FactPayload.TodoCreated(Uuid.random(), "task")))

        val produced = signals.processAll(record.replayableFacts())
        assertEquals(3, produced.size)
        assertEquals(3, signals.count())
    }
}
