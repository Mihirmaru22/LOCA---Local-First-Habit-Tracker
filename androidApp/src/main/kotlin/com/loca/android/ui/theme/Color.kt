package com.loca.android.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * LOCA color system — consistent across all three pillars.
 *
 * Each pillar gets a distinct accent that works in both light and dark,
 * but shares the same neutral base so the app feels unified.
 *
 * Pillar accents:
 *  Habits  → Indigo   (#5C6BC0 light / #7986CB dark)
 *  Journal → Teal     (#26A69A light / #4DB6AC dark)
 *  Todo    → Amber    (#FFA726 light / #FFB74D dark)
 */
object LOCAColors {

    // ── Primary (Habits / brand) ─────────────────────────────────────────────
    val primaryLight            = Color(0xFF5C6BC0)
    val onPrimaryLight          = Color(0xFFFFFFFF)
    val primaryContainerLight   = Color(0xFFE8EAF6)
    val onPrimaryContainerLight = Color(0xFF1A237E)

    val primaryDark             = Color(0xFF7986CB)
    val onPrimaryDark           = Color(0xFF1A237E)
    val primaryContainerDark    = Color(0xFF283593)
    val onPrimaryContainerDark  = Color(0xFFE8EAF6)

    // ── Secondary (Journal) ──────────────────────────────────────────────────
    val secondaryLight          = Color(0xFF26A69A)
    val onSecondaryLight        = Color(0xFFFFFFFF)

    val secondaryDark           = Color(0xFF4DB6AC)
    val onSecondaryDark         = Color(0xFF004D40)

    // ── Tertiary (Todo) ──────────────────────────────────────────────────────
    val tertiaryLight           = Color(0xFFFFA726)
    val tertiaryDark            = Color(0xFFFFB74D)

    // ── Neutral base ─────────────────────────────────────────────────────────
    val backgroundLight         = Color(0xFFF8F9FA)
    val onBackgroundLight       = Color(0xFF1C1B20)
    val surfaceLight            = Color(0xFFFFFFFF)
    val onSurfaceLight          = Color(0xFF1C1B20)
    val surfaceVariantLight     = Color(0xFFEEEFF5)
    val onSurfaceVariantLight   = Color(0xFF45464F)

    val backgroundDark          = Color(0xFF111318)
    val onBackgroundDark        = Color(0xFFE3E2E8)
    val surfaceDark             = Color(0xFF1C1B20)
    val onSurfaceDark           = Color(0xFFE3E2E8)
    val surfaceVariantDark      = Color(0xFF45464F)
    val onSurfaceVariantDark    = Color(0xFFC5C6D0)

    // ── Pillar accent helpers (used directly in pillar UI) ───────────────────
    val habitsAccent    = primaryLight
    val journalAccent   = secondaryLight
    val todoAccent      = tertiaryLight

    val habitsAccentDark    = primaryDark
    val journalAccentDark   = secondaryDark
    val todoAccentDark      = tertiaryDark
}
