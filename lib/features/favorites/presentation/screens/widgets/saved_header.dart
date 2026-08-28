part of '../saved_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final OnemarketAppState state;
  final ColorScheme cs;
  final bool compareModeEnabled;

  const _Header({
    required this.state,
    required this.cs,
    required this.compareModeEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.s.savedTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: cs.primary,
              ),
            ),
          ),
          // Compare button with icon + label so it's self-explanatory
          InkWell(
            onTap: state.toggleCompareMode,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: compareModeEnabled
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: compareModeEnabled
                      ? cs.primary.withValues(alpha: 0.5)
                      : cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.compare_arrows_rounded,
                    size: 18,
                    color:
                        compareModeEnabled ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.s.savedCompare,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: compareModeEnabled
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? active;
  final ValueChanged<String?> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.active,
    required this.onSelect,
  });

  static IconData _icon(String cat) => switch (cat.toUpperCase()) {
        'CARS'   => Icons.directions_car_rounded,
        'HOUSES' => Icons.home_rounded,
        'LAND'   => Icons.landscape_rounded,
        'SKILLS' => Icons.construction_rounded,
        'OTHERS' => Icons.category_outlined,
        _        => Icons.inventory_2_outlined,
      };

  String _label(String cat, AppStrings s) => switch (cat.toUpperCase()) {
        'CARS'   => s.savedCatCars,
        'HOUSES' => s.savedCatHouses,
        'LAND'   => s.savedCatLand,
        'SKILLS' => s.savedCatSkills,
        'OTHERS' => s.savedCatOthers,
        _        => cat,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = OnemarketAppStateScope.of(context).s;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _Chip(
            label: s.savedCatAll,
            icon: Icons.apps_rounded,
            selected: active == null,
            cs: cs,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...categories.expand((cat) => [
                _Chip(
                  label: _label(cat, s),
                  icon: _icon(cat),
                  selected: active == cat,
                  cs: cs,
                  onTap: () => onSelect(active == cat ? null : cat),
                ),
                const SizedBox(width: 8),
              ]),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

