part of '../saved_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Floating compare action bar
// ─────────────────────────────────────────────────────────────────────────────

class _CompareActionBar extends StatelessWidget {
  final OnemarketAppState state;
  final ColorScheme cs;
  final VoidCallback onCompare;

  const _CompareActionBar({
    required this.state,
    required this.cs,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final count   = state.selectedCompareIds.length;
    final ready   = count == 2;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        color: cs.inverseSurface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Selection indicators
              Row(
                children: List.generate(
                  2,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: i < count
                            ? cs.primary
                            : cs.onInverseSurface.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        i < count ? Icons.check_rounded : Icons.add_rounded,
                        size: 16,
                        color: i < count
                            ? cs.onPrimary
                            : cs.onInverseSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.s.savedSelectedCount
                          .replaceAll('{count}', '$count'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.onInverseSurface,
                      ),
                    ),
                    Text(
                      ready
                          ? state.s.savedReadyAnalyse
                          : state.s.savedChooseOne,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            cs.onInverseSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),

              // Compare button
              FilledButton.icon(
                onPressed: ready ? onCompare : null,
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: Text(
                  state.s.savedCompareButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ready ? cs.primary : null,
                  foregroundColor: ready ? cs.onPrimary : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final OnemarketAppState state;
  final ColorScheme cs;
  const _EmptyState({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: cs.surfaceContainerHighest,
                child: Icon(
                  Icons.bookmark_border_rounded,
                  size: 52,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.s.savedEmpty,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.s.savedEmptySubAlt,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => state.pushScreen(HomeScreenRoute()),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(state.s.savedBrowse),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  final ColorScheme cs;
  const _FilterEmptyState({required this.cs});

  @override
  Widget build(BuildContext context) {
    final s = OnemarketAppStateScope.of(context).s;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_rounded,
                size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              s.savedFilterEmpty,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pill chip  (used in tile info)
// ─────────────────────────────────────────────────────────────────────────────

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color? border;

  const _SmallPill({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
