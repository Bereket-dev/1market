import 'package:flutter/material.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';

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

  static const _rows = [
    _RowSpec('Price', _price),
    _RowSpec('Location', _loc),
    _RowSpec('Status', _status),
    _RowSpec('Spec 1', _spec1),
    _RowSpec('Spec 2', _spec2),
    _RowSpec('Spec 3', _spec3),
    _RowSpec('Seller', _seller),
  ];

  static String _price(Listing l) => l.price;
  static String _loc(Listing l) => l.location.split(',')[0];
  static String _status(Listing l) => l.conditionOrStatus;
  static String _spec1(Listing l) =>
      l.spec1Label != null ? '${l.spec1Label}: ${l.spec1Value}' : 'N/A';
  static String _spec2(Listing l) =>
      l.spec2Label != null ? '${l.spec2Label}: ${l.spec2Value}' : 'N/A';
  static String _spec3(Listing l) =>
      l.spec3Label != null ? '${l.spec3Label}: ${l.spec3Value}' : 'N/A';
  static String _seller(Listing l) => l.sellerName;

  @override
  Widget build(BuildContext context) {
    if (listings.length < 2) return const SizedBox();
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Material(
          // Use Card-level surface so it adapts to both themes
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

                // Listing thumbnails
                Row(children: [
                  const Expanded(child: SizedBox()),
                  Expanded(
                      child: _ListingHeader(
                          listing: listings[0], cs: cs)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _ListingHeader(
                          listing: listings[1], cs: cs)),
                ]),
                const SizedBox(height: 12),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),

                // Row comparisons
                Expanded(
                  child: ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.4)),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
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
                  child: const Text('Close Comparison',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
  final ColorScheme cs;
  const _ListingHeader({required this.listing, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(listing.imageUrl,
            height: 70, width: 100, fit: BoxFit.cover),
      ),
      const SizedBox(height: 4),
      Text(listing.title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: cs.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]);
  }
}
