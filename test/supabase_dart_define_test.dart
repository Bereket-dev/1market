import 'package:flutter_test/flutter_test.dart';

import 'package:onemarket/core/config/supabase_config.dart';

void main() {
  test('Supabase config is injected via --dart-define-from-file', () {
    expect(
      AppSupabaseConfig.isConfigured,
      isTrue,
      reason: 'Run tests with: flutter test --dart-define-from-file=.env',
    );
    expect(AppSupabaseConfig.url, startsWith('https://'));
    expect(AppSupabaseConfig.publishableKey, isNotEmpty);
  });
}
