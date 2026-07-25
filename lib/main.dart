import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  debugPrint('main start');
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ────────────────────────────────────────────────────────────────
  await Firebase.initializeApp();
  debugPrint('✅ Firebase initialized');

  // Register background message handler (must be before runApp).
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialise local notifications plugin + Android channel.
  await PermissionService.initLocalNotifications();
  debugPrint('✅ Local notifications initialized');

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  debugPrint('✅ Environment variables loaded');

  if (AppSupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppSupabaseConfig.url,
        anonKey: AppSupabaseConfig.publishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(const Duration(seconds: 10));

      debugPrint('✅ Supabase initialized');
      debugPrint('Client ready: ${AppSupabaseConfig.isAvailable()}');
      try {
        final client = AppSupabaseConfig.clientOrNull();
        debugPrint('Current user: ${client?.auth.currentUser}');
      } catch (e) {
        debugPrint('Current user check failed: $e');
      }
    } catch (e, st) {
      debugPrint('Supabase initialization failed: $e');
      debugPrint(st.toString());
    }
  } else {
    debugPrint('Supabase configuration missing; continuing without remote auth');
  }

  debugPrint('before runApp');
  runApp(const KoolanApp());
  debugPrint('after runApp');
}
