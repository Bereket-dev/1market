import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/hiring_post.dart';
import '../../../../shared/models/syncable_entity.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/phone_prompt.dart';
part 'widgets/hiring_edit_widgets.dart';
part 'widgets/hiring_edit_form.dart';

/// Create or edit a hiring post.
/// Same UX pattern as [ServiceEditScreen].
class HiringEditScreen extends StatefulWidget {
  final String? postId;
  const HiringEditScreen({super.key, this.postId});

  @override
  State<HiringEditScreen> createState() => _HiringEditScreenState();
}

class _HiringEditScreenState extends State<HiringEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  bool _isOpen = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  /// Existing cover image URL loaded from the post record.
  String _existingImageUrl = '';

  /// Local file path for a newly picked cover image.
  String? _newImagePath;

  /// Error message from image pick.
  String? _imageError;

  HiringPost? _post;
  late String _postId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialise controllers with empty values; populated in
    // didChangeDependencies() once the inherited widget is accessible.
    _titleController = TextEditingController();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _priceController = TextEditingController();
    _postId = 'local_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final state = KoolanAppStateScope.of(context);
    _post = widget.postId == null
        ? null
        : state.getHiringPostById(widget.postId!);
    if (_post != null) _postId = _post!.id;

    _titleController.text = _post?.title ?? '';
    _categoryController.text = _post?.category ?? '';
    _descriptionController.text = _post?.description ?? '';
    _locationController.text = _post?.location ?? '';
    _priceController.text = _post?.priceRange ?? '';
    _isOpen = _post?.isOpen ?? true;
    _existingImageUrl = _post?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );
    } catch (e) {
      setState(() => _imageError = ErrorMapper.userMessage(e, KoolanAppStateScope.of(context).s));
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path != null) {
      setState(() {
        _newImagePath = path;
        _imageError = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = KoolanAppStateScope.of(context);
    final userId = state.currentUser?.id;
    if (userId == null) return;

    // Prompt for phone when creating a new hiring post and profile has none yet.
    // Skip the prompt when editing — the phone was already collected earlier.
    if (widget.postId == null) {
      final proceed = await showPhonePromptIfNeeded(context, state);
      if (!proceed) return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now().toUtc();
    final post = HiringPost(
      id: _postId,
      posterId: userId,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      priceRange: _priceController.text.trim(),
      status: _isOpen ? 'open' : 'closed',
      // Pass existing URL; app_state will replace it if a new image is uploaded.
      imageUrl: _existingImageUrl,
      createdAt: _post?.createdAt,
      localUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    try {
      final resolvedId = await state.submitHiringPostEdit(
        post,
        newImagePaths: _newImagePath != null ? [_newImagePath!] : [],
        existingImageUrls:
            _existingImageUrl.isNotEmpty ? [_existingImageUrl] : [],
      );
      if (!mounted) return;
      if (widget.postId == null) {
        // New post — pop the edit screen then open the detail screen.
        state.popScreen();
        state.pushScreen(HiringDetailScreenRoute(resolvedId));
      } else {
        // Edit — just go back.
        state.popScreen();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.hiringDeleteButton),
        content: Text(s.hiringDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.hiringDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            // Use ctx — not the outer context — so the colorScheme lookup
            // stays within the dialog's own element and doesn't touch a
            // screen element that may already be deactivated.
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(s.hiringDeleteConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await state.deleteHiringPost(_post!.id);
        if (!mounted) return;
        state.popScreen();
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final isEditing = _post != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(
          isEditing ? s.hiringEditTitle : s.hiringCreateTitle,
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: s.hiringDeleteButton,
              onPressed:
                  (_isSaving || _isDeleting) ? null : _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ── Cover Image ────────────────────────────────────────────
              _SectionLabel(label: 'Cover Photo', cs: cs),
              const SizedBox(height: 8),
              _buildImagePicker(cs),
              if (_imageError != null) ...[
                const SizedBox(height: 4),
                Text(_imageError!,
                    style: TextStyle(fontSize: 12, color: cs.error)),
              ],
              const SizedBox(height: 16),
              // ── Title ────────────────────────────────────────────────
              _field(
                label: s.hiringTitleLabel,
                hint: s.hiringTitleHint,
                controller: _titleController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? s.hiringTitleRequired
                        : null,
              ),
              const SizedBox(height: 12),
              // ── Category ─────────────────────────────────────────────
              _field(
                label: s.hiringCategoryLabel,
                hint: s.hiringCategoryHint,
                controller: _categoryController,
              ),
              const SizedBox(height: 12),
              // ── Description ───────────────────────────────────────────
              _field(
                label: s.hiringDescriptionLabel,
                hint: s.hiringDescriptionHint,
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              // ── Location ──────────────────────────────────────────────
              _field(
                label: s.hiringLocationLabel,
                hint: s.hiringLocationHint,
                controller: _locationController,
              ),
              const SizedBox(height: 12),
              // ── Budget ────────────────────────────────────────────────
              _field(
                label: s.hiringPriceRangeLabel,
                hint: s.hiringPriceRangeHint,
                controller: _priceController,
              ),
              const SizedBox(height: 12),
              // ── Open/Closed — labelled toggle, never icon-only ─────────
              Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.hiringStatusLabel,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    _isOpen
                        ? s.hiringStatusOpen
                        : s.hiringStatusClosed,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isOpen ? cs.primary : cs.error,
                    ),
                  ),
                  Switch.adaptive(
                    value: _isOpen,
                    onChanged: (v) => setState(() => _isOpen = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // ── Save ─────────────────────────────────────────────────
              FilledButton(
                onPressed:
                    (_isSaving || _isDeleting) ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(s.hiringSaveButton),
              ),
              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s.hiringDeleteButton),
                  onPressed: (_isSaving || _isDeleting)
                      ? null
                      : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(ColorScheme cs) {
    if (_newImagePath != null) {
      return SizedBox(
        height: 120,
        child: Row(
          children: [
            _LocalImageTile(
              path: _newImagePath!,
              cs: cs,
              onRemove: () => setState(() => _newImagePath = null),
            ),
          ],
        ),
      );
    }
    if (_existingImageUrl.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: Row(
          children: [
            _RemoteImageTile(
              url: _existingImageUrl,
              cs: cs,
              onRemove: () => setState(() => _existingImageUrl = ''),
            ),
            const SizedBox(width: 8),
            _AddTile(cs: cs, onTap: _pickImage),
          ],
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          _AddTile(cs: cs, label: 'Add Cover Photo', onTap: _pickImage),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image picker sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
