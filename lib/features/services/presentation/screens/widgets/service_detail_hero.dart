part of '../service_detail_screen.dart';

// ── Service hero carousel ─────────────────────────────────────────────────────
// Renders a swipeable PageView carousel when the service has multiple images,
// or a single image / placeholder when it has zero or one.
// Currently Service only carries imageUrl — the widget is structured to
// accept a list so it can grow when imageUrls is added to the model.

class _ServiceHeroCarousel extends StatefulWidget {
  /// Primary cover image URL.
  final String imageUrl;

  /// All image URLs (multi-image support).
  final List<String> imageUrls;

  final String ownerId;
  final OnemarketAppState state;
  final String serviceId;

  const _ServiceHeroCarousel({
    required this.imageUrl,
    required this.imageUrls,
    required this.ownerId,
    required this.state,
    required this.serviceId,
  });

  @override
  State<_ServiceHeroCarousel> createState() => _ServiceHeroCarouselState();
}

class _ServiceHeroCarouselState extends State<_ServiceHeroCarousel> {
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

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Photo(s) ─────────────────────────────────────────────────
          if (images.isEmpty)
            _ServiceHeroPlaceholder(cs: cs)
          else if (!multi)
            CachedNetworkImage(
              imageUrl: images.first,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                child: Center(
                    child: CircularProgressIndicator(color: cs.primary)),
              ),
              errorWidget: (_, _, _) => _ServiceHeroPlaceholder(cs: cs),
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
                errorWidget: (_, _, _) => _ServiceHeroPlaceholder(cs: cs),
              ),
            ),

          // ── Gradient scrim ───────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Dot indicators – only when multi ─────────────────────────
          if (multi)
            Positioned(
              bottom: 14,
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

          // ── Left / right arrow buttons – only when multi ──────────────
          if (multi && _currentPage > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _OverlayCircleButton(
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
                child: _OverlayCircleButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: () => _pageController.animateToPage(
                    _currentPage + 1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),

          // ── Counter badge – only when multi ───────────────────────────
          if (multi)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 16,
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
    );
  }
}

// ── Service hero placeholder ──────────────────────────────────────────────────

class _ServiceHeroPlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _ServiceHeroPlaceholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      color: cs.primaryContainer.withValues(alpha: 0.25),
      child: Icon(
        Icons.work_outline_rounded,
        size: 72,
        color: cs.primary.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── Overlay circle button (back / edit on hero image) ─────────────────────────

class _OverlayCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _OverlayCircleButton(
      {required this.icon, required this.onPressed});

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
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
            ],
          ),
        ),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

