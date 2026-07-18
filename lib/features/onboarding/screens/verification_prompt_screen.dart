import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';

class VerificationPromptScreen extends StatelessWidget {
  const VerificationPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Verify your account with Fayda',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verified accounts build trust. You can verify now, or skip and continue using the app immediately.',
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => state.completeVerificationOnboarding(true),
                child: const Text('Verify now'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => state.completeVerificationOnboarding(false),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
