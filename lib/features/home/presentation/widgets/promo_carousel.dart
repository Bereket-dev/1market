import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/home_promo.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

// ── Hardcoded fallback slides ─────────────────────────────────────────────────
//
// Used when the DB returns no rows (offline / all slots deactivated).
// Default image URLs match the pre-DB carousel so cards never look empty when
// `home_promos.image_url` is null (seed / admin not yet set).

class _FallbackSlide {
  final String Function(AppStrings) headline;
  final String Function(AppStrings) sub;
  final PromoTheme theme;
  final String imageUrl;

  const _FallbackSlide({
    required this.headline,
    required this.sub,
    required this.theme,
    required this.imageUrl,
  });
}

/// Per-slot default images (slot index 0 → 3). Also used when a DB row has a
/// null/empty `image_url`.
const _defaultPromoImageUrls = [
  'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=600&q=80',
  'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=600&q=80',
  'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80',
  'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?auto=format&fit=crop&w=600&q=80',
];

const _fallbackSlides = [
  _FallbackSlide(
    headline: _h1,
    sub: _s1,
    theme: PromoTheme.navy,
    imageUrl:
        'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=600&q=80',
  ),
  _FallbackSlide(
    headline: _h2,
    sub: _s2,
    theme: PromoTheme.teal,
    imageUrl:
        'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=600&q=80',
  ),
  _FallbackSlide(
    headline: _h3,
    sub: _s3,
    theme: PromoTheme.purple,
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80',
  ),
  _FallbackSlide(
    headline: _h4,
    sub: _s4,
    theme: PromoTheme.red,
    imageUrl:
        'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?auto=format&fit=crop&w=600&q=80',
  ),
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
      final slides = _buildSlides(KoolanAppStateScope.of(context));
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
  List<_SlideVM> _buildSlides(KoolanAppState state) {
    final dbPromos = state.homePromos;
    if (dbPromos.isNotEmpty) {
      return [
        for (var i = 0; i < dbPromos.length; i++)
          _SlideVM(
            headline: dbPromos[i].headline,
            subtitle: dbPromos[i].subtitle,
            // Seed rows ship with null image_url; keep the old Unsplash
            // defaults so clearing app data / guest fetch still shows images.
            imageUrl: (dbPromos[i].imageUrl != null &&
                    dbPromos[i].imageUrl!.isNotEmpty)
                ? dbPromos[i].imageUrl
                : _defaultPromoImageUrls[i % _defaultPromoImageUrls.length],
            theme: dbPromos[i].theme,
          ),
      ];
    }
    // Fallback: localised hardcoded strings + default images.
    final s = state.s;
    return _fallbackSlides
        .map((f) => _SlideVM(
              headline: f.headline(s),
              subtitle: f.sub(s),
              imageUrl: f.imageUrl,
              theme: f.theme,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final slides = _buildSlides(state);

    return Column(
      children: [
        SizedBox(
          height: 170,
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
                scale: _page == index ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _PromoSlideCard(vm: slides[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slides.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _page == i ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
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

class _PromoSlideCard extends StatelessWidget {
  final _SlideVM vm;

  const _PromoSlideCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [vm.theme.accent, vm.theme.accentLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Subtle geometric overlay for depth ─────────────────────────
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // ── Remote image (if provided) — right-side fill ───────────────
            if (vm.imageUrl != null && vm.imageUrl!.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 130,
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      vm.theme.accent,
                      Colors.transparent,
                    ],
                  ).createShader(rect),
                  blendMode: BlendMode.dstOut,
                  child: CachedNetworkImage(
                    imageUrl: vm.imageUrl!,
                    cacheManager: KoolanImageCacheManager.instance,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    placeholder: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            // ── Text + badge content ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Brand badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(vm.theme.icon,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 5),
                              const Text(
                                'KOOLAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Headline
                        Text(
                          vm.headline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle
                        Text(
                          vm.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // ── Right side: network image OR icon circle ──────────────
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: vm.imageUrl != null && vm.imageUrl!.isNotEmpty
                          ? _NetworkImageCircle(url: vm.imageUrl!, theme: vm.theme)
                          : _IconCircle(theme: vm.theme),
                    ),
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

// ── Helper sub-widgets ────────────────────────────────────────────────────────

class _IconCircle extends StatelessWidget {
  final PromoTheme theme;

  const _IconCircle({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(theme.icon, color: Colors.white, size: 28),
    );
  }
}

class _NetworkImageCircle extends StatelessWidget {
  final String url;
  final PromoTheme theme;

  const _NetworkImageCircle({required this.url, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.35), width: 2),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          cacheManager: KoolanImageCacheManager.instance,
          fit: BoxFit.cover,
          placeholder: (_, __) => _IconCircle(theme: theme),
          errorWidget: (_, __, ___) => _IconCircle(theme: theme),
        ),
      ),
    );
  }
}
