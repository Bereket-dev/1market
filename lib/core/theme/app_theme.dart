import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  );

  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        fontFamily: 'Inter',
        pageTransitionsTheme: _pageTransitions,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: kPrimary,
          onPrimary: kOnPrimary,
          primaryContainer: kPrimaryContainer,
          onPrimaryContainer: kOnPrimaryContainer,
          secondary: kSecondary,
          onSecondary: kOnSecondary,
          secondaryContainer: kSecondaryContainer,
          onSecondaryContainer: kOnSecondaryContainer,
          tertiary: kTertiary,
          onTertiary: kOnTertiary,
          tertiaryContainer: kTertiaryContainer,
          onTertiaryContainer: kOnTertiaryContainer,
          error: kError,
          onError: kOnError,
          errorContainer: kErrorContainer,
          onErrorContainer: kOnErrorContainer,
          surface: kSurface,
          onSurface: kOnSurface,
          surfaceContainerHighest: kSurfaceContainerHighest,
          onSurfaceVariant: kOnSurfaceVariant,
          outline: kOutline,
          outlineVariant: kOutlineVariant,
        ),
        cardTheme: CardThemeData(
          color: kSurfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: kOutlineVariant.withValues(alpha: 0.45)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          elevation: 0,
          foregroundColor: kOnSurface,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: kOnPrimary,
            minimumSize: const Size.fromHeight(50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimary,
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: kPrimary, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kPrimary : kOutline,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? kPrimary.withValues(alpha: 0.3)
                : kOutlineVariant,
          ),
        ),
      );

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kDarkBackground,
        fontFamily: 'Inter',
        pageTransitionsTheme: _pageTransitions,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: kDarkPrimary,
          onPrimary: kDarkOnPrimary,
          primaryContainer: kDarkPrimaryContainer,
          onPrimaryContainer: kDarkOnPrimaryContainer,
          secondary: kDarkSecondary,
          onSecondary: kDarkOnSecondary,
          secondaryContainer: kDarkSecondaryContainer,
          onSecondaryContainer: kDarkOnSecondaryContainer,
          tertiary: kDarkTertiary,
          onTertiary: kDarkOnTertiary,
          tertiaryContainer: kDarkTertiaryContainer,
          onTertiaryContainer: kDarkOnTertiaryContainer,
          error: kDarkError,
          onError: kDarkOnError,
          errorContainer: kDarkErrorContainer,
          onErrorContainer: kDarkOnErrorContainer,
          surface: kDarkSurface,
          onSurface: kDarkOnSurface,
          surfaceContainerHighest: kDarkSurfaceContainerHighest,
          onSurfaceVariant: kDarkOnSurfaceVariant,
          outline: kDarkOutline,
          outlineVariant: kDarkOutlineVariant,
        ),
        cardTheme: CardThemeData(
          color: kDarkSurfaceContainerLow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kDarkOutlineVariant.withValues(alpha: 0.6)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kDarkBackground,
          elevation: 0,
          foregroundColor: kDarkOnSurface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kDarkPrimary,
            foregroundColor: kDarkOnPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? kDarkPrimary : kDarkOutline,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? kDarkPrimary.withValues(alpha: 0.3)
                : kDarkOutlineVariant,
          ),
        ),
      );
}
