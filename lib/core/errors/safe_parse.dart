import 'package:flutter/foundation.dart';

import 'error_reporter.dart';

/// Defensive JSON helpers — skip bad rows instead of crashing the app.
class SafeParse {
  SafeParse._();

  /// Parses a list of maps, skipping rows that throw.
  static List<T> mapList<T>(
    Iterable<dynamic> rows,
    T Function(Map<String, dynamic> json) fromJson, {
    String context = 'parse',
  }) {
    final out = <T>[];
    for (final row in rows) {
      try {
        if (row is! Map) continue;
        out.add(fromJson(Map<String, dynamic>.from(row)));
      } catch (e, st) {
        ErrorReporter.recordError(
          e,
          st,
          reason: 'SafeParse.$context skipped bad row',
        );
        if (kDebugMode) {
          debugPrint('[SafeParse] $context skipped row: $e');
        }
      }
    }
    return out;
  }

  /// Tries [fromJson]; returns null and reports on failure.
  static T? tryMap<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic> json) fromJson, {
    String context = 'parse',
  }) {
    if (json == null) return null;
    try {
      return fromJson(json);
    } catch (e, st) {
      ErrorReporter.recordError(
        e,
        st,
        reason: 'SafeParse.$context failed',
      );
      return null;
    }
  }
}
