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

  // ── Read persisted theme and locale synchronously ────────────────────────
  // These are fast SharedPreferences reads so the first frame never flashes
  // the wrong theme/language.
  bool initialDarkMode = false;
  String initialLocale = 'en';
  try {
    final prefs = await SharedPreferences.getInstance();
    initialDarkMode = prefs.getBool('koolan_dark_mode') ?? false;
    initialLocale = prefs.getString('koolan_language') ?? 'en';
  } catch (_) {
    // SharedPreferences unavailable — use defaults.
  }

  // ── runApp immediately ───────────────────────────────────────────────────
  // The native splash is still visible at this point. The Flutter init screen
  // (_InitializingScreen) will be shown while the heavy services load in the
  // background below.
  runApp(KoolanApp(
    initialDarkMode: initialDarkMode,
    initialLocale: initialLocale,
  ));

  // ── Deferred heavy initialisation (runs after first frame) ───────────────
  // Everything below happens asynchronously. The app shell shows a loading
  // indicator (controlled by OnboardingPhase.initializing in app_state) while
  // these complete, so the user sees branded UI almost immediately.
  _initServices();
}

/// Initialises Firebase, dotenv, Supabase and local notifications in order.
/// Called after [runApp] so it never blocks first-frame rendering.
Future<void> _initServices() async {
  // 1. Firebase — needed by Supabase FCM integration.
  try {
    await Firebase.initializeApp();
    if (kDebugMode) debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('[init] Firebase.initializeApp failed: $e');
  }

  // 2. Load .env for local debug runs (not bundled in release builds).
  //    AppSupabaseConfig reads dart-define first; dotenv is only useful
  //    during local `flutter run` without --dart-define flags.
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('✅ .env loaded (debug)');
    } catch (_) {
      // .env is not required — ignore if missing.
    }
  }

  AppSupabaseConfig.debugLogSource();

  // 3. Supabase — keep a generous but finite timeout.
  if (AppSupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppSupabaseConfig.url,
        anonKey: AppSupabaseConfig.publishableKey,
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
