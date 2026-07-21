import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

/// A single comparison row: a localized label + a mapper that extracts the
/// display value from a [Listing].
class _RowSpec {
  final String label;
  final String Function(Listing) mapper;
  const _RowSpec(this.label, this.mapper);
}

class CompareOverlay extends StatelessWidget {
  final List<Listing> listings;
  final VoidCallback onClose;

  const CompareOverlay(
      {super.key, required this.listings, required this.onClose});

  /// Build the row definitions using localized labels from [s].
  /// The N/A fallback is also localized via [s.compareNa].
  List<_RowSpec> _buildRows(AppStrings s) {
    final na = s.compareNa;
    return [
      _RowSpec(s.compareRowPrice,    (l) => l.price),
      _RowSpec(s.compareRowLocation, (l) => l.location.split(',')[0]),
      _RowSpec(s.compareRowStatus,   (l) => l.conditionOrStatus),
      _RowSpec(s.compareRowSpec1,    (l) => l.spec1Label != null
          ? '${l.spec1Label}: ${l.spec1Value}' : na),
      _RowSpec(s.compareRowSpec2,    (l) => l.spec2Label != null
          ? '${l.spec2Label}: ${l.spec2Value}' : na),
      _RowSpec(s.compareRowSpec3,    (l) => l.spec3Label != null
          ? '${l.spec3Label}: ${l.spec3Value}' : na),
      _RowSpec(s.compareRowSeller,   (l) => l.sellerName),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (listings.length < 2) return const SizedBox();
    final cs    = Theme.of(context).colorScheme;
    final state = KoolanAppStateScope.of(context);
    final s     = state.s;
    final rows  = _buildRows(s);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 650),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.compareTitle,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface)),
                    IconButton(
                        icon: Icon(Icons.close, color: cs.onSurface),
                        onPressed: onClose),
                  ],
                ),
                const SizedBox(height: 16),

                // Listing thumbnails + localized titles
                Row(children: [
                  const Expanded(child: SizedBox()),
                  Expanded(
                      child: _ListingHeader(
                          listing: listings[0],
                          locale: state.locale,
                          cs: cs)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _ListingHeader(
                          listing: listings[1],
                          locale: state.locale,
                          cs: cs)),
                ]),
                const SizedBox(height: 12),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),

                // Row comparisons
                Expanded(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.4)),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          Expanded(
                            child: Text(row.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: cs.primary)),
                          ),
                          Expanded(
                            child: Text(row.mapper(listings[0]),
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurface),
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(row.mapper(listings[1]),
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurface),
                                textAlign: TextAlign.center),
                          ),
                        ]),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.compareClose,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingHeader extends StatelessWidget {
  final Listing listing;
  final String locale;
  final ColorScheme cs;
  const _ListingHeader({
    required this.listing,
    required this.locale,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
            imageUrl: listing.imageUrl,
            cacheManager: KoolanImageCacheManager.instance,
            height: 70, width: 100, fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 70, width: 100, color: Colors.grey[200],
            ),
            errorWidget: (_, __, ___) => Container(
              height: 70, width: 100, color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
      ),
      const SizedBox(height: 4),
      Text(listing.titleForLocale(locale),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: cs.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]);
  }
}
