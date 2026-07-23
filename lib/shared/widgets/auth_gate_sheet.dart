import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../services/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showAuthGateSheet
//
// Soft-gate modal bottom sheet for every auth-gated action post first-install.
//
// Layout (new design):
//   • Drag handle
//   • Continue with Google   → completes auth inline, sheet closes
//   • Continue with Facebook → completes auth inline (stub snackbar for now)
//   • Log in with Email      → navigates to AuthScreen
//   • "Don't have an account? Create one now" text link → AuthScreen sign-up
//
// No logo, no lock icon, no body copy — clean action-focused sheet.
// ─────────────────────────────────────────────────────────────────────────────

enum AuthGateReason {
  post,
  save,
  messages,
  notifications,
  profile,
  apply,
  generic,
}

Future<void> showAuthGateSheet(
  BuildContext context, {
  AuthGateReason reason = AuthGateReason.generic,
}) {
  return showModalBottomSheet<void>(
    context: context,
    clipBehavior: Clip.antiAlias,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    barrierColor: Colors.black54,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) => _AuthGateSheetContent(reason: reason),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _AuthGateSheetContent extends StatefulWidget {
  final AuthGateReason reason;
  const _AuthGateSheetContent({required this.reason});

  @override
  State<_AuthGateSheetContent> createState() => _AuthGateSheetContentState();
}

class _AuthGateSheetContentState extends State<_AuthGateSheetContent> {
  bool _loadingGoogle = false;
  String? _error;

  KoolanAppState? get _appState =>
      context.getInheritedWidgetOfExactType<KoolanAppStateScope>()?.notifier;

  Future<void> _signInWithGoogle() async {
    final appState = _appState;
    if (appState == null) return;

    setState(() {
      _loadingGoogle = true;
      _error = null;
    });

    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() {
        _error = appState.s.authSupabaseUnavailable;
        _loadingGoogle = false;
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
        setState(() {
          _error = appState.s.authGoogleCancelled;
          _loadingGoogle = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null || accessToken == null) {
        throw Exception('Google tokens were not returned.');
      }

      if (!mounted) return;
      appState.markOAuthPending();
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      await appState.onFreshAuth();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = _appState;
    if (appState == null) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    final s = appState.s;
    final cs = Theme.of(context).colorScheme;

    // Shared button style
    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag handle ───────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Headline ──────────────────────────────────────────────────
            Text(
              s.authGateTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // ── Error banner ──────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: cs.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: cs.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Continue with Google ──────────────────────────────────────
            OutlinedButton(
              onPressed: _loadingGoogle ? null : _signInWithGoogle,
              style: outlinedStyle,
              child: _loadingGoogle
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialBadge(
                            color: const Color(0xFF4285F4), label: 'G'),
                        const SizedBox(width: 10),
                        Text(
                          s.authGoogle,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),

            // ── Continue with Facebook ────────────────────────────────────
            OutlinedButton(
              onPressed: _loadingGoogle
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(s.authFacebook),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
              style: outlinedStyle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialBadge(color: const Color(0xFF1877F2), label: 'f'),
                  const SizedBox(width: 10),
                  Text(
                    s.authFacebook,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Log in with Email ─────────────────────────────────────────
            OutlinedButton(
              onPressed: _loadingGoogle
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      appState.goToAuth();
                    },
              style: outlinedStyle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded,
                      size: 20, color: cs.onSurface),
                  const SizedBox(width: 10),
                  Text(
                    s.authGateLoginWithEmail,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Don't have an account? Create one now ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.authGateNoAccount,
                  style:
                      TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _loadingGoogle
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          appState.goToAuth(signUpMode: true);
                        },
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SocialBadge — small colored circle with letter
// ─────────────────────────────────────────────────────────────────────────────

class _SocialBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _SocialBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
