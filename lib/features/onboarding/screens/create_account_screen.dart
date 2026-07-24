import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreateAccountScreen
//
// Separate screen pushed from AuthScreen when the user taps "Create one with
// email" (or from onboarding / auth-gate sign-up flow).
//
// Layout:
//   • AppBar with back arrow → pops to AuthScreen (sign-in)
//   • Full name, Email, Password, Confirm password, Phone fields
//   • "Create an Account" filled button
//   • Bottom: "Already registered? Login" link → pops
// ─────────────────────────────────────────────────────────────────────────────

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _fullNameCtrl         = TextEditingController();
  final _emailCtrl            = TextEditingController();
  final _passwordCtrl         = TextEditingController();
  final _confirmPasswordCtrl  = TextEditingController();
  final _phoneCtrl            = TextEditingController();

  bool   _passwordVisible        = false;
  bool   _confirmPasswordVisible = false;
  bool   _isLoading              = false;
  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  InputDecoration _fieldDeco(
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
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _eyeToggle(BuildContext context,
      {required bool visible, required VoidCallback onToggle}) {
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

  String _friendlyError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('not authenticated') ||
        lower.contains('user not confirmed') ||
        lower.contains('email not confirmed') ||
        lower.contains('confirmation required') ||
        lower.contains('verify your email') ||
        lower.contains('confirm your email')) {
      return KoolanAppStateScope.of(context).s.authConfirmationRequired;
    }
    return msg;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() {
        _error = KoolanAppStateScope.of(context).s.authSupabaseUnavailable;
        _isLoading = false;
      });
      return;
    }

    try {
      final phone    = _phoneCtrl.text.trim();
      final fullName = _fullNameCtrl.text.trim();
      final response = await client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        emailRedirectTo: AppSupabaseConfig.emailRedirectUrl,
        data: {
          if (fullName.isNotEmpty) 'full_name': fullName,
          if (phone.isNotEmpty)    'phone': phone,
        },
      );
      if (!mounted) return;
      if (response.session == null) {
        // Email confirmation required — stay on screen and show message.
        setState(() =>
            _error = KoolanAppStateScope.of(context).s.authConfirmationRequired);
        return;
      }
      await KoolanAppStateScope.of(context).onFreshAuth();
    } on AuthException catch (e) {
      setState(() => _error = _friendlyError(e.message));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          tooltip: s.wizardBack,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          s.authCreateAccount,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Full name ──────────────────────────────────────────────
                TextFormField(
                  controller: _fullNameCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDeco(
                    context,
                    label: s.authFullName,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? s.authFullNameRequired
                      : null,
                ),
                const SizedBox(height: 14),

                // ── Email ──────────────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: _fieldDeco(
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

                // ── Password ───────────────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_passwordVisible,
                  decoration: _fieldDeco(
                    context,
                    label: s.authPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: _eyeToggle(
                      context,
                      visible: _passwordVisible,
                      onToggle: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? s.authPasswordMin : null,
                ),
                const SizedBox(height: 14),

                // ── Confirm password ───────────────────────────────────────
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: !_confirmPasswordVisible,
                  decoration: _fieldDeco(
                    context,
                    label: s.authConfirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: _eyeToggle(
                      context,
                      visible: _confirmPasswordVisible,
                      onToggle: () => setState(() =>
                          _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.authPasswordMin;
                    if (v != _passwordCtrl.text) return s.authPasswordsDoNotMatch;
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Phone (optional) ───────────────────────────────────────
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDeco(
                    context,
                    label: s.editProfilePhone,
                    hint: '+251 9X XXX XXXX',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Error banner ───────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: cs.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style:
                                  TextStyle(color: cs.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Create account button ──────────────────────────────────
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : Text(
                          s.authCreateAccount,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 32),

                // ── Bottom: already registered link ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered?',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
