import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../errors/error_reporter.dart';
import '../../shared/services/permission_service.dart';

/// Result of [ServiceBootstrap.initialize].
class BootstrapResult {
  const BootstrapResult({
    required this.ok,
    this.errorCode,
    this.supabaseReady = false,
  });

  final bool ok;

  /// Stable machine code for UI mapping (never a raw exception string).
  final String? errorCode;
  final bool supabaseReady;
}

/// Initializes Firebase, dotenv (debug attempt), Supabase, notifications.
///
/// Retryable from the bootstrap / init error UI.
class ServiceBootstrap {
  ServiceBootstrap._();

  static bool _dotenvLoaded = false;
  static bool _firebaseReady = false;
  static bool _supabaseReady = false;
  static bool _notificationsReady = false;

  static Future<BootstrapResult> initialize() async {
    // 1. Firebase
    if (!_firebaseReady) {
      try {
        await Firebase.initializeApp();
        _firebaseReady = true;
        await ErrorReporter.initialize(enabled: true);
        if (kDebugMode) debugPrint('[bootstrap] Firebase ready');
      } catch (e, st) {
        await ErrorReporter.recordError(e, st, reason: 'firebase_init');
        if (kDebugMode) debugPrint('[bootstrap] Firebase failed: $e');
      }
    }

    // 2. Bundled client config (Supabase URL + anon key + OAuth IDs).
    //    Synced from project-root .env → assets/config/local.env before builds.
    if (!_dotenvLoaded) {
      try {
        await dotenv.load(fileName: 'assets/config/local.env');
        _dotenvLoaded = true;
        if (kDebugMode) debugPrint('[bootstrap] local.env loaded from assets');
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[bootstrap] local.env not loaded ($e)\n'
            '  Run: dart run tool/sync_local_env.dart',
          );
        }
      }
    }

    if (kDebugMode) AppSupabaseConfig.debugLogSource();

    // 3. Supabase — required when config is present.
    if (AppSupabaseConfig.isConfigured) {
      if (!_supabaseReady) {
        try {
          await Supabase.initialize(
            url: AppSupabaseConfig.url,
            publishableKey: AppSupabaseConfig.publishableKey,
            authOptions: const FlutterAuthClientOptions(
              authFlowType: AuthFlowType.pkce,
            ),
            // Do NOT set Accept-Encoding manually. Dart's HttpClient already
            // negotiates gzip and auto-decompresses. Overriding the header
            // disables that decompression, so PostgREST bodies arrive as
            // binary and every listings/services fetch fails to parse —
            // empty home feed for both guests and signed-in users.
          ).timeout(const Duration(seconds: 10));
          _supabaseReady = true;
          if (kDebugMode) debugPrint('[bootstrap] Supabase ready');
        } catch (e, st) {
          await ErrorReporter.recordError(e, st, reason: 'supabase_init');
          return const BootstrapResult(
            ok: false,
            errorCode: 'supabase_init_failed',
            supabaseReady: false,
          );
        }
      }
    } else if (kDebugMode) {
      debugPrint(
        '[bootstrap] Supabase config missing — run:\n'
        '  dart run tool/sync_local_env.dart\n'
        '  (requires project-root .env with SUPABASE_URL and SUPABASE_ANON_KEY)',
      );
    }

    // 4. Local notifications
    if (!_notificationsReady) {
      try {
        await PermissionService.initLocalNotifications();
        _notificationsReady = true;
      } catch (e, st) {
        await ErrorReporter.recordError(
          e,
          st,
          reason: 'notifications_init',
        );
      }
    }

    return BootstrapResult(
      ok: true,
      supabaseReady: _supabaseReady || !AppSupabaseConfig.isConfigured,
    );
  }
}

/// Must be registered before [runApp].
void registerFcmBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
}
