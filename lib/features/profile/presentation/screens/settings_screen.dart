import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';
import '../../../onboarding/screens/change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final appState = KoolanAppStateScope.of(context);
    final s = appState.s;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => appState.popScreen(),
        ),
        title: Text(
          s.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Account ──────────────────────────────────────────────────────
          _sectionLabel(s.settingsAccountSection, cs),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.person,
            title: s.settingsProfile,
            subtitle: s.settingsProfileSubtitle,
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.lock,
            title: s.settingsChangePassword,
            subtitle: s.settingsChangePasswordSub,
            trailingText: null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.phone,
            title: s.settingsPhoneVerification,
            subtitle: '+251 912 ****90 verified',
            trailingText: s.settingsPhoneVerified,
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.work,
            title: s.settingsPrefCategory,
            subtitle: 'Selected: HOUSEHOLD SERVICES',
          ),
          const SizedBox(height: 24),

          // ── Trust & Escrow ────────────────────────────────────────────────
          _sectionLabel(s.settingsTrustSection, cs),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.shield,
            title: s.settingsIdVerification,
            subtitle: s.settingsIdVerified,
            trailingText: s.settingsIdVerified,
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.payment,
            title: s.settingsWallet,
            subtitle: s.settingsWalletSub,
          ),
          const SizedBox(height: 24),

          // ── System preferences ────────────────────────────────────────────
          _sectionLabel(s.settingsSystemSection, cs),
          const SizedBox(height: 10),
          // ── Language selector ──────────────────────────────────────────────
          _LanguageRow(currentLocale: appState.locale, onChanged: appState.setLocale),
          const SizedBox(height: 10),
          _SettingsToggleRow(
            icon: Icons.notifications,
            title: s.settingsPushEnabled,
            value: _notificationEnabled,
            onChanged: (val) => setState(() => _notificationEnabled = val),
          ),
          const SizedBox(height: 10),
          _SettingsToggleRow(
            icon: appState.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: s.settingsDarkMode,
            value: appState.isDarkMode,
            // Calls toggleDarkMode() on KoolanAppState — rebuilds entire tree.
            onChanged: (_) => appState.toggleDarkMode(),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSigningOut
                ? null
                : () async {
                    if (!mounted) return;
                    setState(() => _isSigningOut = true);
                    try {
                      await appState.signOut();
                    } finally {
                      if (mounted) {
                        setState(() => _isSigningOut = false);
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.errorContainer,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              s.settingsLogOut,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, ColorScheme cs) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: cs.primary,
        fontSize: 12,
      ),
    );
  }
}

// ── Reusable settings row widgets ─────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withOpacity(0.1),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (trailingText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trailingText!,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );

    return Card(
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary.withOpacity(0.1),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// ── Language selector row ─────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  final String currentLocale;
  final Future<void> Function(String) onChanged;

  const _LanguageRow({
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;

    final options = [
      ('en', s.languageEnglish),
      ('am', s.languageAmharic),
      ('so', s.languageSomali),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary.withOpacity(0.1),
              child: Icon(Icons.language, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                s.settingsLanguage,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentLocale,
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                items: options
                    .map((opt) => DropdownMenuItem<String>(
                          value: opt.$1,
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
