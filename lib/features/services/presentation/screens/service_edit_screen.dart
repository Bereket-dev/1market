import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/models/service.dart';
import '../../../../shared/models/syncable_entity.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/cv_upload_service.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/cv_upload_button.dart';

class ServiceEditScreen extends StatefulWidget {
  final String? serviceId;

  const ServiceEditScreen({super.key, this.serviceId});

  @override
  State<ServiceEditScreen> createState() => _ServiceEditScreenState();
}

class _ServiceEditScreenState extends State<ServiceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _coverController;
  late TextEditingController _descriptionController;
  late TextEditingController _experienceController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  bool _availability = true;

  /// Remote URL of CV if already uploaded. Null = no CV or pending upload.
  String? _cvFileUrl;

  /// True when a CV was picked offline and is queued for upload.
  bool _cvPending = false;

  /// Existing image URLs loaded from the service record (already uploaded).
  List<String> _existingImageUrls = [];

  /// Local file paths for newly picked images (not yet uploaded).
  List<String> _newImagePaths = [];

  /// Error message from image pick.
  String? _imageError;

  bool _isSaving = false;
  bool _isDeleting = false;

  Service? _service;
  late String _serviceId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Controllers initialised with empty values here; populated in
    // didChangeDependencies() once the inherited widget is accessible.
    _titleController = TextEditingController();
    _categoryController = TextEditingController();
    _coverController = TextEditingController();
    _descriptionController = TextEditingController();
    _experienceController = TextEditingController();
    _priceController = TextEditingController();
    _locationController = TextEditingController();
    _serviceId = _generateId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final state = KoolanAppStateScope.of(context);
    _service = widget.serviceId == null
        ? null
        : state.getServiceById(widget.serviceId!);
    if (_service != null) _serviceId = _service!.id;

    _titleController.text = _service?.title ?? '';
    _categoryController.text = _service?.category ?? '';
    _coverController.text = _service?.coverDescription ?? '';
    _descriptionController.text = _service?.description ?? '';
    _experienceController.text =
        _service != null ? _service!.yearsOfExperience.toString() : '';
    _priceController.text = _service?.priceRange ?? '';
    _locationController.text = _service?.location ?? '';
    _availability = _service?.availability ?? true;
    _cvFileUrl = _service?.cvFileUrl;
    // Populate image list: prefer imageUrls[], fall back to single imageUrl.
    if (_service != null) {
      _existingImageUrls = _service!.imageUrls.isNotEmpty
          ? List<String>.from(_service!.imageUrls)
          : _service!.imageUrl.isNotEmpty
              ? [_service!.imageUrl]
              : [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _coverController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _locationController.dispose();
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
      setState(() => _imageError = e.toString());
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path != null) {
      setState(() {
        _newImagePaths = [path];
        _imageError = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = KoolanAppStateScope.of(context);
    final currentUser = state.currentUser;
    if (currentUser == null) return;

    setState(() => _isSaving = true);
    final now = DateTime.now().toUtc();
    final service = Service(
      id: _serviceId,
      ownerId: currentUser.id,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
      coverDescription: _coverController.text.trim(),
      // If cv is pending offline, pass null — sync will patch the URL later.
      cvFileUrl: _cvFileUrl,
      yearsOfExperience:
          int.tryParse(_experienceController.text.trim()) ?? 0,
      priceRange: _priceController.text.trim(),
      location: _locationController.text.trim(),
      availability: _availability,
      // Pass existing URL; app_state will replace it if a new image is uploaded.
      imageUrl: _existingImageUrls.isNotEmpty ? _existingImageUrls.first : '',
      createdAt: _service?.createdAt,
      localUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    try {
      await state.submitServiceEdit(
        service,
        newImagePaths: _newImagePaths,
        existingImageUrls: _existingImageUrls,
      );
      if (!mounted) return;
      state.popScreen();
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
        title: Text(s.servicesDeleteButton),
        content: Text(s.servicesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.servicesDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(s.servicesDeleteConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await state.deleteService(_service!.id);
        if (!mounted) return;
        state.popScreen();
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  /// Timestamp-based ID for new services so the sync queue can match them
  /// if the app restarts before sync. Will be replaced by Supabase UUID on
  /// the first successful insert.
  String _generateId() =>
      'local_${DateTime.now().millisecondsSinceEpoch}';

  void _onCvResult(CvUploadResult result) {
    if (result is CvUploadQueued) {
      setState(() {
        if (result.remoteUrl != null) {
          _cvFileUrl = result.remoteUrl;
          _cvPending = false;
        } else {
          // Offline — CV is queued; URL will arrive on reconnect.
          _cvPending = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final isEditing = _service != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(isEditing ? s.servicesEditTitle : s.servicesCreateTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: s.servicesDeleteButton,
              onPressed: (_isSaving || _isDeleting) ? null : _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ── Cover Image ────────────────────────────────────────────────
              _SectionLabel(label: 'Cover Photo', cs: cs),
              const SizedBox(height: 8),
              _buildImagePicker(cs),
              if (_imageError != null) ...[
                const SizedBox(height: 4),
                Text(_imageError!,
                    style: TextStyle(fontSize: 12, color: cs.error)),
              ],
              const SizedBox(height: 16),
              // ── Title ──────────────────────────────────────────────────────
              _field(
                label: s.servicesTitleLabel,
                hint: s.servicesTitleHint,
                controller: _titleController,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.servicesTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              // ── Category ───────────────────────────────────────────────────
              _field(
                label: s.servicesCategoryLabel,
                hint: s.servicesCategoryHint,
                controller: _categoryController,
              ),
              const SizedBox(height: 12),
              // ── Cover description ──────────────────────────────────────────
              _field(
                label: s.servicesCoverDescriptionLabel,
                hint: s.servicesCoverDescriptionHint,
                controller: _coverController,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              // ── Description ────────────────────────────────────────────────
              _field(
                label: s.servicesDescriptionLabel,
                hint: s.servicesDescriptionHint,
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              // ── Years of experience ────────────────────────────────────────
              _field(
                label: s.servicesYearsOfExperienceLabel,
                hint: s.servicesYearsOfExperienceHint,
                controller: _experienceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              // ── Price range ────────────────────────────────────────────────
              _field(
                label: s.servicesPriceRangeLabel,
                hint: s.servicesPriceRangeHint,
                controller: _priceController,
              ),
              const SizedBox(height: 12),
              // ── Location ───────────────────────────────────────────────────
              _field(
                label: s.servicesLocationLabel,
                hint: s.servicesLocationHint,
                controller: _locationController,
              ),
              const SizedBox(height: 12),
              // ── Availability — labelled toggle, never icon-only ────────────
              Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.servicesAvailabilityLabel,
                      style: TextStyle(fontSize: 15, color: cs.onSurface),
                    ),
                  ),
                  Text(
                    _availability
                        ? s.servicesAvailable
                        : s.servicesUnavailable,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _availability ? cs.primary : cs.error,
                    ),
                  ),
                  Switch.adaptive(
                    value: _availability,
                    onChanged: (v) => setState(() => _availability = v),
                  ),
                ],
              ),
              // ── Offline CV pending note ────────────────────────────────────
              if (_cvPending) ...[
                const SizedBox(height: 4),
                Text(
                  s.servicesCvPending,
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
              ],
              const SizedBox(height: 12),
              // ── Existing CV preview (shown when a CV URL exists and no new
              //    file has been picked yet) ─────────────────────────────────
              if (_cvFileUrl != null && !_cvPending)
                _CvPreviewCard(cvUrl: _cvFileUrl!, cs: cs, s: s),
              const SizedBox(height: 12),
              // ── CV upload — labelled, with offline queue + size check ──────
              CvUploadButton(
                serviceId: _serviceId,
                currentCvUrl: _cvFileUrl,
                onResult: _onCvResult,
              ),
              const SizedBox(height: 24),
              // ── Save ───────────────────────────────────────────────────────
              FilledButton(
                onPressed: (_isSaving || _isDeleting) ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.servicesSaveButton),
              ),
              // ── Delete (also from app bar) ─────────────────────────────────
              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s.servicesDeleteButton),
                  onPressed: (_isSaving || _isDeleting) ? null : _confirmDelete,
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
    // Show new local image if picked, otherwise existing remote image, else add button.
    if (_newImagePaths.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: Row(
          children: [
            _LocalImageTile(
              path: _newImagePaths.first,
              cs: cs,
              onRemove: () => setState(() => _newImagePaths = []),
            ),
          ],
        ),
      );
    }
    if (_existingImageUrls.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: Row(
          children: [
            _RemoteImageTile(
              url: _existingImageUrls.first,
              cs: cs,
              onRemove: () => setState(() => _existingImageUrls = []),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CV Preview Card
// Shows the existing CV filename, a copy-URL action, and an inline preview
// note — without requiring url_launcher.
// ─────────────────────────────────────────────────────────────────────────────

class _CvPreviewCard extends StatelessWidget {
  final String cvUrl;
  final ColorScheme cs;
  final dynamic s; // AppStrings

  const _CvPreviewCard({
    required this.cvUrl,
    required this.cs,
    required this.s,
  });

  String get _fileName {
    final parts = cvUrl.split('/');
    return parts.isNotEmpty ? parts.last : cvUrl;
  }

  bool get _isImage {
    final ext = cvUrl.toLowerCase().split('.').last.split('?').first;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  void _showPreviewDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding:
            const EdgeInsets.fromLTRB(16, 16, 16, 8),
        title: Row(
          children: [
            Icon(Icons.description_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'CV Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview if it's an image file
            if (_isImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  cvUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: cs.outline, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // File name
            Text(
              _fileName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // URL (truncated)
            Text(
              cvUrl,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Copy URL chip
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: cvUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded,
                        size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Copy link',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPreviewDialog(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isImage
                    ? Icons.image_rounded
                    : Icons.picture_as_pdf_rounded,
                color: cs.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current CV',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fileName,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to preview',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.visibility_rounded,
                color: cs.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image picker sub-widgets (shared with edit_listing_screen pattern)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface));
  }
}

class _RemoteImageTile extends StatelessWidget {
  final String url;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _RemoteImageTile(
      {required this.url, required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedImageWidget(
            imageUrl: url,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 120,
              height: 120,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded,
                  color: cs.outline, size: 28),
            ),
          ),
        ),
        _RemoveButton(cs: cs, onRemove: onRemove),
      ],
    );
  }
}

class _LocalImageTile extends StatelessWidget {
  final String path;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _LocalImageTile(
      {required this.path, required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              height: 120,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded,
                  color: cs.outline, size: 28),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('New',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary)),
          ),
        ),
        _RemoveButton(cs: cs, onRemove: onRemove),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _RemoveButton({required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          decoration:
              BoxDecoration(color: cs.error, shape: BoxShape.circle),
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 14, color: cs.onError),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onTap;
  final String? label;
  const _AddTile({required this.cs, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: label != null ? 160 : 120,
        height: 120,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 28, color: cs.primary),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(label!,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
