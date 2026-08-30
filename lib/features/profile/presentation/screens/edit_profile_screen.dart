import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';

import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/onemarket_cities.dart';
import '../../../../shared/models/syncable_entity.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/recommendation_engine.dart'
    show kGoalToCategoryCode;
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
part 'widgets/edit_profile_widgets.dart';
part 'widgets/edit_profile_form.dart';

// Valid preferred-category values — must match the CHECK constraint in Supabase.
const _kCategories = ['CARS', 'HOUSES', 'LAND', 'SKILLS', 'OTHERS'];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;

  String _selectedCity = OnemarketCities.launchDefault;
  String? _selectedCategory; // null = "None"

  /// True while [submitProfileUpdate] is awaited.
  bool _isSaving = false;

  /// True while avatar upload is in progress.
  bool _avatarUploading = false;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllersInitialized) {
      // Use getInheritedWidgetOfExactType instead of .of() so we do NOT
      // register this widget as a dependent of OnemarketAppStateScope.
      // Registering a dependency here causes the "_dependents.isEmpty"
      // assertion to fire when notifyListeners() is called during save while
      // the widget is being disposed. We only need the profile data once for
      // the initial controller text — we don't need rebuild notifications.
      final scope = context
          .getInheritedWidgetOfExactType<OnemarketAppStateScope>();
      final profile = scope?.notifier?.profile;
      _nameController.text = profile?.displayName ?? '';
      _bioController.text = profile?.bio ?? '';
      _phoneController.text = profile?.phone ?? '';
      _selectedCity = OnemarketCities.resolve(profile?.city);

      // Sanitize preferredCategory: legacy profiles may have stored a
      // translated goal label (e.g. "Find a car") instead of the category code
      // (e.g. "CARS"). Map it through kGoalToCategoryCode first, then accept
      // only values that exist in _kCategories. Anything unrecognised → null.
      final raw = profile?.preferredCategory;
      if (raw == null) {
        _selectedCategory = null;
      } else {
        // Direct code (CARS, HOUSES, …) passes straight through; legacy labels
        // are converted via the goal→code map.
        final resolved = kGoalToCategoryCode[raw] ?? raw;
        _selectedCategory =
            _kCategories.contains(resolved) ? resolved : null;
      }

      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Save all text fields ──────────────────────────────────────────────────

  Future<void> _save(OnemarketAppState appState) async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent clearing an existing phone number — only allow adding/changing.
    final existingPhone = appState.profile?.phone ?? '';
    final newPhone = _phoneController.text.trim();
    if (existingPhone.isNotEmpty && newPhone.isEmpty) {
      // Silently restore the existing phone so the user can't blank it out.
      _phoneController.text = existingPhone;
    }

    setState(() => _isSaving = true);
    try {
      await appState.submitProfileUpdate(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: newPhone.isEmpty ? existingPhone : newPhone,
        city: _selectedCity,
        preferredCategory: _selectedCategory,
      );
      if (mounted) appState.popScreen();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.userMessage(e, OnemarketAppStateScope.of(context).s)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Photo helpers ─────────────────────────────────────────────────────────

  Future<void> _pickAvatar(OnemarketAppState appState) async {
    setState(() => _avatarUploading = true);
    try {
      final err = await appState.uploadAvatarImage();
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Use getInheritedWidgetOfExactType (non-registering) here so that
    // _EditProfileScreenState's element is NOT added to
    // OnemarketAppStateScope._dependents.  Using the registering .of() would
    // crash with '_dependents.isEmpty': is not true when the second
    // notifyListeners() inside submitProfileUpdate fires after its async gap
    // while the screen element is in the deactivating window.
    //
    // This screen does NOT need automatic rebuilds driven by notifyListeners()
    // because every state change it cares about is already covered by setState:
    //   - _isSaving / _avatarUploading: explicit setState
    //   - profile.syncStatus: read on each setState-triggered rebuild below
    //   - text field initial values: read once in didChangeDependencies
    // The SyncStatusBadge reads profile.syncStatus from this same non-registering
    // lookup during the setState rebuild that clears _isSaving — no separate
    // reactive subscription is needed or safe here.
    final scope = context
        .getInheritedWidgetOfExactType<OnemarketAppStateScope>();
    final appState = scope!.notifier!;
    final profile = appState.profile;
    final cs = Theme.of(context).colorScheme;
    final s = appState.s;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editProfileTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        // Back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.popScreen(),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ══ Photo section ═════════════════════════════════════════════

              // ── Avatar picker ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 24, bottom: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _avatarUploading
                          ? null
                          : () => _pickAvatar(appState),
                      child: Stack(
                        children: [
                          // Avatar circle
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: cs.primary,
                            child: _avatarUploading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : (profile?.avatarUrl != null
                                    ? CachedCircularImage(
                                        imageUrl: profile!.avatarUrl!,
                                        radius: 44)
                                    : CircleAvatar(
                                        radius: 44,
                                        backgroundColor: cs.primaryContainer,
                                        child: Text(
                                          (profile?.displayName ?? '?')
                                              .isNotEmpty
                                              ? (profile?.displayName ?? '?')[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onPrimaryContainer,
                                          ),
                                        ),
                                      )),
                          ),
                          // Camera badge
                          if (!_avatarUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: cs.surface, width: 2),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.camera_alt_rounded,
                                    size: 14, color: cs.onPrimary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.editProfileChangePhoto,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Section divider ───────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),

              // ══ Text fields ═══════════════════════════════════════════════

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Display name
                    _field(
                      label: s.editProfileDisplayName,
                      controller: _nameController,
                      s: s,
                      isRequired: true,
                    ),
                    const SizedBox(height: 14),

                    // Bio
                    _field(
                      label: s.editProfileBio,
                      controller: _bioController,
                      s: s,
                      maxLines: 3,
                      hint: 'Tell others about yourself…',
                    ),
                    const SizedBox(height: 14),

                    // Phone — can be added or changed, but not deleted once set
                    _field(
                      label: s.editProfilePhone,
                      controller: _phoneController,
                      s: s,
                      keyboardType: TextInputType.phone,
                      hint: '+251 9X XXX XXXX',
                      existingValue: appState.profile?.phone,
                    ),
                    const SizedBox(height: 14),

                    // City — East Ethiopia launch cities (Dire Dawa first).
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedCity),
                      initialValue: _selectedCity,
                      decoration: InputDecoration(
                        labelText: s.editProfileCity,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: [
                        for (final city in [
                          ...OnemarketCities.all,
                          if (!OnemarketCities.all.any((c) =>
                              c.toLowerCase() ==
                              _selectedCity.toLowerCase()))
                            _selectedCity,
                        ])
                          DropdownMenuItem(value: city, child: Text(city)),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _selectedCity = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Preferred category dropdown ───────────────────────
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: s.editProfilePrefCategory,
                        hintText: s.editProfilePrefCategoryHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: [
                        // "None" option
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
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),

                    const SizedBox(height: 28),

                    // ── Save button ───────────────────────────────────────
                    FilledButton(
                      onPressed: _isSaving ? null : () => _save(appState),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSaving ? s.editProfileSaving : s.editProfileSaveButton,
                      ),
                    ),

                    // ── Sync status badge ─────────────────────────────────
                    // Driven entirely by the parent's setState (via _isSaving
                    // in the finally block of _save), not by a live
                    // InheritedNotifier subscription.  When _save completes,
                    // setState(() => _isSaving = false) triggers a rebuild
                    // which re-reads profile.syncStatus from the non-registering
                    // scope lookup, so the badge reflects synced/failed without
                    // needing any reactive .of(context) subscription here.
                    if (profile != null &&
                        profile.syncStatus != SyncStatus.synced) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: SyncStatusBadge(
                          status: profile.syncStatus,
                          onRetry: profile.syncStatus == SyncStatus.failed
                              ? () => _save(appState)
                              : null,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required AppStrings s,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool isRequired = false,
    String? existingValue, // if set, field cannot be cleared
  }) {
    final hasExisting =
        existingValue != null && existingValue.trim().isNotEmpty;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: hasExisting ? 'Cannot be removed once set' : null,
        helperStyle: const TextStyle(fontSize: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return s.editProfileDisplayNameRequired;
              }
              return null;
            }
          : hasExisting
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number cannot be removed';
                  }
                  return null;
                }
              : null,
    );
  }
}
