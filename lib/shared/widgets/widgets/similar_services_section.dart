part of '../similar_section.dart';

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

  void _computeIfStale(OnemarketAppState state) {
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
    final state = OnemarketAppStateScope.of(context);
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

