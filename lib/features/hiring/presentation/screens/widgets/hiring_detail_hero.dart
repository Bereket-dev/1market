part of '../hiring_detail_screen.dart';

// ── Hiring hero carousel ──────────────────────────────────────────────────────
// Renders a swipeable PageView when the post has multiple images, or a single
// image when it has only one. HiringPost currently carries one imageUrl — the
// widget is structured to grow when imageUrls is added to the model.

class _HiringHeroCarousel extends StatefulWidget {
  final String imageUrl;

  /// All image URLs (multi-image support).
  final List<String> imageUrls;

  const _HiringHeroCarousel({
    required this.imageUrl,
    required this.imageUrls,
  });

  @override
  State<_HiringHeroCarousel> createState() => _HiringHeroCarouselState();
}

class _HiringHeroCarouselState extends State<_HiringHeroCarousel> {
  int _currentPage = 0;
  late final PageController _pageController = PageController();

  /// Builds the full ordered image list: primary first, extras after,
  /// deduped and with empty strings filtered out.
  List<String> get _images {
    final all = <String>[
      if (widget.imageUrl.isNotEmpty) widget.imageUrl,
      ...widget.imageUrls.where((u) => u.isNotEmpty),
    ];
    final seen = <String>{};
    return all.where(seen.add).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final images = _images;
    final multi  = images.length > 1;

    if (images.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo(s) ───────────────────────────────────────────────
            if (!multi)
              CachedNetworkImage(
                imageUrl: images.first,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: cs.primaryContainer.withValues(alpha: 0.25),
                  child: Center(
                      child: CircularProgressIndicator(color: cs.primary)),
                ),
                errorWidget: (_, _, _) => Container(
                  color: cs.primaryContainer.withValues(alpha: 0.25),
                  child: Icon(Icons.work_outline_rounded,
                      size: 64, color: cs.primary.withValues(alpha: 0.4)),
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: cs.primaryContainer.withValues(alpha: 0.25),
                    child: Center(
                        child: CircularProgressIndicator(color: cs.primary)),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: cs.primaryContainer.withValues(alpha: 0.25),
                    child: Icon(Icons.work_outline_rounded,
                        size: 64, color: cs.primary.withValues(alpha: 0.4)),
                  ),
                ),
              ),

            // ── Dot indicators – only when multi ──────────────────────
            if (multi)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width:  active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

            // ── Left / right arrow buttons – only when multi ──────────
            if (multi && _currentPage > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => _pageController.animateToPage(
                      _currentPage - 1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),
            if (multi && _currentPage < images.length - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    onPressed: () => _pageController.animateToPage(
                      _currentPage + 1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),

            // ── Counter badge ─────────────────────────────────────────
            if (multi)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Arrow button for hiring carousel ─────────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ArrowButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}



