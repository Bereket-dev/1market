import 'package:flutter/material.dart';

import '../../../../shared/models/syncable_entity.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/sync_status_badge.dart';

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
  late final TextEditingController _cityController;

  /// True while [submitProfileUpdate] is awaited. Disables the save button to
  /// prevent double-submission; the [SyncStatusBadge] shows the real sync state.
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = KoolanAppStateScope.of(context).profile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save(KoolanAppState appState) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await appState.submitProfileUpdate(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = KoolanAppStateScope.of(context);
    final profile = appState.profile;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field('Display name', _nameController),
              const SizedBox(height: 12),
              _field('Bio', _bioController, maxLines: 3),
              const SizedBox(height: 12),
              _field(
                'Phone',
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field('City', _cityController),
              const SizedBox(height: 24),

              // ── Save button ───────────────────────────────────────────────
              FilledButton(
                onPressed: _isSaving ? null : () => _save(appState),
                child: Text(_isSaving ? 'Saving...' : 'Save changes'),
              ),

              // ── Sync status badge ─────────────────────────────────────────
              // Shown whenever there is a meaningful status to surface.
              // Hidden when synced to keep the UI clean after a successful save.
              if (profile != null && profile.syncStatus != SyncStatus.synced) ...[
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: (value) {
        if (label == 'Display name' &&
            (value == null || value.trim().isEmpty)) {
          return 'Display name is required';
        }
        return null;
      },
    );
  }
}
