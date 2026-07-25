part of '../home_screen.dart';

// ── Data model ────────────────────────────────────────────────────────────────

enum _RecType { listing, service, hiring }

class _RecItem {
  final String id;
  final _RecType type;
  final String title;
  final String category;
  final String? imageUrl;
  final String? price;

  const _RecItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    this.imageUrl,
    this.price,
  });

  factory _RecItem.listing(Listing l) => _RecItem(
        id: l.id,
        type: _RecType.listing,
        title: l.title,
        category: l.category,
        imageUrl: l.imageUrl,
        price: l.price,
      );

  factory _RecItem.service(Service s) => _RecItem(
        id: s.id,
        type: _RecType.service,
        title: s.title,
        category: s.category,
        imageUrl: null,
        price: s.priceRange,
      );

  factory _RecItem.hiring(HiringPost p) => _RecItem(
        id: p.id,
        type: _RecType.hiring,
        title: p.title,
        category: p.category,
        imageUrl: null,
        price: p.priceRange,
      );
}
