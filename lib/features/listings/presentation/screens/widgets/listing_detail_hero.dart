part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Hero image  – single image OR swipeable PageView carousel when multiple
// images exist.  Dot indicators are shown only when count > 1.
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatefulWidget {
  final Listing listing;
  final KoolanAppState state;
  const _HeroImage({required this.listing, required this.state});

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage> {
  int _currentPage = 0;
  late final PageController _pageController = PageController();

  /// Builds the full ordered image list: primary first, extras after,
  /// deduped and with empty strings filtered out.
  List<String> get _images {
    final all = <String>[
      if (widget.listing.imageUrl.isNotEmpty) widget.listing.imageUrl,
      ...widget.listing.imageUrls.where((u) => u.isNotEmpty),
    ];
    // Deduplicate while preserving order.
    final seen = <String>{};
    return all.where(seen.add).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final listing = widget.listing;
    final state   = widget.state;
    final images  = _images;
    final multi   = images.length > 1;

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Photo(s) ───────────────────────────────────────────────────
          if (images.isEmpty)
            ListingPlaceholder(
              category: listing.category,
              width: double.infinity,
              height: 280,
            )
          else if (!multi)
            // Single image — no PageView overhead
            CachedNetworkImage(
              imageUrl: images.first,
              cacheManager: KoolanImageCacheManager.instance,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(color: cs.primary),
                ),
              ),
              errorWidget: (_, _, _) => ListingPlaceholder(
                category: listing.category,
                width: double.infinity,
                height: 280,
              ),
            )
          else
            // Multiple images — swipeable carousel
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: images[i],
                cacheManager: KoolanImageCacheManager.instance,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  ),
                ),
                errorWidget: (_, _, _) => ListingPlaceholder(
                  category: listing.category,
                  width: double.infinity,
                  height: 280,
                ),
              ),
            ),

          // ── Gradient scrim so top buttons are always legible ───────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Back / Share / Save row ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverlayCircleButton(
                  icon: Icons.arrow_back,
                  onPressed: () => state.popScreen(),
                ),
                Row(
                  children: [
                    // Edit button — only for the listing owner
                    if (listing.isOwnedByCurrentUser) ...[
                      _OverlayCircleButton(
                        icon: Icons.edit_outlined,
                        onPressed: () => state
                            .pushScreen(EditListingScreenRoute(listing.id)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _OverlayCircleButton(
                      icon: Icons.share_outlined,
                      onPressed: () {
                        final box = context.findRenderObject() as RenderBox?;
                        ShareService.shareListing(
                          listing,
                          state.s,
                          sharePositionOrigin:
                              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _SavePill(listing: listing, state: state),
                  ],
                ),
              ],
            ),
          ),

          // ── Condition pill – bottom-left corner ────────────────────────
          Positioned(
            left: 16,
            bottom: 16,
            child: _ConditionPill(label: listing.conditionOrStatus),
          ),

          // ── Dot indicators – bottom-center, only when multi-image ──────
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

          // ── Left / right arrow buttons – only when multi-image ─────────
          if (multi && _currentPage > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _OverlayCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => _goTo(_currentPage - 1),
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
                  onPressed: () => _goTo(_currentPage + 1),
                ),
              ),
            ),

          // ── Counter badge – top-right, below the back/share/save row ───
          if (multi)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
