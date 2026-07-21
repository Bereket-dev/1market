import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  print('main start');
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  print('✅ Environment variables loaded');

  if (AppSupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppSupabaseConfig.url,
        publishableKey: AppSupabaseConfig.publishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(const Duration(seconds: 10));

      print('✅ Supabase initialized');
      print('Client ready: ${AppSupabaseConfig.isAvailable()}');
      try {
        final client = AppSupabaseConfig.clientOrNull();
        print('Current user: ${client?.auth.currentUser}');
      } catch (e) {
        print('Current user check failed: $e');
      }

      try {
        final client = AppSupabaseConfig.clientOrNull();
        final result = await client!
            .from('profiles')
            .select()
            .limit(1)
            .timeout(const Duration(seconds: 10));
        print('Database OK: $result');
      } catch (e, st) {
        print('Database check failed: $e');
        print(st);
      }
    } catch (e, st) {
      print('Supabase initialization failed: $e');
      print(st);
    }
  } else {
    print('Supabase configuration missing; continuing without remote auth');
  }

  print('before runApp');
  runApp(const KoolanApp());
  print('after runApp');
}
