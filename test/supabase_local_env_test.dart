import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koolan/core/config/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: 'assets/config/local.env');
  });

  test('Supabase config loads from bundled assets/config/local.env', () {
    expect(AppSupabaseConfig.isConfigured, isTrue);
    expect(AppSupabaseConfig.url, startsWith('https://'));
    expect(AppSupabaseConfig.publishableKey, isNotEmpty);
  });
}
