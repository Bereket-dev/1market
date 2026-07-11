import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
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
          background: kBackground,
          onBackground: kOnBackground,
          surface: kSurface,
          onSurface: kOnSurface,
          surfaceVariant: kSurfaceVariant,
          onSurfaceVariant: kOnSurfaceVariant,
          outline: kOutline,
          outlineVariant: kOutlineVariant,
        ),
      );
}
