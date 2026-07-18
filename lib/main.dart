import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  debugPrint('main start');
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  debugPrint('✅ Environment variables loaded');

  if (AppSupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppSupabaseConfig.url,
        publishableKey: AppSupabaseConfig.publishableKey,
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
