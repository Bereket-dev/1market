part of '../auth_gate_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────

class _AuthGateSheetContent extends StatefulWidget {
  final AuthGateReason reason;
  const _AuthGateSheetContent({required this.reason});

  @override
  State<_AuthGateSheetContent> createState() => _AuthGateSheetContentState();
}

class _AuthGateSheetContentState extends State<_AuthGateSheetContent> {
  bool _loadingGoogle = false;
  bool _loadingFacebook = false;
  String? _error;

  bool get _isLoading => _loadingGoogle || _loadingFacebook;

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
      if (mounted) setState(() => _error = ErrorMapper.userMessage(e, appState.s));
    } catch (e) {
      if (mounted) {
        setState(() => _error = ErrorMapper.userMessage(e, appState.s));
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    final appState = _appState;
    if (appState == null) return;

    setState(() {
      _loadingFacebook = true;
      _error = null;
    });

    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      setState(() {
        _error = appState.s.authSupabaseUnavailable;
        _loadingFacebook = false;
      });
      return;
    }

    try {
      appState.markOAuthPending();
      // Close the sheet before opening the browser so the user isn't stuck
      // looking at a half-open sheet during the OAuth flow.
      if (mounted) Navigator.of(context).pop();

      // Open Facebook OAuth in a Chrome Custom Tab (externalApplication).
      // Using externalApplication lets Android handle the io.supabase.koolan://
      // deep link via the intent filter. inAppWebView would intercept the
      // redirect inside the WebView, mangle it to http://, and fail with
      // ERR_CLEARTEXT_NOT_PERMITTED.
      // Request email so Supabase can auto-link this Facebook identity to an
      // existing account that already uses the same verified email.
      await client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: AppSupabaseConfig.redirectUrl,
        scopes: 'email,public_profile',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // Session arrives via deep-link → onAuthStateChange → hydrateSessionProfile
      // (guest/ready) or onFreshAuth (onboarding auth phase).
    } on AuthException catch (e) {
      if (mounted) {
        final cancelled = AppError.classify(e) == AppErrorKind.cancelled;
        if (!cancelled) {
          setState(() => _error = ErrorMapper.userMessage(e, appState.s));
        }
        _appState?.clearOAuthPending();
      }
    } catch (e) {
      if (mounted) {
        final cancelled = AppError.classify(e) == AppErrorKind.cancelled;
        if (!cancelled) {
          setState(() => _error = ErrorMapper.userMessage(e, appState.s));
        }
        _appState?.clearOAuthPending();
      }
    } finally {
      if (mounted) setState(() => _loadingFacebook = false);
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
              onPressed: _isLoading ? null : _signInWithGoogle,
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
                        const _GoogleLogo(),
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
              onPressed: _isLoading ? null : _signInWithFacebook,
              style: outlinedStyle,
              child: _loadingFacebook
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF1877F2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _FacebookLogo(),
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
              onPressed: _isLoading
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
                  onTap: _isLoading
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

