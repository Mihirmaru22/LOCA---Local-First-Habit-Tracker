package com.loca.android.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

private val LightColors = lightColorScheme(
    primary         = LOCAColors.primaryLight,
    onPrimary       = LOCAColors.onPrimaryLight,
    primaryContainer    = LOCAColors.primaryContainerLight,
    onPrimaryContainer  = LOCAColors.onPrimaryContainerLight,
    secondary       = LOCAColors.secondaryLight,
    onSecondary     = LOCAColors.onSecondaryLight,
    background      = LOCAColors.backgroundLight,
    onBackground    = LOCAColors.onBackgroundLight,
    surface         = LOCAColors.surfaceLight,
    onSurface       = LOCAColors.onSurfaceLight,
    surfaceVariant  = LOCAColors.surfaceVariantLight,
    onSurfaceVariant = LOCAColors.onSurfaceVariantLight,
)

private val DarkColors = darkColorScheme(
    primary         = LOCAColors.primaryDark,
    onPrimary       = LOCAColors.onPrimaryDark,
    primaryContainer    = LOCAColors.primaryContainerDark,
    onPrimaryContainer  = LOCAColors.onPrimaryContainerDark,
    secondary       = LOCAColors.secondaryDark,
    onSecondary     = LOCAColors.onSecondaryDark,
    background      = LOCAColors.backgroundDark,
    onBackground    = LOCAColors.onBackgroundDark,
    surface         = LOCAColors.surfaceDark,
    onSurface       = LOCAColors.onSurfaceDark,
    surfaceVariant  = LOCAColors.surfaceVariantDark,
    onSurfaceVariant = LOCAColors.onSurfaceVariantDark,
)

@Composable
fun LOCATheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else      -> LightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography  = LOCATypography,
        content     = content
    )
}
