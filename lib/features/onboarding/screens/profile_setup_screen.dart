import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';

/// Shown during onboarding for OAuth users (Google / Facebook) who are missing
/// a display name or phone number. Both fields are required — phone is needed
/// so buyers can contact sellers, and a real name builds trust.
///
/// Placed after LanguageScreen and before LocationPermissionScreen.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill whatever the OAuth provider gave us.
    // Use non-registering read because initState must not call
    // dependOnInheritedWidgetOfExactType before the widget is mounted.
    final profile = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
        .notifier!
        .profile;
    _nameCtrl = TextEditingController(text: profile?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(KoolanAppState state) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await state.completeProfileSetup(
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ───────────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.person_rounded,
                    color: cs.primary, size: 36),
              ),
              const SizedBox(height: 24),

              // ── Title ──────────────────────────────────────────────────────
              Text(
                s.profileSetupTitle,
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.profileSetupSubtitle,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),

              // ── Form ───────────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display name
                    TextFormField(
                      controller: _nameCtrl,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: _deco(
                        context,
                        label: s.profileSetupNameLabel,
                        hint: s.profileSetupNameHint,
                        icon: Icons.badge_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.profileSetupNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone number
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _deco(
                        context,
                        label: s.profileSetupPhoneLabel,
                        hint: s.profileSetupPhoneHint,
                        icon: Icons.phone_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return s.profileSetupPhoneRequired;
                        }
                        // Minimal sanity: at least 7 digits.
                        final digits =
                            v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 7) {
                          return s.profileSetupPhoneInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Continue button
                    FilledButton(
                      onPressed: _isSaving ? null : () => _save(state),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Text(
                              s.profileSetupContinue,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
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
}
