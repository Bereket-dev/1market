import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';

class _RowSpec {
  final String label;
  final String Function(Listing) mapper;
  const _RowSpec(this.label, this.mapper);
}

/// Full-screen overlay that displays a side-by-side listing comparison table.
class CompareOverlay extends StatelessWidget {
  final List<Listing> listings;
  final VoidCallback onClose;

  const CompareOverlay({
    super.key,
    required this.listings,
    required this.onClose,
  });

  static const _rows = [
    _RowSpec('Price', _price),
    _RowSpec('Location', _location),
    _RowSpec('Status', _status),
    _RowSpec('Spec 1', _spec1),
    _RowSpec('Spec 2', _spec2),
    _RowSpec('Spec 3', _spec3),
    _RowSpec('Seller', _seller),
  ];

  static String _price(Listing l) => l.price;
  static String _location(Listing l) => l.location.split(',')[0];
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
    final s = KoolanAppStateScope.of(context).s;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Material(
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
                    Text(
                      s.compareTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close), onPressed: onClose),
                  ],
                ),
                const SizedBox(height: 16),

                // Listing headers
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(child: _ListingHeader(listing: listings[0])),
                    const SizedBox(width: 8),
                    Expanded(child: _ListingHeader(listing: listings[1])),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                // Comparison rows
                Expanded(
                  child: ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Color(0xFFF1F3F9)),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.mapper(listings[0]),
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                row.mapper(listings[1]),
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Close Comparison',
                    style: TextStyle(color: Colors.white),
                  ),
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
  const _ListingHeader({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            listing.imageUrl,
            height: 70,
            width: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          listing.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
