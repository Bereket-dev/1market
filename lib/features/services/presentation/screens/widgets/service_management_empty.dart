part of '../service_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — explains what a service is before any are created
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyServicesState extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  const _EmptyServicesState({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    final s = state.s;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          // Hero illustration
          CircleAvatar(
            radius: 56,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
            child: Icon(Icons.work_outline_rounded,
                size: 56, color: cs.primary),
          ),
          const SizedBox(height: 24),

          Text(
            'Set up your service profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Explanation card — onboarding copy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _OnboardingRow(
                  icon: Icons.search_rounded,
                  cs: cs,
                  text:
                      'Employers and clients search for professionals like you by skill category.',
                ),
                const SizedBox(height: 12),
                _OnboardingRow(
                  icon: Icons.toggle_on_rounded,
                  cs: cs,
                  text:
                      'Toggle your availability at any time — when you\'re available, you appear in results.',
                ),
                const SizedBox(height: 12),
                _OnboardingRow(
                  icon: Icons.handshake_outlined,
                  cs: cs,
                  text:
                      'Interested employers contact you directly through the chat to discuss the job.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: () =>
                state.pushScreen(ServiceEditScreenRoute(null)),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              s.servicesAddNew,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingRow extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final String text;
  const _OnboardingRow(
      {required this.icon, required this.cs, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

