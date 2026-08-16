part of '../app.dart';

// ── Onboarding gate ───────────────────────────────────────────────────────────

class _RootGate extends StatelessWidget {
  final KoolanAppState appState;

  const _RootGate({required this.appState});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('[RootGate] build — phase: ${appState.onboardingPhase}');
    }
    switch (appState.onboardingPhase) {
      case OnboardingPhase.initializing:
        return _InitializingScreen(
          error: appState.initError,
          onRetry: appState.retryInitialization,
          locale: appState.locale,
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

/// Matches native splash: brand blue + centred logo while services start.
class _BrandedBootScreen extends StatelessWidget {
  const _BrandedBootScreen({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF001A5C) : kPrimary;
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/brand/splash_logo.png',
              width: 96,
              height: 96,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.initLoading,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitializingScreen extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  final String locale;

  const _InitializingScreen({
    this.error,
    required this.onRetry,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('[InitializingScreen] build');
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (error == null) {
      final bg = isDark ? const Color(0xFF001A5C) : kPrimary;
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/brand/splash_logo.png',
                width: 96,
                height: 96,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.initLoading,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
    this.locale = 'en',
  });

  final bool retrying;
  final VoidCallback onRetry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings(locale);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/brand/logo.png',
                width: 72,
                height: 72,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 24),
              Icon(Icons.cloud_off_outlined, color: cs.error, size: 40),
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
