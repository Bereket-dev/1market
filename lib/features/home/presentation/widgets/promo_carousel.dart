import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/home_promo.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

// ── Hardcoded fallback slides ─────────────────────────────────────────────────
//
// Used when the DB returns no rows (offline / all slots deactivated).
// Theme-coloured cards only — no stock-photo URLs in the client. Admins set
// real `image_url` values via the home_promos table (Cloudinary / Storage).

class _FallbackSlide {
  final String Function(AppStrings) headline;
  final String Function(AppStrings) sub;
  final PromoTheme theme;

  const _FallbackSlide({
    required this.headline,
    required this.sub,
    required this.theme,
  });
}

const _fallbackSlides = [
  _FallbackSlide(headline: _h1, sub: _s1, theme: PromoTheme.navy),
  _FallbackSlide(headline: _h2, sub: _s2, theme: PromoTheme.teal),
  _FallbackSlide(headline: _h3, sub: _s3, theme: PromoTheme.purple), // gold family
  _FallbackSlide(headline: _h4, sub: _s4, theme: PromoTheme.red),
];

// Top-level const function references required for const list items.
String _h1(AppStrings s) => s.promo1Headline;
String _s1(AppStrings s) => s.promo1Sub;
String _h2(AppStrings s) => s.promo2Headline;
String _s2(AppStrings s) => s.promo2Sub;
String _h3(AppStrings s) => s.promo3Headline;
String _s3(AppStrings s) => s.promo3Sub;
String _h4(AppStrings s) => s.promo4Headline;
String _s4(AppStrings s) => s.promo4Sub;

// ── Slide view-model ──────────────────────────────────────────────────────────

/// Normalised view-model consumed by [_PromoSlideCard].
class _SlideVM {
  final String headline;
  final String subtitle;
  final String? imageUrl;
  final PromoTheme theme;

  const _SlideVM({
    required this.headline,
    required this.subtitle,
    this.imageUrl,
    required this.theme,
  });
}

// ── Carousel ──────────────────────────────────────────────────────────────────

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _ctrl = PageController(viewportFraction: 0.88);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final slides = _buildSlides(OnemarketAppStateScope.of(context));
      final next = (_page + 1) % slides.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Builds the view-model list.  Prefers DB promos; falls back to hardcoded.
  List<_SlideVM> _buildSlides(OnemarketAppState state) {
    final dbPromos = state.homePromos;
    if (dbPromos.isNotEmpty) {
      return [
        for (final promo in dbPromos)
          _SlideVM(
            headline: promo.headline,
            subtitle: promo.subtitle,
            // Only use admin-provided HTTPS URLs — never invent stock photos.
            imageUrl: (promo.imageUrl != null && promo.imageUrl!.isNotEmpty)
                ? promo.imageUrl
                : null,
            theme: promo.theme,
          ),
      ];
    }
    // Fallback: localised hardcoded strings + theme fill (no remote images).
    final s = state.s;
    return _fallbackSlides
        .map((f) => _SlideVM(
              headline: f.headline(s),
              subtitle: f.sub(s),
              theme: f.theme,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final slides = _buildSlides(state);

    return Column(
      children: [
        SizedBox(
          height: 188,
          child: PageView.builder(
            // Rebuild pages when slide content changes (e.g. DB promos arrive
            // after the hardcoded fallback was first painted).
            key: ValueKey(
              slides.map((s) => '${s.headline}|${s.imageUrl}').join(';'),
            ),
            controller: _ctrl,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              return AnimatedScale(
                scale: _page == index ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _PromoSlideCard(vm: slides[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slides.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _page == i ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

// ── Slide card ────────────────────────────────────────────────────────────────
//
// Full-bleed photo background + soft left scrim so the message stays readable
// while most of the image remains visible on the right.

class _PromoSlideCard extends StatelessWidget {
  final _SlideVM vm;

  const _PromoSlideCard({required this.vm});

  bool get _hasImage => vm.imageUrl != null && vm.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: vm.theme.accent.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Solid theme fill behind image (also used when image fails).
            ColoredBox(color: vm.theme.accent),

            // Full-bleed background photo.
            if (_hasImage)
              CachedNetworkImage(
                imageUrl: vm.imageUrl!,
                cacheManager: OnemarketImageCacheManager.instance,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (_, __) => ColoredBox(color: vm.theme.accentLight),
                errorWidget: (_, __, ___) => ColoredBox(color: vm.theme.accent),
              ),

            // Left→right message scrim: strong enough for text, light enough
            // that the photo reads clearly on the right half.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.42, 0.72, 1.0],
                  colors: [
                    vm.theme.accent.withValues(alpha: 0.88),
                    vm.theme.accent.withValues(alpha: 0.55),
                    vm.theme.accent.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Soft bottom edge so subtitle stays legible on busy photos.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0x66000000),
                  ],
                ),
              ),
            ),

            // Message content — left-weighted over the scrim.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 88, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(vm.theme.icon, color: Colors.white, size: 12),
                        const SizedBox(width: 5),
                        const Text(
                          '1MARKET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vm.headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.4,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 10,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vm.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      height: 1.35,
                      shadows: const [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
