import 'package:flutter/material.dart';
import '../../../../shared/services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;

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
          _sectionLabel(
            s.isAmharic
                ? 'የሂሳብ ቅንብሮች'
                : s.isSomali
                    ? 'Dejinta xisaabta'
                    : 'Account settings',
            cs,
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.person,
            title: s.settingsProfile,
            subtitle: s.isAmharic
                ? 'ስም፣ ባዮ እና ፎቶ ይቀይሩ'
                : s.isSomali
                    ? 'Beddel magaca, xogta'
                    : 'Change display name, bio, and photos',
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.phone,
            title: s.isAmharic
                ? 'ስልክ ማረጋገጫ'
                : s.isSomali
                    ? 'Xaqiijinta telefoonka'
                    : 'Phone Verification',
            subtitle: '+251 912 ****90 verified',
            trailingText: s.isAmharic
                ? 'ተረጋግጧል'
                : s.isSomali
                    ? 'Xaqiijiyey'
                    : 'Verified',
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.work,
            title: s.isAmharic
                ? 'ተመራጭ ምድብ'
                : s.isSomali
                    ? 'Qaybta la doortay'
                    : 'Preferred Category',
            subtitle: s.isAmharic
                ? 'የቤት ውስጥ አገልግሎቶች'
                : s.isSomali
                    ? 'Adeegyada guriga'
                    : 'Selected: HOUSEHOLD SERVICES',
          ),
          const SizedBox(height: 24),

          // ── Trust & Escrow ────────────────────────────────────────────────
          _sectionLabel(
            s.isAmharic
                ? 'ደህንነት እና ኤስክሮ'
                : s.isSomali
                    ? 'Ammaan & Escrow'
                    : 'Trust & Escrow Safety',
            cs,
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.shield,
            title: s.isAmharic
                ? 'ዋስትና ማረጋገጫ'
                : s.isSomali
                    ? 'Xaqiijinta aqoonsiga'
                    : 'ID Document Verification',
            subtitle: s.isAmharic
                ? 'የቀበሌ መታወቂያ ተረጋግጧል'
                : s.isSomali
                    ? 'Aqoonsiga Kebele xaqiijiyey'
                    : 'Kebele ID verified',
            trailingText: s.isAmharic
                ? 'ንቁ'
                : s.isSomali
                    ? 'Firfircoon'
                    : 'Active',
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.payment,
            title: s.isAmharic
                ? 'የኤስክሮ ዋሌት'
                : s.isSomali
                    ? 'Xisaabta Escrow'
                    : 'Secure Wallet Account',
            subtitle: s.isAmharic
                ? 'የክፍያ ባንኮችን ያዋቅሩ'
                : s.isSomali
                    ? 'Habaynta bangiga'
                    : 'Configure payout banks & escrow conditions',
          ),
          const SizedBox(height: 24),

          // ── System preferences ────────────────────────────────────────────
          _sectionLabel(
            s.isAmharic
                ? 'የስርዓት ቅንብሮች'
                : s.isSomali
                    ? 'Doorashada nidaamka'
                    : 'System preferences',
            cs,
          ),
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
            onPressed: () => appState.popScreen(),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.errorContainer,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              s.isAmharic
                  ? 'ከሂሳብ ውጣ'
                  : s.isSomali
                      ? 'Ka bax xisaabta'
                      : 'Log Out Account',
              style: TextStyle(
                  color: cs.onErrorContainer, fontWeight: FontWeight.bold),
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
          fontWeight: FontWeight.bold, color: cs.primary, fontSize: 12),
    );
  }
}

// ── Reusable settings row widgets ─────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
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
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
