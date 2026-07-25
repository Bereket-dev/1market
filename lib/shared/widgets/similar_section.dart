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
part 'widgets/similar_shared_widgets.dart';
part 'widgets/similar_services_section.dart';
part 'widgets/similar_hiring_section.dart';

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
