part of '../saved_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Compare mode info banner
// ─────────────────────────────────────────────────────────────────────────────

class _CompareBanner extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  const _CompareBanner({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    final count = state.selectedCompareIds.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.s.savedCompareInfo
                  .replaceAll('{count}', '$count'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
          // Quick exit from compare mode
          GestureDetector(
            onTap: state.toggleCompareMode,
            child: Icon(Icons.close_rounded,
                size: 16, color: cs.primary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saved listing tile  – horizontal layout: image | info | actions
// ─────────────────────────────────────────────────────────────────────────────

class _SavedListingTile extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  final bool isChosen;

  const _SavedListingTile({
    required this.listing,
    required this.state,
    required this.isChosen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inCompare = state.compareModeEnabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isChosen && inCompare
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: isChosen && inCompare ? 2.5 : 1,
        ),
        color: isChosen && inCompare
            ? cs.primaryContainer.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (inCompare) {
            state.toggleCompareSelection(listing.id);
          } else {
            state.pushScreen(ListingDetailScreenRoute(listing.id));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────────────
              _Thumbnail(listing: listing, isChosen: isChosen && inCompare),

              const SizedBox(width: 12),

              // ── Info ───────────────────────────────────────────────────
              Expanded(
                child: _TileInfo(listing: listing, state: state),
              ),

              const SizedBox(width: 8),

              // ── Actions column ─────────────────────────────────────────
              _TileActions(
                listing: listing,
                state: state,
                isChosen: isChosen && inCompare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Listing listing;
  final bool isChosen;
  const _Thumbnail({required this.listing, required this.isChosen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SavedListingImage(
            imageUrl: listing.imageUrl,
            width: 90,
            height: 90,
          ),
        ),
        if (isChosen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cs.primary.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: cs.primary,
                child: Icon(Icons.check_rounded,
                    size: 16, color: cs.onPrimary),
              ),
            ),
          ),
      ],
    );
  }
}

class _TileInfo extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _TileInfo({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price
        Text(
          listing.price,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 2),

        // Title
        Text(
          listing.titleForLocale(state.locale),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // Condition + spec chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _SmallPill(
              label: listing.conditionOrStatus,
              color: cs.primaryContainer,
              textColor: cs.onPrimaryContainer,
            ),
            if (listing.spec1Label != null && listing.spec1Value != null)
              _SmallPill(
                label: listing.spec1Value!,
                color: cs.surfaceContainerHighest,
                textColor: cs.onSurfaceVariant,
                border: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            if (listing.spec2Label != null && listing.spec2Value != null)
              _SmallPill(
                label: listing.spec2Value!,
                color: cs.surfaceContainerHighest,
                textColor: cs.onSurfaceVariant,
                border: cs.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Location
        Row(
          children: [
            Icon(Icons.location_on_rounded,
                size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                listing.location.split(',')[0],
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TileActions extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  final bool isChosen;

  const _TileActions({
    required this.listing,
    required this.state,
    required this.isChosen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unsave button
        GestureDetector(
          onTap: () => state.toggleSaveListing(listing.id),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_remove_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

