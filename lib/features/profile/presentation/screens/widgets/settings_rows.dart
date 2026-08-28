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
    this.subtitle = '',
    // ignore: unused_element_parameter — optional trailing label for future rows
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
                if (subtitle.isNotEmpty)
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
  final String? subtitle;
  final bool value;
  final bool busy;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    this.subtitle,
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
                child: subtitle != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(subtitle!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.7))),
                        ],
                      )
                    : Text(title,
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

// ── Debug sync section (only visible in debug builds) ────────────────────────
//
// Shows aggregate sync metrics from [OnemarketAppState.syncObservability] so
// developers can verify the Phase 4 version-cursor path, bandwidth targets,
// and queue health without opening a separate debug overlay.
//
// Wrapped in an [if (kDebugMode)] in the calling widget tree — this class
// itself does not guard, so the tree-shaker can eliminate it in release
// builds.

class _SyncDebugSection extends StatelessWidget {
  const _SyncDebugSection({required this.appState});

  final OnemarketAppState appState;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: appState.syncObservability,
      builder: (context, _) {
        final obs = appState.syncObservability;

        String fmt(int bytes) {
          if (bytes < 1024) return '$bytes B';
          if (bytes < 1024 * 1024) {
            return '${(bytes / 1024).toStringAsFixed(1)} KB';
          }
          return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
        }

        final rows = <_DebugRow>[
          _DebugRow(
            label: 'Last sync',
            value: obs.lastSyncLabel,
            icon: Icons.check_circle_outline,
          ),
          _DebugRow(
            label: 'Duration',
            value: obs.lastSyncDuration != null
                ? '${obs.lastSyncDuration!.inMilliseconds} ms'
                : '—',
            icon: Icons.timer_outlined,
          ),
          _DebugRow(
            label: 'Downloaded',
            value: fmt(obs.bytesDownloaded),
            icon: Icons.download_outlined,
          ),
          _DebugRow(
            label: 'Uploaded',
            value: fmt(obs.bytesUploaded),
            icon: Icons.upload_outlined,
          ),
          _DebugRow(
            label: 'Pending ops',
            value: obs.pendingOperations.toString(),
            icon: Icons.pending_outlined,
          ),
          _DebugRow(
            label: 'Failed ops',
            value: obs.failedOperations.toString(),
            icon: Icons.error_outline,
            isError: obs.hasFailures,
          ),
        ];

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          elevation: 0,
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report_outlined,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'SYNC DEBUG',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    if (appState.isRefreshing)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...rows.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            row.icon,
                            size: 14,
                            color: row.isError
                                ? cs.error
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${row.label}: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            row.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: row.isError ? cs.error : cs.onSurface,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => appState.syncObservability.reset(),
                  child: Text(
                    'Reset counters',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebugRow {
  final String label;
  final String value;
  final IconData icon;
  final bool isError;

  const _DebugRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isError = false,
  });
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
        .getInheritedWidgetOfExactType<OnemarketAppStateScope>()!
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
