import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/app_state.dart';
import 'reset_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(
        () => _error = KoolanAppStateScope.of(context).s.authSupabaseUnavailable,
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final auth = client.auth;
      if (_isSignUp) {
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailRedirectTo: AppSupabaseConfig.emailRedirectUrl,
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(
            () => _error = KoolanAppStateScope.of(
              context,
            ).s.authConfirmationRequired,
          );
          return;
        }
        await KoolanAppStateScope.of(context).onFreshAuth();
        return;
      }

      await auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(
        () => _error = KoolanAppStateScope.of(context).s.authSupabaseUnavailable,
      );
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

      // Sign out of any previously cached Google account so the account-picker
      // dialog always appears. Without this, after a logout the plugin silently
      // returns the last account and skips the chooser entirely.
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _error = KoolanAppStateScope.of(context).s.authGoogleCancelled);
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

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                s.authTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.authSubtitle,
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(s.authSignIn)),
                        ButtonSegment(value: true, label: Text(s.authSignUp)),
                      ],
                      selected: {_isSignUp},
                      onSelectionChanged: (value) {
                        setState(() {
                          _isSignUp = value.first;
                          _error = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: s.authEmail,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return s.authEmailRequired;
                        }
                        if (!value.contains('@')) return s.authEmailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: s.authPassword,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return s.authPasswordMin;
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ResetPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(s.authForgotPassword),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: cs.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitEmail,
                  child: Text(
                    _isLoading
                        ? s.authPleaseWait
                        : (_isSignUp ? s.authCreateAccount : s.authContinue),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: cs.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      s.authOrContinue,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  Expanded(child: Divider(color: cs.outlineVariant)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(s.authGoogle),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () {},
                  icon: const Icon(Icons.facebook),
                  label: Text(s.authFacebook),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
