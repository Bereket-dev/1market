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
    // Use getInheritedWidgetOfExactType (non-registering) here because
    // _InitializingScreen only reads .s strings and never needs to rebuild
    // when appState changes — it is shown exactly once, before the app is
    // ready.  Registering a dependency would add it to the listener set
    // unnecessarily and could contribute to the build-scope assertion crash.
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
                  error!,
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

