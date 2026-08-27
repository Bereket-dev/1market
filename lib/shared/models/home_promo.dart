import 'package:flutter/material.dart';

/// A single promo card fetched from the `home_promos` Supabase table.
///
/// Slot numbers match the 4 hardcoded carousel positions so the admin can
/// control each card independently.  When the DB returns no rows the carousel
/// falls back to the existing hardcoded slides.
class HomePromo {
  final int slot;
  final String headline;
  final String subtitle;
  final String? imageUrl; // null → icon-only (same look as today)
  final PromoTheme theme;

  const HomePromo({
    required this.slot,
    required this.headline,
    required this.subtitle,
    this.imageUrl,
    required this.theme,
  });

  factory HomePromo.fromJson(Map<String, dynamic> json) {
    return HomePromo(
      slot: (json['slot'] as num).toInt(),
      headline: json['headline'] as String,
      subtitle: (json['subtitle'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      theme: PromoTheme.fromString(json['theme'] as String? ?? 'navy'),
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'headline': headline,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'theme': theme.name,
      };
}

/// The four gradient palettes that map to the `theme` DB column value.
enum PromoTheme {
  navy,
  teal,
  purple,
  red;

  static PromoTheme fromString(String value) {
    return switch (value.toLowerCase()) {
      'teal'   => PromoTheme.teal,
      'purple' => PromoTheme.purple,
      'red'    => PromoTheme.red,
      _        => PromoTheme.navy, // default / unknown → navy
    };
  }

  Color get accent => switch (this) {
        PromoTheme.navy   => const Color(0xFF0B3A6E),
        PromoTheme.teal   => const Color(0xFF0F766E),
        PromoTheme.purple => const Color(0xFF1B6CA8),
        PromoTheme.red    => const Color(0xFFB91C1C),
      };

  /// Light (right-side) gradient stop.
  Color get accentLight => switch (this) {
        PromoTheme.navy   => const Color(0xFF1B6CA8),
        PromoTheme.teal   => const Color(0xFF14B8A6),
        PromoTheme.purple => const Color(0xFF3B82C4),
        PromoTheme.red    => const Color(0xFFEF4444),
      };

  /// Default icon shown when no [HomePromo.imageUrl] is set.
  IconData get icon => switch (this) {
        PromoTheme.navy   => Icons.storefront_rounded,
        PromoTheme.teal   => Icons.verified_user_rounded,
        PromoTheme.purple => Icons.add_circle_rounded,
        PromoTheme.red    => Icons.handyman_rounded,
      };
}
