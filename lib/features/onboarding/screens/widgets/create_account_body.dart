part of '../create_account_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Form body widgets for CreateAccountScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Shared input decoration for all create-account fields.
InputDecoration _createAccountFieldDeco(
  BuildContext context, {
  required String label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
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

/// The complete sign-up form: all five fields, error banner, submit button,
/// and "already registered" bottom link.
class _CreateAccountForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final TextEditingController phoneCtrl;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final bool isLoading;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  const _CreateAccountForm({
    required this.formKey,
    required this.fullNameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.phoneCtrl,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.isLoading,
    required this.error,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  Widget _eyeToggle(
    BuildContext context, {
    required bool visible,
    required VoidCallback onToggle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final s  = KoolanAppStateScope.of(context).s;
    return Tooltip(
      message: visible ? s.authHidePassword : s.authShowPassword,
      child: IconButton(
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: cs.onSurfaceVariant,
          size: 22,
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full name
          TextFormField(
            controller: fullNameCtrl,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: _createAccountFieldDeco(context,
                label: s.authFullName,
                prefixIcon: const Icon(Icons.person_outline_rounded)),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? s.authFullNameRequired
                : null,
          ),
          const SizedBox(height: 14),

          // Email
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: _createAccountFieldDeco(context,
                label: s.authEmail,
                prefixIcon: const Icon(Icons.mail_outline_rounded)),
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
            decoration: _createAccountFieldDeco(
              context,
              label: s.authPassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: _eyeToggle(context,
                  visible: passwordVisible, onToggle: onTogglePassword),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? s.authPasswordMin : null,
          ),
          const SizedBox(height: 14),

          // Confirm password
          TextFormField(
            controller: confirmPasswordCtrl,
            obscureText: !confirmPasswordVisible,
            decoration: _createAccountFieldDeco(
              context,
              label: s.authConfirmPassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: _eyeToggle(context,
                  visible: confirmPasswordVisible,
                  onToggle: onToggleConfirmPassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return s.authPasswordMin;
              if (v != passwordCtrl.text) return s.authPasswordsDoNotMatch;
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Phone (optional)
          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _createAccountFieldDeco(context,
                label: s.editProfilePhone,
                hint: '+251 9X XXX XXXX',
                prefixIcon: const Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 8),

          // Error banner
          if (error != null) ...[
            const SizedBox(height: 4),
            _CreateAccountErrorBanner(error: error!),
            const SizedBox(height: 12),
          ],

          // Create account button
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
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
                : Text(s.authCreateAccount,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),

          _CreateAccountBottomLink(isLoading: isLoading),
        ],
      ),
    );
  }
}
