part of '../auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth screen form sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Headline + subtitle section at top of auth screen.
class _AuthHeadline extends StatelessWidget {
  const _AuthHeadline();

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: BrandLogo(iconOnly: true, width: 64, height: 64),
        ),
        const SizedBox(height: 14),
        Text(
          s.authSignIn,
          textAlign: TextAlign.center,
          style: tt.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.appSlogan,
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.authSubtitle,
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Or-divider between social buttons and email/password form.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.6))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            s.authOrContinue,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.6))),
      ],
    );
  }
}

/// Error banner shown below the password field when [error] is non-null.
class _AuthErrorBanner extends StatelessWidget {
  final String error;
  const _AuthErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: TextStyle(color: cs.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Bottom "Don't have an account? Create one" row.
class _AuthBottomLink extends StatelessWidget {
  final bool isLoading;
  const _AuthBottomLink({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          s.authGateNoAccount,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: isLoading
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateAccountScreen(),
                    ),
                  ),
          child: Text(
            s.authGateCreateNow,
            style: TextStyle(
              color: cs.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: cs.primary,
            ),
          ),
        ),
      ],
    );
  }
}
