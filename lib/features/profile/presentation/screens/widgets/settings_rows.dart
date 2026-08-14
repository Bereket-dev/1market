part of '../settings_screen.dart';

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
  final bool busy;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    this.busy = false,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Card(
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
              if (busy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
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
