import 'package:flutter/material.dart';
import 'colors.dart';

/// Reusable text-style constants.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: kOnSurface,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: kPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: kOnSurface,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: kOnSurface,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: kOnSurface,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: kOnSurface,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: kOnSurface,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    color: kOnSurfaceVariant,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: kOnSurfaceVariant,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    color: kOnSurfaceVariant,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: kPrimary,
  );

  static const TextStyle priceMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: kPrimary,
  );
}
