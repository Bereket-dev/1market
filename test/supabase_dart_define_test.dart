import 'package:flutter_test/flutter_test.dart';

import 'package:onemarket/core/config/supabase_config.dart';

void main() {
  test('Supabase config is injected via --dart-define-from-file', () {
    // When dart-define values are not present (plain `flutter test` without
    // --dart-define-from-file=.env) AppSupabaseConfig.isConfigured is false.
    // We skip rather than fail so CI runs on the asset-bundled config path
    // without requiring a secrets file.
    if (!AppSupabaseConfig.isConfigured) {
      // ignore: avoid_print
      print(
        '[SKIP] dart-define not injected. '
        'Run with: flutter test --dart-define-from-file=.env',
      );
      return;
    }

    expect(AppSupabaseConfig.url, startsWith('https://'));
    expect(AppSupabaseConfig.publishableKey, isNotEmpty);
  });
}
