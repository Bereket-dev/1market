import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/models/syncable_entity.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/cv_upload_service.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/cv_upload_button.dart';
import '../../../../shared/widgets/cv_viewer.dart';
import '../../../../shared/widgets/phone_prompt.dart';
part 'widgets/service_edit_widgets.dart';
part 'widgets/service_edit_form.dart';

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

    final state = OnemarketAppStateScope.of(context);
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
      setState(() => _imageError = ErrorMapper.userMessage(e, OnemarketAppStateScope.of(context).s));
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
    final state = OnemarketAppStateScope.of(context);
    final currentUser = state.currentUser;
    if (currentUser == null) return;

    // Prompt for phone when creating a new service and profile has none yet.
    // Skip the prompt when editing — the phone was already collected earlier.
    if (widget.serviceId == null) {
      final proceed = await showPhonePromptIfNeeded(context, state);
      if (!proceed) return;
    }

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
      final resolvedId = await state.submitServiceEdit(
        service,
        newImagePaths: _newImagePaths,
        existingImageUrls: _existingImageUrls,
      );
      if (!mounted) return;
      if (widget.serviceId == null) {
        // New service — pop the edit screen then open the detail screen.
        state.popScreen();
        state.pushScreen(ServiceDetailScreenRoute(resolvedId));
      } else {
        // Edit — just go back.
        state.popScreen();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final state = OnemarketAppStateScope.of(context);
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
            // Use ctx — not the outer context — so the colorScheme lookup
            // stays within the dialog's own element and doesn't touch a
            // screen element that may already be deactivated.
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
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
    final state = OnemarketAppStateScope.of(context);
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
              _SectionLabel(label: s.coverPhotoLabel, cs: cs),
              const SizedBox(height: 8),
              _buildImagePicker(cs, s.addCoverPhotoLabel),
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

  Widget _buildImagePicker(ColorScheme cs, String addCoverLabel) {
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
          _AddTile(cs: cs, label: addCoverLabel, onTap: _pickImage),
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
