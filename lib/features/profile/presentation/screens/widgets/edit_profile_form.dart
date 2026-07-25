part of '../edit_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Form bottom section widgets for EditProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Preferred-category dropdown — all valid codes + "None" option.
class _CategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>();
    final s = scope!.notifier!.s;

    return DropdownButtonFormField<String?>(
      initialValue: selectedCategory,
      decoration: InputDecoration(
        labelText: s.editProfilePrefCategory,
        hintText: s.editProfilePrefCategoryHint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(s.editProfilePrefCategoryNone),
        ),
        ..._kCategories.map((cat) {
          final label = switch (cat) {
            'CARS'   => s.homeCategoryCars,
            'HOUSES' => s.homeCategoryHouses,
            'LAND'   => s.homeCategoryLand,
            'SKILLS' => s.homeCategorySkills,
            'OTHERS' => s.homeCategoryOthers,
            _        => s.homeCategoryOthers,
          };
          return DropdownMenuItem<String?>(
            value: cat,
            child: Text(label),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

/// Save button + optional sync-status badge.
class _ProfileSaveSection extends StatelessWidget {
  final bool isSaving;
  final SyncStatus? syncStatus;
  final VoidCallback onSave;
  final VoidCallback? onRetry;

  const _ProfileSaveSection({
    required this.isSaving,
    required this.syncStatus,
    required this.onSave,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>();
    final s = scope!.notifier!.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(isSaving ? s.editProfileSaving : s.editProfileSaveButton),
        ),
        if (syncStatus != null && syncStatus != SyncStatus.synced) ...[
          const SizedBox(height: 12),
          Center(
            child: SyncStatusBadge(
              status: syncStatus!,
              onRetry: syncStatus == SyncStatus.failed ? onRetry : null,
            ),
          ),
        ],
      ],
    );
  }
}
