import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  bool _notificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => state.popScreen(),
        ),
        title: Text(
          s.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: kBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Account ────────────────────────────────────────────────────────
          _sectionLabel(
            s.isAmharic
                ? 'የሂሳብ ቅንብሮች'
                : s.isSomali
                    ? 'Dejinta xisaabta'
                    : 'Account settings',
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

          // ── Trust & Escrow ─────────────────────────────────────────────────
          _sectionLabel(
            s.isAmharic
                ? 'ደህንነት እና ኤስክሮ'
                : s.isSomali
                    ? 'Ammaan & Escrow'
                    : 'Trust & Escrow Safety',
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

          // ── System preferences ─────────────────────────────────────────────
          _sectionLabel(
            s.isAmharic
                ? 'የስርዓት ቅንብሮች'
                : s.isSomali
                    ? 'Doorashada nidaamka'
                    : 'System preferences',
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
            icon: Icons.light_mode,
            title: s.settingsDarkMode,
            value: _darkModeEnabled,
            onChanged: (val) => setState(() => _darkModeEnabled = val),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () => state.popScreen(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
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
              style: const TextStyle(
                  color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          fontWeight: FontWeight.bold, color: kPrimary, fontSize: 12),
    );
  }
}

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
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: kPrimary.withOpacity(0.08),
              child: Icon(icon, color: kPrimary),
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
                        color: kOnSurfaceVariant.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kVerifiedColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailingText!,
                  style: const TextStyle(
                    color: kVerifiedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: kOnSurfaceVariant),
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
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: kPrimary.withOpacity(0.08),
              child: Icon(icon, color: kPrimary),
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
              activeColor: kPrimary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
