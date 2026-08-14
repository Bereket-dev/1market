part of '../app.dart';

// ── Onboarding gate ───────────────────────────────────────────────────────────

class _RootGate extends StatelessWidget {
  final KoolanAppState appState;

  const _RootGate({required this.appState});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('[RootGate] build — phase: ${appState.onboardingPhase}');
    switch (appState.onboardingPhase) {
      case OnboardingPhase.initializing:
        return _InitializingScreen(
          error: appState.initError,
          onRetry: appState.retryInitialization,
        );
      case OnboardingPhase.auth:
        return const AuthScreen(fromOnboarding: true);
      case OnboardingPhase.language:
        return const LanguageScreen();
      case OnboardingPhase.profileSetup:
        return const ProfileSetupScreen();
      case OnboardingPhase.location:
        return const LocationPermissionScreen();
      case OnboardingPhase.goal:
        return const GoalSelectionScreen();
      case OnboardingPhase.ready:
        return const _AppShell();
    }
  }
}

class _InitializingScreen extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const _InitializingScreen({this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('[InitializingScreen] build');
    final cs = Theme.of(context).colorScheme;
    final appState = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
        .notifier!;
    final s = appState.s;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  s.initLoading,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ] else ...[
                Icon(Icons.error_outline, color: cs.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  s.errorCantConnect,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: Text(s.initRetry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when Firebase/Supabase bootstrap fails before [KoolanAppState] exists.
class _BootstrapFailureScreen extends StatelessWidget {
  const _BootstrapFailureScreen({
    required this.retrying,
    required this.onRetry,
  });

  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Locale prefs may exist but AppStrings needs a locale code; default en.
    final s = AppStrings('en');
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, color: cs.error, size: 48),
              const SizedBox(height: 16),
              Text(
                s.errorCantConnect,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                s.errorCantConnectHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (retrying)
                const CircularProgressIndicator()
              else
                FilledButton(onPressed: onRetry, child: Text(s.initRetry)),
            ],
          ),
        ),
      ),
    );
  }
}

