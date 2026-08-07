package com.loca.android.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val LOCATypography = Typography(
    // Large display — pillar headings, monthly titles
    displayMedium = TextStyle(
        fontWeight  = FontWeight.SemiBold,
        fontSize    = 28.sp,
        lineHeight  = 36.sp,
        letterSpacing = (-0.5).sp
    ),
    // Screen titles
    headlineMedium = TextStyle(
        fontWeight  = FontWeight.SemiBold,
        fontSize    = 22.sp,
        lineHeight  = 28.sp,
        letterSpacing = (-0.25).sp
    ),
    // Section headers, habit names
    titleLarge = TextStyle(
        fontWeight  = FontWeight.Medium,
        fontSize    = 18.sp,
        lineHeight  = 24.sp
    ),
    titleMedium = TextStyle(
        fontWeight  = FontWeight.Medium,
        fontSize    = 15.sp,
        lineHeight  = 20.sp
    ),
    // Body text — journal entries, reflections
    bodyLarge = TextStyle(
        fontWeight  = FontWeight.Normal,
        fontSize    = 16.sp,
        lineHeight  = 24.sp
    ),
    bodyMedium = TextStyle(
        fontWeight  = FontWeight.Normal,
        fontSize    = 14.sp,
        lineHeight  = 20.sp
    ),
    // Captions — dates, metadata, streak counts
    labelSmall = TextStyle(
        fontWeight  = FontWeight.Medium,
        fontSize    = 11.sp,
        lineHeight  = 16.sp,
        letterSpacing = 0.5.sp
    ),
    labelMedium = TextStyle(
        fontWeight  = FontWeight.Medium,
        fontSize    = 12.sp,
        lineHeight  = 16.sp,
        letterSpacing = 0.25.sp
    )
)
