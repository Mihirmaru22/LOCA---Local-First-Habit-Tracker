package com.loca.record

import kotlinx.serialization.Serializable

/**
 * Every kind of event the Record can store.
 *
 * Pillars:
 *  - Habits  : HABIT_DEFINED, HABIT_LOGGED
 *  - Journal : REFLECTION_WRITTEN, MEMORABLE_MOMENT_CAPTURED, INTENTION_SET
 *  - Todo    : TODO_CREATED, TODO_COMPLETED
 *  - Infra   : shared across all pillars (correction, deletion, health, consent…)
 *  - Life    : deferred — defined now, implemented later
 *
 * Data sharing rules:
 *  - Habits ↔ Journal  share signals
 *  - Habits, Journal, Todo  all feed into Life
 *  - Todo  is standalone (does not share with Habits or Journal)
 *  - Life  is the master synthesis pillar (receives from all three)
 *
 * Adding a new kind is additive — no migration required.
 * Deferred Life kinds are present so the type system is complete from day one.
 */
@Serializable
enum class FactKind {

    // ── Habits pillar ────────────────────────────────────────────────────────

    /** Defines or updates a habit (name, target, frequency). */
    HABIT_DEFINED,

    /** User logs a completion of a habit. */
    HABIT_LOGGED,

    // ── Journal pillar ───────────────────────────────────────────────────────

    /** User writes a reflection or free-form journal entry. */
    REFLECTION_WRITTEN,

    /** User captures a memorable moment for the day. */
    MEMORABLE_MOMENT_CAPTURED,

    /** User sets an intention or goal for a period. */
    INTENTION_SET,

    // ── Todo pillar ──────────────────────────────────────────────────────────

    /** User creates a new task. */
    TODO_CREATED,

    /** User marks a task as complete. */
    TODO_COMPLETED,

    // ── Infrastructure (shared across all pillars) ───────────────────────────

    /** Imported health sample (steps, sleep, heart rate…) from Health Connect. */
    HEALTH_SAMPLE_IMPORTED,

    /**
     * User corrects a previously recorded fact.
     * Also used to edit a Todo (title, due date) — reuses this kind
     * rather than introducing a separate TODO_UPDATED kind.
     */
    CORRECTION_SUBMITTED,

    /** User confirms a landmark or previously uncertain fact. */
    CONFIRMATION_SUBMITTED,

    /** User requests deletion of a fact or group of facts. */
    DELETION_REQUESTED,

    /** App permission state changed (e.g. Health Connect, notifications). */
    PERMISSION_CHANGED,

    /** User consent state changed for a data source. */
    CONSENT_CHANGED,

    // ── Life pillar (deferred — defined, not yet implemented) ────────────────

    /** User checks in their current mood, energy, focus, or stress. */
    STATE_CHECKED_IN,

    /** User sets or updates a personal direction / long-term goal. */
    DIRECTION_CHANGED,

    /** User asks a reflective question (for AI or self-guided prompts). */
    QUESTION_ASKED,

    /** Calendar event imported from device calendar. */
    CALENDAR_EVENT_IMPORTED;

    /** Pillar this kind belongs to. Used for routing and UI grouping. */
    val pillar: Pillar get() = when (this) {
        HABIT_DEFINED,
        HABIT_LOGGED                -> Pillar.HABITS

        REFLECTION_WRITTEN,
        MEMORABLE_MOMENT_CAPTURED,
        INTENTION_SET               -> Pillar.JOURNAL

        TODO_CREATED,
        TODO_COMPLETED              -> Pillar.TODO

        HEALTH_SAMPLE_IMPORTED,
        CORRECTION_SUBMITTED,
        CONFIRMATION_SUBMITTED,
        DELETION_REQUESTED,
        PERMISSION_CHANGED,
        CONSENT_CHANGED             -> Pillar.INFRA

        STATE_CHECKED_IN,
        DIRECTION_CHANGED,
        QUESTION_ASKED,
        CALENDAR_EVENT_IMPORTED     -> Pillar.LIFE
    }

    /** Whether this kind is active (implemented) in the current build. */
    val isImplemented: Boolean get() = pillar != Pillar.LIFE
}

/**
 * The four user-facing pillars plus the infrastructure pillar.
 */
@Serializable
enum class Pillar {
    HABITS,
    JOURNAL,
    TODO,
    LIFE,
    INFRA
}
