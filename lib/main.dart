import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'shared/services/permission_service.dart';

/// FCM background message handler — must be a top-level function.
/// Runs in a separate isolate when the app is terminated or backgrounded.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialised in the background isolate too.
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
  // flutter_local_notifications cannot show heads-up from a background isolate
  // on Android — the system will display the FCM notification automatically
  // if it contains a `notification` payload.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Register FCM background handler before runApp ────────────────────────
  // Must be registered here (before runApp), but does NOT require Firebase
  // to be fully initialised yet — the handler itself calls initializeApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── Read persisted theme and locale ──────────────────────────────────────
  bool initialDarkMode = false;
  String initialLocale = 'en';
  try {
    final prefs = await SharedPreferences.getInstance();
    initialDarkMode = prefs.getBool('koolan_dark_mode') ?? false;
    initialLocale = prefs.getString('koolan_language') ?? 'en';
  } catch (_) {
    // SharedPreferences unavailable — use defaults.
  }

  // ── Heavy init BEFORE runApp ──────────────────────────────────────────────
  // KoolanAppState._initialize() waits on _sessionReadyCompleter, which is
  // only signalled after Supabase fires its initialSession event.  If
  // Supabase has not been initialised yet when that wait starts it will
  // always time out (5 s) and auth/sync will silently fail.
  // Running _initServices() here ensures Firebase, dotenv and Supabase are
  // all ready before the first KoolanAppState is constructed.
  await _initServices();

  runApp(KoolanApp(
    initialDarkMode: initialDarkMode,
    initialLocale: initialLocale,
  ));
}

/// Initialises Firebase, dotenv, Supabase and local notifications in order.
/// Runs synchronously inside [main] — before [runApp] — so that Supabase is
/// ready before [KoolanAppState] is constructed and starts waiting on its
/// [_sessionReadyCompleter].
Future<void> _initServices() async {
  // 1. Firebase — needed by Supabase FCM integration.
  try {
    await Firebase.initializeApp();
    if (kDebugMode) debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('[init] Firebase.initializeApp failed: $e');
  }

  // 2. Load .env (bundled as a Flutter asset).
  //    AppSupabaseConfig reads dart-define first; dotenv fills the gaps
  //    for values not passed via --dart-define (e.g. local debug runs).
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) debugPrint('✅ .env loaded');
  } catch (_) {
    // .env is not required — release builds use --dart-define values.
  }

  AppSupabaseConfig.debugLogSource();

  // 3. Supabase — keep a generous but finite timeout.
  if (AppSupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppSupabaseConfig.url,
        publishableKey: AppSupabaseConfig.publishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(const Duration(seconds: 10));
      if (kDebugMode) debugPrint('✅ Supabase initialized');
    } catch (e, st) {
      debugPrint('[init] Supabase.initialize failed: $e');
      if (kDebugMode) debugPrint(st.toString());
    }
  } else {
    debugPrint('[init] Supabase config missing — continuing without remote auth');
  }

  // 4. Local notifications channel (Android).
  try {
    await PermissionService.initLocalNotifications();
    if (kDebugMode) debugPrint('✅ Local notifications initialized');
  } catch (e) {
    debugPrint('[init] initLocalNotifications failed: $e');
  }
}
