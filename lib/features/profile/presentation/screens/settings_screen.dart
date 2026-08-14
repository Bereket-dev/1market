import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/services/app_state.dart';
import '../../../onboarding/screens/change_password_screen.dart';
part 'widgets/settings_rows.dart';
part 'widgets/settings_name_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _isSigningOut = false;
  bool _pushToggleBusy = false;
  bool _messagesToggleBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context
          .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
          .notifier!
          .refreshNotificationPermissionState();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context
          .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
          .notifier!
          .refreshNotificationPermissionState()
          .then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _onPushToggle(bool value, KoolanAppState appState) async {
    if (_pushToggleBusy) return;
    setState(() => _pushToggleBusy = true);
    try {
      if (!value) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(appState.s.settingsPushDisableTitle),
            content: Text(appState.s.settingsPushDisableBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(appState.s.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(appState.s.settingsOpenNotificationSettings),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }

      final result = await appState.toggleNotifPush(value);
      if (!mounted) return;

      switch (result) {
        case NotifPushToggleResult.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appState.s.settingsPushPermissionDenied),
              action: SnackBarAction(
                label: appState.s.settingsOpenNotificationSettings,
                onPressed: appState.openNotificationSettings,
              ),
            ),
          );
        case NotifPushToggleResult.disabled:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appState.s.settingsPushDisabledHint)),
          );
        case NotifPushToggleResult.enabled:
          break;
      }
    } finally {
      if (mounted) setState(() => _pushToggleBusy = false);
    }
  }

  Future<void> _onMessagesToggle(bool value, KoolanAppState appState) async {
    if (_messagesToggleBusy) return;
    setState(() => _messagesToggleBusy = true);
    try {
      await appState.toggleNotifMessages(value);
    } finally {
      if (mounted) setState(() => _messagesToggleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
        .notifier!;
    final s = appState.s;
    final cs = Theme.of(context).colorScheme;
    final profile = appState.profile;

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Profile summary card ──────────────────────────────────────────
          // Inline name edit only — no popup, no dialog, no bottom sheet.
          _InlineNameCard(
            displayName: profile?.displayName ?? '—',
            city: profile?.city,
            avatarUrl: profile?.avatarUrl,
          ),
          const SizedBox(height: 24),

          // ── Account ───────────────────────────────────────────────────────
          _SectionLabel(s.settingsAccountSection),
          const SizedBox(height: 10),

          _SettingsRow(
            icon: Icons.person_outline,
            title: s.settingsProfile,
            subtitle: s.settingsProfileSubtitle,
            onTap: () => appState.pushScreen(EditProfileScreenRoute()),
          ),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.lock_outline,
            title: s.settingsChangePassword,
            subtitle: s.settingsChangePasswordSub,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.category_outlined,
            title: s.settingsPrefCategory,
            subtitle: _categoryLabel(profile?.preferredCategory, s),
            onTap: () => appState.pushScreen(EditProfileScreenRoute()),
          ),
          const SizedBox(height: 24),

          // ── System preferences ────────────────────────────────────────────
          _SectionLabel(s.settingsSystemSection),
          const SizedBox(height: 10),

          _LanguageRow(
              currentLocale: appState.locale, onChanged: appState.setLocale),
          const SizedBox(height: 8),

          _SettingsToggleRow(
            icon: appState.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: s.settingsDarkMode,
            value: appState.isDarkMode,
            onChanged: (_) => appState.toggleDarkMode(),
          ),
          const SizedBox(height: 8),

          // ── Data Saver (Phase 3) ──────────────────────────────────────────
          _SettingsToggleRow(
            icon: Icons.data_saver_on_outlined,
            title: s.settingsDataSaver,
            subtitle: s.settingsDataSaverSubtitle,
            value: appState.dataSaverEnabled,
            onChanged: (_) => appState.toggleDataSaver(),
          ),
          const SizedBox(height: 24),

          // ── Contact & location ─────────────────────────────────────────────
          _SectionLabel(s.settingsContactSection),
          const SizedBox(height: 10),

          _ContactInfoRow(
            icon: Icons.phone_outlined,
            title: s.settingsPhoneRow,
            subtitle: s.settingsPhoneRowSub,
            value: profile?.phone,
            emptyLabel: s.settingsAddPhone,
            onTap: () => appState.pushScreen(EditProfileScreenRoute()),
          ),
          const SizedBox(height: 8),

          _ContactInfoRow(
            icon: Icons.location_on_outlined,
            title: s.settingsLocationRow,
            subtitle: s.settingsLocationRowSub,
            value: profile?.city,
            emptyLabel: s.settingsAddLocation,
            onTap: () => appState.pushScreen(EditProfileScreenRoute()),
          ),
          const SizedBox(height: 24),

          // ── Notifications ─────────────────────────────────────────────────
          _SectionLabel(s.settingsNotifications),
          const SizedBox(height: 10),

          _SettingsToggleRow(
            icon: Icons.notifications_outlined,
            title: s.settingsPushEnabled,
            value: appState.notifPushEnabled,
            busy: _pushToggleBusy,
            onChanged: _pushToggleBusy ? null : (v) => _onPushToggle(v, appState),
          ),
          const SizedBox(height: 8),

          _SettingsToggleRow(
            icon: Icons.chat_bubble_outline,
            title: s.settingsNewMessages,
            value: appState.notifMessagesEnabled,
            busy: _messagesToggleBusy,
            enabled: appState.notifPushEnabled,
            onChanged: !appState.notifPushEnabled || _messagesToggleBusy
                ? null
                : (v) => _onMessagesToggle(v, appState),
          ),
          const SizedBox(height: 32),

          // ── Sign out ──────────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _isSigningOut
                ? null
                : () async {
                    if (!mounted) return;
                    setState(() => _isSigningOut = true);
                    try {
                      await appState.signOut();
                    } finally {
                      if (mounted) setState(() => _isSigningOut = false);
                    }
                  },
            icon: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout_rounded),
            label: Text(s.settingsLogOut),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Inline name edit card ─────────────────────────────────────────────────────
//
// Displays the user's avatar, display name, and city. The display name field
// switches between a read-only label and an inline TextField on tap.
// Only the display name is editable here — all other fields are edited on
// EditProfileScreen (reachable via the "Edit Profile" row below).
//
// Uses getInheritedWidgetOfExactType (non-registering) so this widget's
// element is NOT added to KoolanAppStateScope._dependents. We only need
// the profile data once for the initial controller text — we don't need
// automatic rebuild notifications from the scope. Any mutation-driven
// state changes are covered by setState.
