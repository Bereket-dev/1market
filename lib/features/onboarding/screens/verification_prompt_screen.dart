import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';
import 'fayda_verification_screen.dart';

class VerificationPromptScreen extends StatelessWidget {
  const VerificationPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
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
                s.verifyTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.verifyBody,
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Navigate to the full Fayda verification UI shell.
                    // When it completes (verified or skipped), delegate to
                    // completeVerificationOnboarding which transitions to ready.
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => KoolanAppStateScope(
                          notifier: state,
                          child: FaydaVerificationScreen(
                            onComplete: state.completeVerificationOnboarding,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text(s.verifyNow),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => state.completeVerificationOnboarding(false),
                  child: Text(s.verifySkip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
