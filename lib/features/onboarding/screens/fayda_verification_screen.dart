import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/services/app_state.dart';

/// Fayda ID verification UI shell.
///
/// This is a two-step onboarding flow:
///   Step 1 — User enters their 14-digit Fayda National ID number.
///   Step 2 — User enters the 6-digit OTP sent to their registered phone.
///
/// Real API integration requires Fayda ABIS/OpenG2P credentials. Until
/// credentials are available, the screen simulates the full flow with a
/// mocked success response (tap Verify → OTP screen → tap Confirm → success).
/// The UI is production-ready: swap `_mockVerifyId` / `_mockVerifyOtp` with
/// real HTTP calls when credentials arrive.
class FaydaVerificationScreen extends StatefulWidget {
  /// [onComplete] is called when the user finishes (verified or skipped).
  final Future<void> Function(bool verified) onComplete;

  const FaydaVerificationScreen({super.key, required this.onComplete});

  @override
  State<FaydaVerificationScreen> createState() =>
      _FaydaVerificationScreenState();
}

class _FaydaVerificationScreenState extends State<FaydaVerificationScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _otpController = TextEditingController();

  int _step = 1; // 1 = enter ID, 2 = enter OTP, 3 = success
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Mock API calls (replace with real Fayda HTTP requests) ──────────────────

  /// Simulates submitting the Fayda ID to the verification API.
  /// Returns true if accepted (mock always accepts a 14-digit number).
  Future<bool> _mockVerifyId(String faydaId) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // Mock: any 14-digit numeric string is accepted.
    return faydaId.length == 14 && RegExp(r'^\d{14}$').hasMatch(faydaId);
  }

  /// Simulates verifying the OTP against the Fayda backend.
  /// Mock: code '123456' (or any 6 digits) is accepted.
  Future<bool> _mockVerifyOtp(String otp) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp);
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  Future<void> _submitId() async {
    if (!(_formKey1.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final accepted = await _mockVerifyId(_idController.text.trim());
      if (!mounted) return;
      if (accepted) {
        setState(() => _step = 2);
      } else {
        setState(
          () => _error = KoolanAppStateScope.of(context).s.faydaErrorGeneric,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = KoolanAppStateScope.of(context).s.faydaErrorNetwork,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOtp() async {
    if (!(_formKey2.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final verified = await _mockVerifyOtp(_otpController.text.trim());
      if (!mounted) return;
      if (verified) {
        setState(() => _step = 3);
      } else {
        setState(
          () => _error = KoolanAppStateScope.of(context).s.faydaErrorGeneric,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = KoolanAppStateScope.of(context).s.faydaErrorNetwork,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _error = null;
      _otpController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(KoolanAppStateScope.of(context).s.faydaOtpSubtitle),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_step < 3)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: cs.primary),
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_step == 1) {
                                Navigator.of(context).pop();
                              } else {
                                setState(() {
                                  _step = 1;
                                  _error = null;
                                  _otpController.clear();
                                });
                              }
                            },
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _step == 1
                              ? 0.33
                              : _step == 2
                              ? 0.66
                              : 1.0,
                          color: cs.primary,
                          backgroundColor: cs.surfaceContainerHighest,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _step == 1
                              ? s.faydaStep1of2
                              : _step == 2
                              ? s.faydaStep2of2
                              : s.faydaTrustBadge,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _step == 1
                    ? _Step1Body(
                        key: const ValueKey(1),
                        formKey: _formKey1,
                        controller: _idController,
                        isLoading: _isLoading,
                        error: _error,
                        onSubmit: _submitId,
                        onSkip: () => widget.onComplete(false),
                      )
                    : _step == 2
                    ? _Step2Body(
                        key: const ValueKey(2),
                        formKey: _formKey2,
                        controller: _otpController,
                        maskedPhone:
                            '+251 9** *** **${_idController.text.length >= 2 ? _idController.text.substring(_idController.text.length - 2) : '00'}',
                        isLoading: _isLoading,
                        error: _error,
                        onSubmit: _submitOtp,
                        onResend: _resendCode,
                      )
                    : _SuccessBody(
                        key: const ValueKey(3),
                        onContinue: () => widget.onComplete(true),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Enter Fayda ID ────────────────────────────────────────────────────

class _Step1Body extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  const _Step1Body({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Fayda brand mark ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF078A4E), // Ethiopian green
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.faydaTrustBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF078A4E),
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        s.faydaTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              s.faydaSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // ── Benefits ──────────────────────────────────────────────────────
            Text(
              s.faydaBenefitsTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              (Icons.verified_user_outlined, s.faydaBenefit1),
              (Icons.trending_up, s.faydaBenefit2),
              (Icons.shield_outlined, s.faydaBenefit3),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(item.$1, size: 18, color: const Color(0xFF078A4E)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── ID input ──────────────────────────────────────────────────────
            Text(
              s.faydaIdLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: s.faydaIdHint,
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 14,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF078A4E),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.error),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.faydaIdRequired;
                if (v.trim().length != 14 ||
                    !RegExp(r'^\d{14}$').hasMatch(v.trim())) {
                  return s.faydaIdInvalid;
                }
                return null;
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: TextStyle(color: cs.error, fontSize: 13)),
            ],

            // ── What is Fayda? collapsible hint ──────────────────────────────
            const SizedBox(height: 16),
            _FaydaInfoTile(),
            const SizedBox(height: 32),

            // ── CTA buttons ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF078A4E),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.faydaVerifyButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading ? null : onSkip,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  s.faydaSkip,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Enter OTP ─────────────────────────────────────────────────────────

class _Step2Body extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String maskedPhone;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onResend;

  const _Step2Body({
    super.key,
    required this.formKey,
    required this.controller,
    required this.maskedPhone,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // ── Icon ──────────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF078A4E).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF078A4E).withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 34,
                  color: Color(0xFF078A4E),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              s.faydaOtpTitle,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: s.faydaOtpSubtitle),
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: maskedPhone,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── OTP input ─────────────────────────────────────────────────────
            Text(
              s.faydaOtpLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 28,
                letterSpacing: 12,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: s.faydaOtpHint,
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withOpacity(0.4),
                  fontSize: 28,
                  letterSpacing: 12,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF078A4E),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.error),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.faydaOtpRequired;
                if (v.trim().length != 6) return s.faydaOtpInvalid;
                return null;
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: TextStyle(color: cs.error, fontSize: 13)),
            ],
            const SizedBox(height: 12),

            // ── Resend ────────────────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: isLoading ? null : onResend,
                child: Text(
                  s.faydaResendCode,
                  style: const TextStyle(
                    color: Color(0xFF078A4E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── CTA ───────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF078A4E),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.faydaSubmitButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 3: Success ───────────────────────────────────────────────────────────

class _SuccessBody extends StatefulWidget {
  final VoidCallback onContinue;

  const _SuccessBody({super.key, required this.onContinue});

  @override
  State<_SuccessBody> createState() => _SuccessBodyState();
}

class _SuccessBodyState extends State<_SuccessBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  bool _isProceeding = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
    // Delay slightly so the AnimatedSwitcher transition completes first.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_isProceeding) return;
    setState(() => _isProceeding = true);
    try {
      widget.onContinue();
    } catch (_) {
      if (mounted) setState(() => _isProceeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Animated success badge ─────────────────────────────────────────
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF078A4E).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF078A4E), width: 3),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 58,
                color: Color(0xFF078A4E),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Trust badge pill ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF078A4E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF078A4E).withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 16,
                  color: Color(0xFF078A4E),
                ),
                const SizedBox(width: 6),
                Text(
                  s.faydaTrustBadge,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF078A4E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            s.faydaSuccess,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            s.faydaSuccessSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // What's next callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.faydaContinue,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Explicit NEXT button — only navigation trigger ─────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isProceeding ? null : _handleContinue,
              icon: _isProceeding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: Text(
                _isProceeding ? '' : 'Go to Home',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF078A4E),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── "What is Fayda?" expandable info tile ────────────────────────────────────

class _FaydaInfoTile extends StatefulWidget {
  @override
  State<_FaydaInfoTile> createState() => _FaydaInfoTileState();
}

class _FaydaInfoTileState extends State<_FaydaInfoTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.faydaWhatIsFayda,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  s.faydaWhatIsFaydaBody,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
