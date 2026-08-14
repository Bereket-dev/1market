import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central crash / non-fatal reporting with PII scrubbing.
///
/// In debug: logs to console only.
/// In release/profile: forwards to Firebase Crashlytics when available.
class ErrorReporter {
  ErrorReporter._();

  static bool _crashlyticsReady = false;

  /// Call after [Firebase.initializeApp] succeeds.
  static Future<void> initialize({required bool enabled}) async {
    if (!enabled) {
      _crashlyticsReady = false;
      return;
    }
    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      _crashlyticsReady = !kDebugMode;
    } catch (e) {
      _crashlyticsReady = false;
      if (kDebugMode) {
        debugPrint('[ErrorReporter] Crashlytics init failed: $e');
      }
    }
  }

  static void log(String message) {
    final scrubbed = scrub(message);
    if (kDebugMode) {
      debugPrint(scrubbed);
      return;
    }
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.log(scrubbed);
    }
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    final scrubbedError = scrub(error.toString());
    final scrubbedReason = reason == null ? null : scrub(reason);

    if (kDebugMode) {
      debugPrint(
        '[ErrorReporter] ${fatal ? 'FATAL' : 'non-fatal'}: '
        '${scrubbedReason ?? scrubbedError}',
      );
      if (stack != null) debugPrint(stack.toString());
      return;
    }

    if (!_crashlyticsReady) return;

    try {
      if (scrubbedReason != null) {
        await FirebaseCrashlytics.instance.log(scrubbedReason);
      }
      await FirebaseCrashlytics.instance.recordError(
        scrubbedError,
        stack,
        fatal: fatal,
        reason: scrubbedReason,
      );
    } catch (_) {
      // Never let reporting crash the app.
    }
  }

  static Future<void> setUserId(String? userId) async {
    if (!_crashlyticsReady) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (_) {}
  }

  /// Redacts emails, phones, JWTs, bearer tokens, and common secret keys.
  static String scrub(String input) {
    var out = input;
    out = out.replaceAll(
      RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
      '[redacted-email]',
    );
    out = out.replaceAll(RegExp(r'\+?\d[\d\s\-()]{7,}\d'), '[redacted-phone]');
    out = out.replaceAll(
      RegExp(r'bearer\s+[a-z0-9\-._~+/]+=*', caseSensitive: false),
      'Bearer [redacted-token]',
    );
    out = out.replaceAll(
      RegExp(r'eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*'),
      '[redacted-jwt]',
    );
    out = out.replaceAllMapped(
      RegExp(
        r'(api[_-]?key|api[_-]?secret|password|token|authorization)'
        r'\s*[:=]\s*\S+',
        caseSensitive: false,
      ),
      (m) => '${m[1]}=[redacted]',
    );
    return out;
  }
}
