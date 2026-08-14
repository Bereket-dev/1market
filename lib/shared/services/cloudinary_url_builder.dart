/// Builds Cloudinary transformation URLs for different display contexts.
///
/// Usage pattern:
///   ```dart
///   final thumb = CloudinaryUrlBuilder.card(originalUrl);
///   ```
///
/// Dual-read strategy:
/// - If the URL already contains `/upload/` (a Cloudinary URL), a
///   transformation segment is injected just before the version/path.
/// - If it is a legacy non-Cloudinary URL (e.g. Supabase storage), the URL
///   is returned unchanged — we never break existing image URLs.
///
/// No new package dependency required — pure string manipulation.
class CloudinaryUrlBuilder {
  CloudinaryUrlBuilder._();

  // ── Transformation presets ────────────────────────────────────────────────

  /// Marketplace card / list row thumbnail.
  /// Target: 30–80 KB on a 320-dp wide slot.
  static const _kCard = 'w_320,h_240,c_fill,q_auto:low,f_auto';

  /// Compact list row (hiring posts, service tiles).
  /// Target: 20–50 KB on a ~240-dp slot.
  static const _kCompact = 'w_240,h_180,c_fill,q_auto:low,f_auto';

  /// Detail screen hero image.
  /// Target: 120–250 KB.
  static const _kHero = 'w_800,q_auto:good,f_auto';

  /// Full-screen image viewer.
  /// Target: 250–500 KB.
  static const _kFull = 'w_1280,q_auto:good,f_auto';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns a thumbnail URL sized for marketplace cards (~320×240 px).
  static String card(String url) => _transform(url, _kCard);

  /// Returns a thumbnail URL sized for compact list rows (~240×180 px).
  static String compact(String url) => _transform(url, _kCompact);

  /// Returns a URL sized for a detail screen hero image (~800 px wide).
  static String hero(String url) => _transform(url, _kHero);

  /// Returns a URL sized for a full-screen image viewer (~1280 px wide).
  static String full(String url) => _transform(url, _kFull);

  /// Low-res placeholder (blurred 20×20) for progressive loading.
  static String placeholder(String url) =>
      _transform(url, 'w_20,h_20,c_fill,q_1,e_blur:200,f_auto');

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Returns true when [url] looks like a Cloudinary delivery URL for this
  /// configured cloud name.
  static bool isCloudinaryUrl(String url) {
    if (url.isEmpty) return false;
    // Accept any res.cloudinary.com URL so we handle both configured and
    // legacy cloud names gracefully.
    return url.contains('res.cloudinary.com') && url.contains('/upload/');
  }

  /// Injects [transformation] into a Cloudinary URL.
  ///
  /// Example input:
  ///   https://res.cloudinary.com/mycloud/image/upload/v1234/folder/file.jpg
  /// Output:
  ///   https://res.cloudinary.com/mycloud/image/upload/w_320,h_240,c_fill,q_auto:low,f_auto/v1234/folder/file.jpg
  ///
  /// If the URL already contains a transformation segment (anything between
  /// `/upload/` and the next `/`), it is replaced so that card URLs don't
  /// accumulate transformation chains.
  static String _transform(String url, String transformation) {
    if (url.isEmpty) return url;
    if (!isCloudinaryUrl(url)) return url; // pass-through for non-Cloudinary

    const marker = '/upload/';
    final idx = url.indexOf(marker);
    if (idx == -1) return url;

    final afterUpload = url.substring(idx + marker.length);

    // Check if the segment after /upload/ looks like an existing transformation
    // (i.e. starts with a known Cloudinary transformation parameter like
    // w_, h_, c_, q_, f_, e_, t_ or a numeric version like v1234).
    // Strategy: if the first segment contains '=' or starts with a letter
    // followed by '_' it is an existing transformation — replace it.
    final segments = afterUpload.split('/');
    final first = segments.isNotEmpty ? segments.first : '';
    final hasExistingTransform = _looksLikeTransformation(first);

    final pathAfterTransform = hasExistingTransform
        ? segments.sublist(1).join('/')
        : afterUpload;

    final base = url.substring(0, idx + marker.length);
    return '$base$transformation/$pathAfterTransform';
  }

  /// Heuristic: does this URL segment look like a Cloudinary transformation?
  /// e.g. "w_320,h_240,c_fill" or "t_mypreset" — YES
  ///       "v1234567890"       — version, not a transformation — NO
  ///       "folder"            — path segment — NO
  static bool _looksLikeTransformation(String segment) {
    if (segment.isEmpty) return false;
    // Cloudinary transformation params follow the pattern letter_value
    // separated by commas, e.g. "w_320,h_240,c_fill,q_auto:low,f_auto"
    // Version segments start with 'v' followed by digits, e.g. "v1234567890"
    if (RegExp(r'^v\d+$').hasMatch(segment)) return false;
    // If it contains '_' and looks like param=value pairs, it's a transform
    return segment.contains('_') &&
        RegExp(r'^[a-z][a-z0-9]*_').hasMatch(segment);
  }
}
