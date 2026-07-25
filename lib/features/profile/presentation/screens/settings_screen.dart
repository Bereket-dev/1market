import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/services/app_state.dart';
import '../../../onboarding/screens/change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSigningOut = false;

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
            onChanged: appState.toggleNotifPush,
          ),
          const SizedBox(height: 8),

          _SettingsToggleRow(
            icon: Icons.chat_bubble_outline,
            title: s.settingsNewMessages,
            value: appState.notifMessagesEnabled,
            onChanged: appState.toggleNotifMessages,
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

class _InlineNameCard extends StatefulWidget {
  final String displayName;
  final String? city;
  final String? avatarUrl;

  const _InlineNameCard({
    required this.displayName,
    this.city,
    this.avatarUrl,
  });

  @override
  State<_InlineNameCard> createState() => _InlineNameCardState();
}

class _InlineNameCardState extends State<_InlineNameCard> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.displayName);
  }

  @override
  void didUpdateWidget(_InlineNameCard old) {
    super.didUpdateWidget(old);
    // Sync the controller text when the parent rebuilds with a new name
    // (e.g. after a successful save propagates back through the tree),
    // but only when we're NOT currently editing — we don't want to clobber
    // what the user is typing.
    if (!_editing && old.displayName != widget.displayName) {
      _controller.text = widget.displayName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;

    // Non-registering read — safe inside a State method (not build()).
    // We only need the appState reference here; no reactive subscription needed.
    final scope = context.getInheritedWidgetOfExactType<KoolanAppStateScope>();
    final appState = scope?.notifier;
    if (appState == null) return;

    setState(() => _saving = true);
    try {
      await appState.submitProfileUpdate(
        displayName: name,
        bio: appState.profile?.bio ?? '',
        phone: appState.profile?.phone ?? '',
        city: appState.profile?.city ?? '',
        preferredCategory: appState.profile?.preferredCategory,
      );
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _startEditing() {
    // Reset controller to the current display name when entering edit mode.
    _controller.text = widget.displayName;
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _controller.text = widget.displayName;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Read strings via non-registering lookup (consistent with _save above).
    final scope = context.getInheritedWidgetOfExactType<KoolanAppStateScope>();
    final s = scope?.notifier?.s;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              backgroundImage: widget.avatarUrl != null &&
                      widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(
                      widget.displayName.isNotEmpty
                          ? widget.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Name + city column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_editing) ...[
                    // Inline text field for editing the name
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: cs.onSurface),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onSubmitted: (_) => _save(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Confirm button
                        _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _controller,
                                builder: (_, value, _) => IconButton(
                                  icon: Icon(Icons.check_circle_rounded,
                                      color: value.text.trim().isEmpty
                                          ? cs.onSurfaceVariant
                                              .withValues(alpha: 0.4)
                                          : cs.primary,
                                      size: 22),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onPressed: value.text.trim().isEmpty
                                      ? null
                                      : _save,
                                  tooltip: s?.editProfileNameSave,
                                ),
                              ),
                        // Cancel button
                        if (!_saving)
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: cs.onSurfaceVariant, size: 20),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            onPressed: _cancelEditing,
                            tooltip: s?.commonCancel,
                          ),
                      ],
                    ),
                  ] else ...[
                    // Read-only display — tap the row or the pencil icon to edit
                    GestureDetector(
                      onTap: _startEditing,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.displayName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: cs.onSurface),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined,
                              color: cs.primary, size: 16),
                        ],
                      ),
                    ),
                  ],
                  if (widget.city != null && widget.city!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(widget.city!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: cs.primary,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Settings row ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
              ],
            ),
          ),
          if (trailingText != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(trailingText!,
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            )
          else
            Icon(Icons.chevron_right,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        ],
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: content),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

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
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// ── Contact info row ──────────────────────────────────────────────────────────
//
// Shows the user's phone/city with a filled chip when set, or an "Add …"
// prompt with dashed styling when empty. Tapping always navigates to
// EditProfileScreen where the value can be added or changed.

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;      // current value from profile (phone or city)
  final String emptyLabel;  // e.g. "Add phone number"
  final VoidCallback onTap;

  const _ContactInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasValue
            ? BorderSide.none
            : BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.6),
                width: 1,
                style: BorderStyle.solid,
              ),
      ),
      elevation: 0,
      color: hasValue ? null : cs.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hasValue
                    ? cs.primary.withValues(alpha: 0.1)
                    : cs.outlineVariant.withValues(alpha: 0.25),
                child: Icon(
                  icon,
                  color: hasValue ? cs.primary : cs.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hasValue ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                    if (hasValue)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      )
                    else
                      Text(
                        emptyLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasValue) ...[
                // Value chip
                Container(
                  constraints: const BoxConstraints(maxWidth: 130),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value!.trim(),
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined,
                    size: 16,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ] else
                Icon(Icons.add_circle_outline,
                    color: cs.primary.withValues(alpha: 0.7), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category label helper ─────────────────────────────────────────────────────

String _categoryLabel(String? category, AppStrings s) {
  return switch (category) {
    'CARS'   => s.homeCategoryCars,
    'HOUSES' => s.homeCategoryHouses,
    'LAND'   => s.homeCategoryLand,
    'SKILLS' => s.homeCategorySkills,
    'OTHERS' => s.homeCategoryOthers,
    _        => s.editProfilePrefCategoryNone,
  };
}

// ── Language row ──────────────────────────────────────────────────────────────

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
    final s = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
        .notifier!
        .s;

    final options = [
      ('en', s.languageEnglish),
      ('am', s.languageAmharic),
      ('so', s.languageSomali),
    ];

    return Card(
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Icon(Icons.language, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(s.settingsLanguage,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentLocale,
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                items: options
                    .map((opt) => DropdownMenuItem<String>(
                          value: opt.$1,
                          child: Text(opt.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary)),
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
