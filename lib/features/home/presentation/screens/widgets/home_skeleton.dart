part of '../home_screen.dart';

// ── Skeleton shimmer card ─────────────────────────────────────────────────────
//
// Used in the Recommended and Recently-Added sections while [isLoadingData]
// is true and the lists are empty. Pulses between surfaceContainerHighest and
// surfaceContainerHigh to suggest content is on its way.

class _SkeletonCard extends StatefulWidget {
  final double width;
  final double height;
  const _SkeletonCard({required this.width, required this.height});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ── Recommended for You section ───────────────────────────────────────────────
//
// Caching strategy: recommendations are computed once when the widget first
// builds and cached in [_recommendations]. They are recomputed only when
// [_dataVersion] changes — detected by tracking the combined length of
// allListings + allServices + allHiringPosts at last compute time.
// This prevents re-scoring on every widget rebuild / scroll frame.

