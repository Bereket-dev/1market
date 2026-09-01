import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/services/app_state.dart';
import '../../../shared/widgets/brand_logo.dart';
import 'create_account_screen.dart';
import 'reset_password_screen.dart';
part 'widgets/auth_social_buttons.dart';
part 'widgets/auth_screen_form.dart';
part 'widgets/auth_screen_body.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen — sign-in only
//
// Layout (top → bottom):
//   • App title / headline
//   • Google button
//   • Or-divider
//   • Email field
//   • Password field
//   • Forgot password link  →  pushes ResetPasswordScreen
//   • Sign In button
//   • Error banner (if any)
//   • Bottom: "Don't have an account? Create one with email"
//     → pushes CreateAccountScreen
//
// fromOnboarding: true  → on first frame, immediately push CreateAccountScreen
//                         so the first-install flow still goes to sign-up.
// goToAuth(signUpMode: true) → same push via pendingSignUpMode flag.
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  final bool fromOnboarding;
  const AuthScreen({super.key, this.fromOnboarding = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  bool   _passwordVisible     = false;
  bool   _isLoading           = false;
  String? _error;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // If this screen was opened in sign-up mode (onboarding or auth-gate
    // "Create account" tap), push CreateAccountScreen on the first frame so
    // the user lands there directly. AuthScreen stays in the back-stack so
    // the user can pop back to sign-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      bool shouldSignUp = widget.fromOnboarding;
      final appState = OnemarketAppStateScope.of(context);
      if (appState.pendingSignUpMode) {
        shouldSignUp = true;
        appState.clearPendingSignUpMode();
      }
      if (shouldSignUp) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _mapError(Object error) =>
      ErrorMapper.userMessage(error, OnemarketAppStateScope.of(context).s);

  InputDecoration _fieldDeco(
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

  Widget _eyeToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = OnemarketAppStateScope.of(context).s;
    return Tooltip(
      message: _passwordVisible ? s.authHidePassword : s.authShowPassword,
      child: IconButton(
        icon: Icon(
          _passwordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: cs.onSurfaceVariant,
          size: 22,
        ),
        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
      ),
    );
  }

  // ── Sign-in ────────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() {
        _error = OnemarketAppStateScope.of(context).s.authSupabaseUnavailable;
        _isLoading = false;
      });
      return;
    }
    try {
      await client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      await OnemarketAppStateScope.of(context).onFreshAuth();
    } on AuthException catch (e) {
      setState(() => _error = _mapError(e));
    } catch (e) {
      setState(() => _error = _mapError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google ─────────────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() {
        _error = OnemarketAppStateScope.of(context).s.authSupabaseUnavailable;
        _isLoading = false;
      });
      return;
    }
    try {
      // On Android the client ID comes from google-services.json (compiled in
      // by the Google Services Gradle plugin) — passing clientId here is
      // ignored by the Android plugin and can cause sign-in failures.
      // serverClientId must be the *web* OAuth client ID so the ID token
      // audience matches what Supabase expects.
      final googleSignIn = GoogleSignIn(
        serverClientId: AppSupabaseConfig.googleWebClientId,
        clientId: Platform.isAndroid ? null : AppSupabaseConfig.googleIosClientId,
        scopes: const ['email', 'profile'],
      );
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) {
          setState(() => _error =
              OnemarketAppStateScope.of(context).s.authGoogleCancelled);
        }
        return;
      }
      final googleAuth  = await googleUser.authentication;
      final idToken     = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null || accessToken == null) {
        throw Exception('Google tokens were not returned.');
      }
      if (!mounted) return;
      OnemarketAppStateScope.of(context).markOAuthPending();
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (!mounted) return;
      await OnemarketAppStateScope.of(context).onFreshAuth();
    } on AuthException catch (e) {
      setState(() => _error = _mapError(e));
    } catch (e) {
      setState(() => _error = _mapError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = OnemarketAppStateScope.of(context);
    final s  = appState.s;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Pick up OAuth redirect errors that arrived via the auth stream.
    final pendingAuthError = appState.authError;
    if (pendingAuthError != null && pendingAuthError != _error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        appState.clearAuthError();
        setState(() {
          _error = pendingAuthError;
          _isLoading = false;
        });
      });
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Brand ──────────────────────────────────────────────────────
              const Center(
                child: BrandLogo(iconOnly: true, width: 72, height: 72),
              ),
              const SizedBox(height: 16),
              Text(
                s.authTitle,
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
              const SizedBox(height: 8),
              Text(
                s.authSubtitle,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),

              // ── Google ─────────────────────────────────────────────────────
              _SocialButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                logo: const _GoogleLogo(),
                label: s.authGoogle,
              ),
              const SizedBox(height: 24),

              // ── Or-divider ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.6))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(s.authOrContinue,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.6))),
                ],
              ),
              const SizedBox(height: 20),

              // ── Email + Password form ──────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
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

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_passwordVisible,
                      decoration: _fieldDeco(
                        context,
                        label: s.authPassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: _eyeToggle(context),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? s.authPasswordMin : null,
                    ),
                    const SizedBox(height: 4),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        ),
                        child: Text(s.authForgotPassword,
                            style: TextStyle(color: cs.primary, fontSize: 13)),
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
                              child: Text(_error!,
                                  style:
                                      TextStyle(color: cs.error, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Sign-in button
                    FilledButton(
                      onPressed: _isLoading ? null : _signIn,
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
                          : Text(s.authContinue,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Bottom: create account link ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.authGateNoAccount,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _isLoading
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets (also used by CreateAccountScreen via separate file)
// ─────────────────────────────────────────────────────────────────────────────
