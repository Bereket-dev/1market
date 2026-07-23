import 'package:flutter/material.dart';
import '../../../../core/utils/icon_for_spec.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

// ── Full card (original) ──────────────────────────────────────────────────────

/// Full-size vertical listing card. Used in grid-off (single-column) mode.
class PremiumClassifiedCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const PremiumClassifiedCard({
    super.key,
    required this.listing,
    required this.onSaveToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ─────────────────────────────────────────────────────
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImageWidget(
                    imageUrl: listing.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 120,
                    errorWidget:
                        Container(color: cs.surfaceContainerHighest),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ConditionPill(
                            status: listing.conditionOrStatus, cs: cs),
                        _SaveButton(
                            isSaved: listing.isSaved,
                            onTap: onSaveToggle,
                            cs: cs),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.price,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      if (listing.isOwnedByCurrentUser)
                        _MyAdBadge(cs: cs),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Specs row
                  _SpecsRow(listing: listing),
                  const SizedBox(height: 8),
                  Divider(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: cs.outline, size: 14),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.location.split(',')[0],
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

// ── Compact card (grid / 2-column mode) ──────────────────────────────────────

/// Compact listing card designed for 2-column grid layouts.
/// Shows the essential info without a large hero image.
class ListingCompactCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const ListingCompactCard({
    super.key,
    required this.listing,
    required this.onSaveToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ───────────────────────────────────────────────
            Stack(
              children: [
                CachedImageWidget(
                  imageUrl: listing.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 110,
                  errorWidget: Container(
                    height: 110,
                    color: cs.primaryContainer.withValues(alpha: 0.2),
                    alignment: Alignment.center,
                    child: Icon(
                      _categoryIcon(listing.category),
                      color: cs.primary,
                      size: 32,
                    ),
                  ),
                ),
                // Save overlay
                Positioned(
                  top: 6,
                  right: 6,
                  child: _SaveButton(
                      isSaved: listing.isSaved, onTap: onSaveToggle, cs: cs),
                ),
              ],
            ),

            // ── Info ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.price,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Condition pill + location on same row to save vertical space
                  Row(
                    children: [
                      _ConditionPill(status: listing.conditionOrStatus, cs: cs),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                color: cs.outline, size: 11),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                listing.location.split(',')[0],
                                style: TextStyle(
                                    fontSize: 10, color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class BrowseFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const BrowseFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.expand_more,
              size: 14,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

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

IconData _categoryIcon(String cat) => switch (cat.toUpperCase()) {
      'CARS' => Icons.directions_car_filled,
      'HOUSES' => Icons.home_rounded,
      'LAND' => Icons.landscape_rounded,
      'SKILLS' => Icons.construction_rounded,
      'OTHERS' => Icons.category_outlined,
      _ => Icons.inventory_2_outlined,
    };

// ── Saved listing image helper ────────────────────────────────────────────────

/// A simple cached image widget sized for the horizontal saved-screen tile.
class SavedListingImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const SavedListingImage({
    super.key,
    required this.imageUrl,
    this.width = 90,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CachedImageWidget(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorWidget: Container(
        width: width,
        height: height,
        color: cs.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_rounded,
            color: cs.outline, size: 24),
      ),
    );
  }
}
