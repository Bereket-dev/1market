import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onemarket/core/config/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Use the bundled asset file — .env is gitignored and not guaranteed to
    // exist in every environment.  assets/config/local.env is tracked and
    // synced from .env via `dart run tool/sync_local_env.dart`.
    await dotenv.load(fileName: 'assets/config/local.env');
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
