import 'package:flutter/material.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _PromoSlide {
  final String headline;
  final String sub;
  final Color accent;
  final Color accentLight;
  final IconData icon;
  final String imageUrl;

  const _PromoSlide({
    required this.headline,
    required this.sub,
    required this.accent,
    required this.accentLight,
    required this.icon,
    required this.imageUrl,
  });
}

const _slides = [
  _PromoSlide(
    headline: "Jigjiga's #1\nMarketplace",
    sub: 'Buy, sell, and hire in your city — all in one place.',
    accent: Color(0xFF00288E),
    accentLight: Color(0xFF1E40AF),
    icon: Icons.storefront_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=600&q=80',
  ),
  _PromoSlide(
    headline: 'Trusted &\nVerified Sellers',
    sub: 'Every listing is reviewed. Real IDs, real people.',
    accent: Color(0xFF0F766E),
    accentLight: Color(0xFF14B8A6),
    icon: Icons.verified_user_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=600&q=80',
  ),
  _PromoSlide(
    headline: 'Post a Listing\nin 60 Seconds',
    sub: 'Cars, houses, land or skills — post for free today.',
    accent: Color(0xFF6D28D9),
    accentLight: Color(0xFF8B5CF6),
    icon: Icons.add_circle_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80',
  ),
  _PromoSlide(
    headline: 'Safe Escrow\nPayments',
    sub: 'Pay only when satisfied. Koolan protects your money.',
    accent: Color(0xFF92400E),
    accentLight: Color(0xFFF59E0B),
    icon: Icons.lock_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=600&q=80',
  ),
];

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
                  child: _PromoSlideCard(slide: slide),
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

// ── Slide card ────────────────────────────────────────────────────────────────

class _PromoSlideCard extends StatelessWidget {
  final _PromoSlide slide;
  const _PromoSlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            slide.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: slide.accent),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  slide.accent.withValues(alpha: 0.92),
                  slide.accent.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
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
                      Text(
                        slide.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slide.sub,
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
    );
  }
}
