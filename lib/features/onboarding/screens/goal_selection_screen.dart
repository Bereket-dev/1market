import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';

/// Each goal option — icon, color, and localised label.
class _GoalOption {
  final IconData icon;
  final Color color;
  final String Function(dynamic s) label;
  final String Function(dynamic s) description;

  const _GoalOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
  });
}

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? _selectedGoal;
  bool _isSaving = false;

  // ── Goal options ────────────────────────────────────────────────────────────

  List<_GoalOption> _buildOptions(dynamic s) => [
        _GoalOption(
          icon: Icons.storefront_rounded,
          color: const Color(0xFF6366F1), // indigo
          label: (_) => s.goalPostListing,
          description: (_) => _descPostListing(s),
        ),
        _GoalOption(
          icon: Icons.engineering_rounded,
          color: const Color(0xFF059669), // emerald
          label: (_) => s.goalHireSkilled,
          description: (_) => _descHireSkilled(s),
        ),
        _GoalOption(
          icon: Icons.work_outline_rounded,
          color: const Color(0xFFF59E0B), // amber
          label: (_) => s.goalFindJob,
          description: (_) => _descFindJob(s),
        ),
        _GoalOption(
          icon: Icons.directions_car_rounded,
          color: const Color(0xFF3B82F6), // blue
          label: (_) => s.goalFindCar,
          description: (_) => _descFindCar(s),
        ),
        _GoalOption(
          icon: Icons.home_rounded,
          color: const Color(0xFFEC4899), // pink
          label: (_) => s.goalRentHome,
          description: (_) => _descRentHome(s),
        ),
        _GoalOption(
          icon: Icons.landscape_rounded,
          color: const Color(0xFF10B981), // green
          label: (_) => s.goalBuyLand,
          description: (_) => _descBuyLand(s),
        ),
      ];

  // Short descriptions per goal (English / Amharic / Somali via AppStrings helper).
  String _descPostListing(dynamic s) {
    switch (s.locale) {
      case 'am':
        return 'መኪና፣ ቤት ወይም ብቃቶችን ይሸጡ';
      case 'so':
        return 'Iib gaari, guri ama xirfado';
      default:
        return 'Sell cars, homes or skills';
    }
  }

  String _descHireSkilled(dynamic s) {
    switch (s.locale) {
      case 'am':
        return 'ጥሩ ሰራተኛ ያግኙ';
      case 'so':
        return 'Hel shaqaale xirfadleh';
      default:
        return 'Find a trusted professional';
    }
  }

  String _descFindJob(dynamic s) {
    switch (s.locale) {
      case 'am':
        return 'ሙያዎን ተዋቅሮ ሥራ ያግኙ';
      case 'so':
        return 'Raadi shaqo ku haboon xirfadaada';
      default:
        return 'Discover jobs that fit your skills';
    }
  }

  String _descFindCar(dynamic s) {
    switch (s.locale) {
      case 'am':
        return 'ቀጥታ ከሻጮች መኪናዎችን ያሰሳሉ';
      case 'so':
        return 'Raadi gaadhiga aad raadinayso';
      default:
        return 'Browse cars directly from sellers';
    }
  }

  String _descRentHome(dynamic s) {
    switch (s.locale) {
      case 'am':
        return 'ለኪራይ ቤቶችን ያሰሳሉ';
      case 'so':
        return 'Hel guriga kiraynta ah';
      default:
        return 'Find homes & apartments for rent';
    }
  }

  String _descBuyLand(dynamic s) {
    switch (s.locale) {
      case 'am':
        return 'ሽያጭ ቦታዎችን ይፈልጉ';
      case 'so':
        return 'Raadi dhulka iibka ah';
      default:
        return 'Explore plots & land for sale';
    }
  }

  // ── Save and proceed ────────────────────────────────────────────────────────

  Future<void> _proceed(KoolanAppState state) async {
    if (_selectedGoal == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await state.completeGoalSelection(_selectedGoal!);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final options = _buildOptions(s);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Headline ───────────────────────────────────────────────────
              Text(
                s.goalTitle,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.goalSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // ── Goal grid ─────────────────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.05,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    final label = opt.label(s);
                    final isSelected = _selectedGoal == label;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedGoal = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? opt.color.withValues(alpha: 0.12)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? opt.color
                                : cs.outlineVariant.withValues(alpha: 0.4),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: opt.color.withValues(alpha: 0.18),
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
                                    ? opt.color
                                    : opt.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                opt.icon,
                                color: isSelected
                                    ? Colors.white
                                    : opt.color,
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            // Goal label
                            Text(
                              label,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? opt.color
                                    : cs.onSurface,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Short description
                            Text(
                              opt.description(s),
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
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── CTA ────────────────────────────────────────────────────────
              FilledButton(
                onPressed:
                    (_selectedGoal == null || _isSaving) ? null : () => _proceed(state),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : Text(
                        s.goalContinue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
