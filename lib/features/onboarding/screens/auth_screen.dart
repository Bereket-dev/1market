import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/app_state.dart';

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

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      if (_isSignUp) {
        await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
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

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      KoolanAppStateScope.of(context).markOAuthPending();
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: AppSupabaseConfig.redirectUrl,
      );
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
                  child: Text(_isLoading
                      ? s.authPleaseWait
                      : (_isSignUp ? s.authCreateAccount : s.authContinue)),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Divider(color: cs.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(s.authOrContinue,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ),
                Expanded(child: Divider(color: cs.outlineVariant)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _signInWithOAuth(OAuthProvider.google),
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(s.authGoogle),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _signInWithOAuth(OAuthProvider.facebook),
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
