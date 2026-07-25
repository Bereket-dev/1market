import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/app_state.dart';
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
//   • Facebook button
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

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  bool   _passwordVisible     = false;
  bool   _isLoading           = false;
  String? _error;

  bool _facebookOAuthInFlight = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // If this screen was opened in sign-up mode (onboarding or auth-gate
    // "Create account" tap), push CreateAccountScreen on the first frame so
    // the user lands there directly. AuthScreen stays in the back-stack so
    // the user can pop back to sign-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      bool shouldSignUp = widget.fromOnboarding;
      final appState = KoolanAppStateScope.of(context);
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
    WidgetsBinding.instance.removeObserver(this);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _facebookOAuthInFlight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final client = AppSupabaseConfig.clientOrNull();
        final hasSession = client?.auth.currentSession != null;
        if (!hasSession && _facebookOAuthInFlight) {
          setState(() {
            _facebookOAuthInFlight = false;
            _isLoading = false;
          });
          KoolanAppStateScope.of(context).clearOAuthPending();
        }
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
    final s  = KoolanAppStateScope.of(context).s;
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

  // ── Sign-in ────────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
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
      await client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      await KoolanAppStateScope.of(context).onFreshAuth();
    } on AuthException catch (e) {
      setState(() => _error = _friendlyError(e.message));
    } catch (e) {
      setState(() => _error = e.toString());
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
        _error = KoolanAppStateScope.of(context).s.authSupabaseUnavailable;
        _isLoading = false;
      });
      return;
    }
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: AppSupabaseConfig.googleWebClientId,
        clientId: Platform.isAndroid
            ? AppSupabaseConfig.googleAndroidClientId
            : AppSupabaseConfig.googleIosClientId,
        scopes: const ['email', 'profile'],
      );
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) {
          setState(() => _error =
              KoolanAppStateScope.of(context).s.authGoogleCancelled);
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

  // ── Facebook ───────────────────────────────────────────────────────────────

  Future<void> _signInWithFacebook() async {
    setState(() { _isLoading = true; _facebookOAuthInFlight = false; _error = null; });
    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() {
        _error = KoolanAppStateScope.of(context).s.authSupabaseUnavailable;
        _isLoading = false;
      });
      return;
    }
    try {
      if (!mounted) return;
      KoolanAppStateScope.of(context).markOAuthPending();
      setState(() => _facebookOAuthInFlight = true);
      await client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: AppSupabaseConfig.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      if (mounted) {
        final cancelled = e.message.toLowerCase().contains('access_denied') ||
            e.message.toLowerCase().contains('access denied');
        setState(() {
          _error = cancelled ? null : e.message;
          _isLoading = false;
          _facebookOAuthInFlight = false;
        });
        if (cancelled) KoolanAppStateScope.of(context).clearOAuthPending();
      }
    } catch (e) {
      if (mounted) {
        final msg       = e.toString().toLowerCase();
        final cancelled = msg.contains('access_denied') || msg.contains('access denied');
        setState(() {
          _error = cancelled ? null : e.toString();
          _isLoading = false;
          _facebookOAuthInFlight = false;
        });
        if (cancelled) KoolanAppStateScope.of(context).clearOAuthPending();
      }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Headline ───────────────────────────────────────────────────
              Text(
                s.authSignIn,
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.authSubtitle,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              // ── Google ─────────────────────────────────────────────────────
              _SocialButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                logo: const _GoogleLogo(),
                label: s.authGoogle,
              ),
              const SizedBox(height: 10),

              // ── Facebook ───────────────────────────────────────────────────
              _SocialButton(
                onPressed: _isLoading ? null : _signInWithFacebook,
                logo: const _FacebookLogo(),
                label: s.authFacebook,
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
