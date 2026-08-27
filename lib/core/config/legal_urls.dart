/// Hosted legal document URLs required for Play Store and in-app Settings.
///
/// Keep these pages live — Play Console rejects listings without a working
/// Privacy Policy URL.
class LegalUrls {
  LegalUrls._();

  /// Public HTTPS privacy policy (must stay reachable for Play review).
  static const String privacyPolicy =
      'https://1market-privacy-policy.vercel.app/';

  /// Public HTTPS terms of service.
  static const String termsOfService =
      'https://1market-terms.vercel.app/';

  /// Play Console / developer contact (update before store submission).
  /// Not shown in-app; documented for listing checklist parity.
  static const String playStoreContactEmail = 'support@1market.app';
}
