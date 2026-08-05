import 'package:flutter/material.dart';

import '../../../../shared/models/app_strings.dart';
import '../../../../shared/services/app_state.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _PromoSlideData {
  final String Function(AppStrings) headline;
  final String Function(AppStrings) sub;
  final Color accent;
  final Color accentLight;
  final IconData icon;

  const _PromoSlideData({
    required this.headline,
    required this.sub,
    required this.accent,
    required this.accentLight,
    required this.icon,
  });
}

const _slides = [
  _PromoSlideData(
    headline: _promo1Headline,
    sub: _promo1Sub,
    accent: Color(0xFF00288E),
    accentLight: Color(0xFF1E40AF),
    icon: Icons.storefront_rounded,
  ),
  _PromoSlideData(
    headline: _promo2Headline,
    sub: _promo2Sub,
    accent: Color(0xFF0F766E),
    accentLight: Color(0xFF14B8A6),
    icon: Icons.verified_user_rounded,
  ),
  _PromoSlideData(
    headline: _promo3Headline,
    sub: _promo3Sub,
    accent: Color(0xFF6D28D9),
    accentLight: Color(0xFF8B5CF6),
    icon: Icons.add_circle_rounded,
  ),
  _PromoSlideData(
    headline: _promo4Headline,
    sub: _promo4Sub,
    accent: Color(0xFFB91C1C),
    accentLight: Color(0xFFEF4444),
    icon: Icons.handyman_rounded,
  ),
];

// Top-level getters used as const function references.
String _promo1Headline(AppStrings s) => s.promo1Headline;
String _promo1Sub(AppStrings s) => s.promo1Sub;
String _promo2Headline(AppStrings s) => s.promo2Headline;
String _promo2Sub(AppStrings s) => s.promo2Sub;
String _promo3Headline(AppStrings s) => s.promo3Headline;
String _promo3Sub(AppStrings s) => s.promo3Sub;
String _promo4Headline(AppStrings s) => s.promo4Headline;
String _promo4Sub(AppStrings s) => s.promo4Sub;

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
      final next = (_page + 1) % _slides.length;
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

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return AnimatedScale(
                scale: _page == index ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _PromoSlideCard(slide: slide, s: s),
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
            children: List.generate(_slides.length, (i) {
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

// ── Slide card (gradient + icon only; no network images) ─────────────────────

class _PromoSlideCard extends StatelessWidget {
  final _PromoSlideData slide;
  final AppStrings s;

  const _PromoSlideCard({required this.slide, required this.s});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [slide.accent, slide.accentLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle geometric overlay for depth
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
            // Content
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
                              Icon(slide.icon, color: Colors.white, size: 13),
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
                          slide.headline(s),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Sub-headline
                        Text(
                          slide.sub(s),
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
                  // Right-side icon circle
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2),
                        ),
                        child: Icon(slide.icon, color: Colors.white, size: 28),
                      ),
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
