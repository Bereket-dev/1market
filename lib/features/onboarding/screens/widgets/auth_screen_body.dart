part of '../auth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Email/password form section for AuthScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Shared input decoration for all auth text fields.
InputDecoration _authFieldDeco(
  BuildContext context, {
  required String label,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
          BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

/// Email + password form: fields, forgot-password link, error banner,
/// and sign-in button — all in one self-contained widget.
class _AuthEmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final bool isLoading;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;

  const _AuthEmailForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.isLoading,
    required this.error,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    final eyeToggle = Tooltip(
      message: passwordVisible ? s.authHidePassword : s.authShowPassword,
      child: IconButton(
        icon: Icon(
          passwordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: cs.onSurfaceVariant,
          size: 22,
        ),
        onPressed: onTogglePassword,
      ),
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: _authFieldDeco(
              context,
              label: s.authEmail,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return s.authEmailRequired;
              if (!v.contains('@')) return s.authEmailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: passwordCtrl,
            obscureText: !passwordVisible,
            decoration: _authFieldDeco(
              context,
              label: s.authPassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: eyeToggle,
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? s.authPasswordMin : null,
          ),
          const SizedBox(height: 4),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              child: Text(s.authForgotPassword,
                  style: TextStyle(color: cs.primary, fontSize: 13)),
            ),
          ),

          // Error banner
          if (error != null) ...[
            const SizedBox(height: 4),
            _AuthErrorBanner(error: error!),
            const SizedBox(height: 12),
          ],

          // Sign-in button
          FilledButton(
            onPressed: isLoading ? null : onSignIn,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.onPrimary),
                  )
                : Text(s.authContinue,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
