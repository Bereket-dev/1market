/// "Similar to This" section widget, reused across all three detail screens
/// (Listing, Service, HiringPost).
///
/// Caching: scores are computed once per screen-load and cached in state.
/// Recomputation is triggered only when the combined data length changes —
/// never on every widget rebuild or scroll frame.
library;

import 'package:flutter/material.dart';

import '../../core/router/routes.dart';
import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/service.dart';
import '../services/app_state.dart';
import '../services/recommendation_engine.dart';
import '../services/scorable_adapters.dart';

// ── Public entry points ───────────────────────────────────────────────────────

/// Shows similar listings to [anchor].
class SimilarListingsSection extends StatefulWidget {
  final Listing anchor;
  const SimilarListingsSection({super.key, required this.anchor});

  @override
  State<SimilarListingsSection> createState() =>
      _SimilarListingsSectionState();
}

class _SimilarListingsSectionState extends State<SimilarListingsSection> {
  static const _engine = RecommendationEngine();
  List<Listing> _similar = [];
  int _lastVersion = -1;

  void _computeIfStale(KoolanAppState state) {
    final v = state.allListings.length;
    if (v == _lastVersion) return;
    _lastVersion = v;
    _similar = _engine
        .rankSimilarTo<ScorableListing>(
          anchor: ScorableListing(widget.anchor),
          candidates:
              state.allListings.map((l) => ScorableListing(l)).toList(),
        )
        .map((s) => s.listing)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    _computeIfStale(state);

    if (_similar.isEmpty) {
      return _SimilarEmptyState();
    }

    return _SimilarShell(
      itemCount: _similar.length,
      itemBuilder: (context, i) {
        final l = _similar[i];
        return _SimilarListingCard(
          listing: l,
          onTap: () {
            state.recordItemViewed(l.id);
            state.pushScreen(ListingDetailScreenRoute(l.id));
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Shows similar services to [anchor].
class SimilarServicesSection extends StatefulWidget {
  final Service anchor;
  const SimilarServicesSection({super.key, required this.anchor});

  @override
  State<SimilarServicesSection> createState() =>
      _SimilarServicesSectionState();
}

class _SimilarServicesSectionState extends State<SimilarServicesSection> {
  static const _engine = RecommendationEngine();
  List<Service> _similar = [];
  int _lastVersion = -1;

  void _computeIfStale(KoolanAppState state) {
    final v = state.allServices.length;
    if (v == _lastVersion) return;
    _lastVersion = v;
    _similar = _engine
        .rankSimilarTo<ScorableService>(
          anchor: ScorableService(widget.anchor),
          candidates: state.allServices.map((s) {
            final reviews = state.getReviewsForService(s.id);
            final avg = reviews.isEmpty
                ? 0.0
                : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                    reviews.length;
            return ScorableService(s, reviewRating: avg);
          }).toList(),
        )
        .map((s) => s.service)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    _computeIfStale(state);

    if (_similar.isEmpty) {
      return _SimilarEmptyState();
    }

    return _SimilarShell(
      itemCount: _similar.length,
      itemBuilder: (context, i) {
        final svc = _similar[i];
        return _SimilarServiceCard(
          service: svc,
          onTap: () {
            state.recordItemViewed(svc.id);
            state.pushScreen(ServiceDetailScreenRoute(svc.id));
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Shows similar hiring posts to [anchor].
class SimilarHiringSection extends StatefulWidget {
  final HiringPost anchor;
  const SimilarHiringSection({super.key, required this.anchor});

  @override
  State<SimilarHiringSection> createState() => _SimilarHiringSectionState();
}

class _SimilarHiringSectionState extends State<SimilarHiringSection> {
  static const _engine = RecommendationEngine();
  List<HiringPost> _similar = [];
  int _lastVersion = -1;

  void _computeIfStale(KoolanAppState state) {
    final v = state.allHiringPosts.length;
    if (v == _lastVersion) return;
    _lastVersion = v;
    _similar = _engine
        .rankSimilarTo<ScorableHiringPost>(
          anchor: ScorableHiringPost(widget.anchor),
          candidates: state.allHiringPosts
              .where((p) => p.isOpen)
              .map((p) => ScorableHiringPost(p))
              .toList(),
        )
        .map((s) => s.post)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    _computeIfStale(state);

    if (_similar.isEmpty) {
      return _SimilarEmptyState();
    }

    return _SimilarShell(
      itemCount: _similar.length,
      itemBuilder: (context, i) {
        final post = _similar[i];
        return _SimilarHiringCard(
          post: post,
          onTap: () {
            state.recordItemViewed(post.id);
            state.pushScreen(HiringDetailScreenRoute(post.id));
          },
        );
      },
    );
  }
}

// ── Shared layout ─────────────────────────────────────────────────────────────

/// Header + horizontal card list shell, shared by all three similar sections.
class _SimilarShell extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const _SimilarShell({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Text(
          s.detailSimilarTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: itemBuilder,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Empty state — shown gracefully when no similar items exist yet.
class _SimilarEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            s.detailSimilarTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.detailSimilarEmpty,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Card variants ─────────────────────────────────────────────────────────────

class _SimilarListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _SimilarListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: listing.imageUrl.isNotEmpty
                  ? Image.network(
                      listing.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _IconPlaceholder(category: listing.category, cs: cs),
                    )
                  : _IconPlaceholder(category: listing.category, cs: cs),
            ),
            // Label
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.title,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      listing.price,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: cs.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;
  const _SimilarServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.construction_rounded,
                  color: cs.primary, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              service.title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Availability chip — text label, not icon only (acc. criterion 6)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: service.availability
                    ? cs.primaryContainer.withValues(alpha: 0.3)
                    : cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                service.availability
                    ? s.servicesAvailable
                    : s.servicesUnavailable,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: service.availability ? cs.primary : cs.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarHiringCard extends StatelessWidget {
  final HiringPost post;
  final VoidCallback onTap;
  const _SimilarHiringCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.work_outline, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              post.title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Status chip — text label (acc. criterion 6)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: post.isOpen
                    ? cs.primaryContainer.withValues(alpha: 0.3)
                    : cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.isOpen ? s.hiringStatusOpen : s.hiringStatusClosed,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: post.isOpen ? cs.primary : cs.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon placeholder ──────────────────────────────────────────────────────────

class _IconPlaceholder extends StatelessWidget {
  final String category;
  final ColorScheme cs;
  const _IconPlaceholder({required this.category, required this.cs});

  @override
  Widget build(BuildContext context) {
    final icon = switch (category.toUpperCase()) {
      'CARS' => Icons.directions_car_filled,
      'HOUSES' => Icons.home_rounded,
      'LAND' => Icons.landscape_rounded,
      'SKILLS' => Icons.construction_rounded,
      _ => Icons.inventory_2_outlined,
    };
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: Icon(icon, color: cs.primary, size: 28),
    );
  }
}
