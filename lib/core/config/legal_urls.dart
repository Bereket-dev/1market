/// Hosted legal document URLs required for Play Store and in-app Settings.
///
/// Replace these with your live pages before submitting to Google Play.
/// Play Console rejects listings without a working Privacy Policy URL.
class LegalUrls {
  LegalUrls._();

  /// Public HTTPS privacy policy (must stay reachable for Play review).
  static const String privacyPolicy =
      'https://1market-privacy-policy.vercel.app/';

  /// Public HTTPS terms of service.
  static const String termsOfService =
      'https://1market-terms.vercel.app/';
}
