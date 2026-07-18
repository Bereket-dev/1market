import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? _selectedGoal;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    final goals = [
      s.goalPostListing,
      s.goalHireSkilled,
      s.goalFindJob,
      s.goalFindCar,
      s.goalRentHome,
      s.goalBuyLand,
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                s.goalTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.goalSubtitle,
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: goals.map((goal) {
                    final isSelected = _selectedGoal == goal;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGoal = goal),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.4),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward,
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              FilledButton(
                onPressed: _selectedGoal == null
                    ? null
                    : () {
                        state.completeGoalSelection(_selectedGoal!);
                      },
                child: Text(s.goalContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
