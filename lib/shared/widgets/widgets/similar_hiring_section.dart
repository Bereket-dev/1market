part of '../similar_section.dart';

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

  void _computeIfStale(OnemarketAppState state) {
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
    final state = OnemarketAppStateScope.of(context);
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

