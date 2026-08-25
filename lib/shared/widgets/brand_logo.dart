import 'package:flutter/material.dart';

/// Light / dark 1market brand assets from [assets/brand].
///
/// Use [iconOnly] for compact UI like the home header (just the icon mark —
/// the circle+cart+1 logo, no "1market" text lockup). The full lockup is used
/// for splash, auth, and boot screens.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.iconOnly = false,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  /// When true, renders only the icon-only crop
  /// (the circle+cart+numeral mark, no text below it).
  final bool iconOnly;

  // ── Asset paths ─────────────────────────────────────────────────────────────

  /// Full lockup asset path (icon + "1market" text) for the given [brightness].
  static String assetForBrightness(Brightness brightness) =>
      brightness == Brightness.dark
          ? 'assets/brand/1market_dark.png'
          : 'assets/brand/1market_light.png';

  /// Icon-only asset path for the given [brightness].
  static String iconAssetForBrightness(Brightness brightness) =>
      brightness == Brightness.dark
          ? 'assets/brand/1market_logo_dark.png'
          : 'assets/brand/1market_logo_light.png';

  // ── Background helpers ───────────────────────────────────────────────────────

  /// Background that matches the lockup plate so there are no seam artefacts
  /// when the logo is rendered inside a container.
  ///
  /// Light lockup: white background (matches [1market_light.png]).
  /// Dark lockup:  very dark navy background (matches [1market_dark.png]).
  static Color backgroundForBrightness(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF080D1C)   // deep navy — same as kDarkBackground
          : const Color(0xFFFFFFFF);  // pure white

  /// Background tint for the icon-only badge (the circle mark).
  ///
  /// Light icon: white background, logo ring is navy.
  /// Dark icon:  dark navy background, logo ring is white/light.
  static Color iconBackgroundForBrightness(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF0E1628)   // slightly lighter navy so ring is visible
          : const Color(0xFFFFFFFF);  // pure white

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final asset = iconOnly
        ? iconAssetForBrightness(brightness)
        : assetForBrightness(brightness);

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: '1market logo',
    );
  }
}
