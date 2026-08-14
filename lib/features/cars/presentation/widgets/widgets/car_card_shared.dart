part of '../car_card.dart';

// ── Shared small widgets ──────────────────────────────────────────────────────

class _ConditionPill extends StatelessWidget {
  final String status;
  final ColorScheme cs;
  const _ConditionPill({required this.status, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _SaveButton(
      {required this.isSaved, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    // Use fully opaque backgrounds so the label is always legible
    // regardless of what image or colour sits behind the button.
    final bgColor   = isSaved ? const Color(0xFFE53935) : cs.surface;
    final fgColor   = isSaved ? Colors.white            : cs.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: fgColor,
              size: 15,
              semanticLabel: isSaved ? 'Remove from saved' : 'Save listing',
            ),
            const SizedBox(width: 4),
            Text(
              isSaved ? s.navSaved : s.navSave,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyAdBadge extends StatelessWidget {
  final ColorScheme cs;
  const _MyAdBadge({required this.cs});

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        s.catAll, // reuse "All" → falls back nicely; TODO: add catMyAd string
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _SpecsRow extends StatelessWidget {
  final Listing listing;
  const _SpecsRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final specs = <Widget>[];
    void add(String? label, String? value) {
      if (label != null && value != null && specs.length < 3) {
        if (specs.isNotEmpty) specs.add(const SizedBox(width: 12));
        specs.add(_SpecIconLabel(
            label: value, icon: iconForSpec(label), cs: cs));
      }
    }

    add(listing.spec1Label, listing.spec1Value);
    add(listing.spec2Label, listing.spec2Value);
    add(listing.spec3Label, listing.spec3Value);
    if (specs.isEmpty) return const SizedBox.shrink();
    return Row(children: specs);
  }
}

class _SpecIconLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;
  const _SpecIconLabel(
      {required this.label, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 14),
        const SizedBox(width: 3),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────


// ── Saved listing image helper ────────────────────────────────────────────────

/// A simple cached image widget sized for the horizontal saved-screen tile.
class SavedListingImage extends StatelessWidget {
  final String imageUrl;
  final String category;
  final double width;
  final double height;

  const SavedListingImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.width = 90,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      delivery: CachedImageDelivery.compact,
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorWidget: ListingPlaceholder(
        category: category,
        width: width,
        height: height,
      ),
    );
  }
}
