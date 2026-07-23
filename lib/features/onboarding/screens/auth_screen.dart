import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/app_state.dart';
import 'reset_password_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen
//
// Single shared screen for sign-in and sign-up. Reached two ways:
//   1. First-install onboarding  (onboardingPhase == .auth)
//   2. Soft-gate bottom sheet CTAs via appState.goToAuth(signUpMode: …)
//      pendingSignUpMode is consumed in initState to pre-select the tab.
//
// Both entry points share this exact widget; every fix here covers both.
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Independent visibility state per field.
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  bool _isLoading = false;
  bool _isSignUp = false;
  String? _error;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Consume pendingSignUpMode so bottom-sheet "Create Account" pre-selects
    // the sign-up tab automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = KoolanAppStateScope.of(context);
      if (appState.pendingSignUpMode) {
        setState(() => _isSignUp = true);
        appState.clearPendingSignUpMode();
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── UI helpers (class-level so they can reference _passwordCtrl etc.) ──────

  /// Consistent filled input decoration matching the rest of the app.
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

  /// Eye-toggle suffix widget — independent per field, with accessible tooltip.
  Widget _eyeToggle(
    BuildContext context, {
    required bool visible,
    required VoidCallback onToggle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    return Tooltip(
      message: visible ? s.authHidePassword : s.authShowPassword,
      child: IconButton(
        icon: Icon(
          visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: cs.onSurfaceVariant,
          size: 22,
        ),
        onPressed: onToggle,
      ),
    );
  }

  // ── Logic helpers ─────────────────────────────────────────────────────────

  String _friendlyAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('not authenticated') ||
        lower.contains('user not confirmed') ||
        lower.contains('email not confirmed') ||
        lower.contains('confirmation required') ||
        lower.contains('verify your email') ||
        lower.contains('confirm your email')) {
      return KoolanAppStateScope.of(context).s.authConfirmationRequired;
    }
    return message;
  }

  void _switchTab(bool signUp) {
    setState(() {
      _isSignUp = signUp;
      _error = null;
      _passwordVisible = false;
      _confirmPasswordVisible = false;
      if (!signUp) {
        _fullNameCtrl.clear();
        _confirmPasswordCtrl.clear();
        _phoneCtrl.clear();
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() =>
          _error = KoolanAppStateScope.of(context).s.authSupabaseUnavailable);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final auth = client.auth;
      if (_isSignUp) {
        final phone = _phoneCtrl.text.trim();
        final fullName = _fullNameCtrl.text.trim();
        final response = await auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          emailRedirectTo: AppSupabaseConfig.emailRedirectUrl,
          data: {
            if (fullName.isNotEmpty) 'full_name': fullName,
            if (phone.isNotEmpty) 'phone': phone,
          },
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() => _error =
              KoolanAppStateScope.of(context).s.authConfirmationRequired);
          return;
        }
        await KoolanAppStateScope.of(context).onFreshAuth();
        return;
      }

      await auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      await KoolanAppStateScope.of(context).onFreshAuth();
    } on AuthException catch (e) {
      setState(() => _error = _friendlyAuthMessage(e.message));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() =>
          _error = KoolanAppStateScope.of(context).s.authSupabaseUnavailable);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: AppSupabaseConfig.googleWebClientId,
        clientId: Platform.isAndroid
            ? AppSupabaseConfig.googleAndroidClientId
            : AppSupabaseConfig.googleIosClientId,
        scopes: const <String>['email', 'profile'],
      );

      // Always show account-picker by discarding the cached account first.
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) {
          setState(() => _error =
              KoolanAppStateScope.of(context).s.authGoogleCancelled);
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null || accessToken == null) {
        throw Exception('Google authentication tokens were not returned.');
      }

      if (!mounted) return;
      KoolanAppStateScope.of(context).markOAuthPending();
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (!mounted) return;
      await KoolanAppStateScope.of(context).onFreshAuth();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Headline ──────────────────────────────────────────────────
              Text(
                _isSignUp ? s.authCreateAccount : s.authSignIn,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.authSubtitle,
                style:
                    textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),

              // ── Tab switcher ──────────────────────────────────────────────
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(s.authSignIn)),
                  ButtonSegment(value: true, label: Text(s.authSignUp)),
                ],
                selected: {_isSignUp},
                onSelectionChanged: (v) => _switchTab(v.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: cs.primaryContainer,
                  selectedForegroundColor: cs.onPrimaryContainer,
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Form ──────────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full name — sign-up only
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _fullNameCtrl,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        decoration: _fieldDeco(
                          context,
                          label: s.authFullName,
                          prefixIcon:
                              const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? s.authFullNameRequired
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: _fieldDeco(
                        context,
                        label: s.authEmail,
                        prefixIcon:
                            const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return s.authEmailRequired;
                        }
                        if (!v.contains('@')) return s.authEmailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_passwordVisible,
                      decoration: _fieldDeco(
                        context,
                        label: s.authPassword,
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded),
                        suffixIcon: _eyeToggle(
                          context,
                          visible: _passwordVisible,
                          onToggle: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? s.authPasswordMin
                          : null,
                    ),

                    // Confirm password — sign-up only
                    if (_isSignUp) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: !_confirmPasswordVisible,
                        decoration: _fieldDeco(
                          context,
                          label: s.authConfirmPassword,
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded),
                          suffixIcon: _eyeToggle(
                            context,
                            visible: _confirmPasswordVisible,
                            onToggle: () => setState(() =>
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return s.authPasswordMin;
                          }
                          if (v != _passwordCtrl.text) {
                            return s.authPasswordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone — optional
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
                    ],

                    // Forgot password — sign-in only
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ResetPasswordScreen(),
                            ),
                          ),
                          child: Text(
                            s.authForgotPassword,
                            style:
                                TextStyle(color: cs.primary, fontSize: 13),
                          ),
                        ),
                      ),

                    // Error banner
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
                              child: Text(
                                _error!,
                                style: TextStyle(
                                    color: cs.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Primary CTA
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Text(
                              _isSignUp
                                  ? s.authCreateAccount
                                  : s.authContinue,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Or-divider ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      s.authOrContinue,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Google ────────────────────────────────────────────────────
              _SocialButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                badgeColor: const Color(0xFF4285F4),
                badgeLabel: 'G',
                label: s.authGoogle,
              ),
              const SizedBox(height: 10),

              // ── Facebook (not yet configured) ─────────────────────────────
              _SocialButton(
                onPressed: _isLoading
                    ? null
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.authFacebook),
                            behavior: SnackBarBehavior.floating,
                          ),
                        ),
                badgeColor: const Color(0xFF1877F2),
                badgeLabel: 'f',
                label: s.authFacebook,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SocialButton — reusable outlined social-login button
// ─────────────────────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color badgeColor;
  final String badgeLabel;
  final String label;

  const _SocialButton({
    required this.onPressed,
    required this.badgeColor,
    required this.badgeLabel,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              badgeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
