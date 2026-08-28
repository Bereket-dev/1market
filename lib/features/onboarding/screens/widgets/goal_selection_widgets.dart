part of '../goal_selection_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data and widgets for GoalSelectionScreen
// ─────────────────────────────────────────────────────────────────────────────

// ── Goal option data class ────────────────────────────────────────────────────

/// Immutable descriptor for one goal card.
class _GoalOption {
  final IconData icon;
  final Color color;
  final String Function(dynamic s) label;
  final String Function(dynamic s) description;

  /// Stable key passed to [OnemarketAppState.completeGoalSelection].
  /// Must be one of: 'CARS', 'HOUSES', 'LAND', 'SKILLS', 'OTHERS'.
  final String key;

  const _GoalOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.key,
  });
}

// ── Options builder ───────────────────────────────────────────────────────────

List<_GoalOption> _buildGoalOptions(dynamic s) => [
      _GoalOption(
        icon: Icons.storefront_rounded,
        color: const Color(0xFF6366F1),
        label: (_) => s.goalPostListing,
        description: (_) => _goalDesc('post', s),
        key: 'OTHERS',
      ),
      _GoalOption(
        icon: Icons.engineering_rounded,
        color: const Color(0xFF059669),
        label: (_) => s.goalHireSkilled,
        description: (_) => _goalDesc('hire', s),
        key: 'SKILLS',
      ),
      _GoalOption(
        icon: Icons.work_outline_rounded,
        color: const Color(0xFFF59E0B),
        label: (_) => s.goalFindJob,
        description: (_) => _goalDesc('job', s),
        key: 'SKILLS',
      ),
      _GoalOption(
        icon: Icons.directions_car_rounded,
        color: const Color(0xFF3B82F6),
        label: (_) => s.goalFindCar,
        description: (_) => _goalDesc('car', s),
        key: 'CARS',
      ),
      _GoalOption(
        icon: Icons.home_rounded,
        color: const Color(0xFFEC4899),
        label: (_) => s.goalRentHome,
        description: (_) => _goalDesc('home', s),
        key: 'HOUSES',
      ),
      _GoalOption(
        icon: Icons.landscape_rounded,
        color: const Color(0xFF10B981),
        label: (_) => s.goalBuyLand,
        description: (_) => _goalDesc('land', s),
        key: 'LAND',
      ),
    ];

// ── Localised short descriptions ──────────────────────────────────────────────

String _goalDesc(String key, dynamic s) {
  final locale = s.locale as String;
  return switch (key) {
    'post' => switch (locale) {
        'am' => 'መኪና፣ ቤት ወይም ብቃቶችን ይሸጡ',
        'so' => 'Iib gaari, guri ama xirfado',
        _    => 'Sell cars, homes or skills',
      },
    'hire' => switch (locale) {
        'am' => 'ጥሩ ሰራተኛ ያግኙ',
        'so' => 'Hel shaqaale xirfadleh',
        _    => 'Find a trusted professional',
      },
    'job' => switch (locale) {
        'am' => 'ሙያዎን ተዋቅሮ ሥራ ያግኙ',
        'so' => 'Raadi shaqo ku haboon xirfadaada',
        _    => 'Discover jobs that fit your skills',
      },
    'car' => switch (locale) {
        'am' => 'ቀጥታ ከሻጮች መኪናዎችን ያሰሳሉ',
        'so' => 'Raadi gaadhiga aad raadinayso',
        _    => 'Browse cars directly from sellers',
      },
    'home' => switch (locale) {
        'am' => 'ለኪራይ ቤቶችን ያሰሳሉ',
        'so' => 'Hel guriga kiraynta ah',
        _    => 'Find homes & apartments for rent',
      },
    'land' => switch (locale) {
        'am' => 'ሽያጭ ቦታዎችን ይፈልጉ',
        'so' => 'Raadi dhulka iibka ah',
        _    => 'Explore plots & land for sale',
      },
    _ => '',
  };
}

// ── Goal card widget ──────────────────────────────────────────────────────────

/// Animated card for one goal option in the 2-column grid.
class _GoalCard extends StatelessWidget {
  final _GoalOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state     = OnemarketAppStateScope.of(context);
    final s         = state.s;
    final cs        = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label     = option.label(s);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? option.color
                : cs.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color
                    : option.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? Colors.white : option.color,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? option.color : cs.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option.description(s),
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
