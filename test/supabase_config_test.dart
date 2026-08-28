import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onemarket/core/config/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await dotenv.load(fileName: '.env');
  });

  test('uses the deep-link callback from env when redirect URL is missing', () {
    dotenv.env.remove('SUPABASE_REDIRECT_URL');
    dotenv.env['SUPABASE_GOOGLE_CALLBACK'] =
        'io.supabase.onemarket://login-callback/';

    expect(
      AppSupabaseConfig.redirectUrl,
      'io.supabase.onemarket://login-callback/',
    );
  });
}
