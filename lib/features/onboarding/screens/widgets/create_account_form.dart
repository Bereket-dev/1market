part of '../create_account_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Create-account screen sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Error banner shown when [error] is non-null.
class _CreateAccountErrorBanner extends StatelessWidget {
  final String error;
  const _CreateAccountErrorBanner({required this.error});

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

/// "Already registered? Login" bottom row.
class _CreateAccountBottomLink extends StatelessWidget {
  final bool isLoading;
  const _CreateAccountBottomLink({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already registered?',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Login',
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
