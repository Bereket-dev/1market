import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
part 'widgets/edit_listing_widgets.dart';
part 'widgets/edit_listing_form.dart';

/// Screen for editing an existing listing's fields and images.
///
/// - Editable fields: title, price, description, location.
/// - Image management: view existing images, remove any, pick new ones (up to 8 total).
/// - On save: uploads new images to Cloudinary then patches Supabase.
class EditListingScreen extends StatefulWidget {
  final String listingId;
  const EditListingScreen({super.key, required this.listingId});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;

  // URLs already stored in Supabase (can be removed).
  late List<String> _existingUrls;

  // Local file paths newly picked by the user.
  final List<String> _newPaths = [];

  bool _isSaving = false;
  String? _uploadError;
  Listing? _listing;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _existingUrls = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listing != null) return; // already initialised

    final state = KoolanAppStateScope.of(context);
    _listing = state.getListingById(widget.listingId);
    if (_listing == null) return;

    _titleCtrl.text = _listing!.title;
    // Strip leading "ETB " for editing convenience.
    _priceCtrl.text =
        _listing!.price.replaceFirst(RegExp(r'^ETB\s*'), '').trim();
    _descCtrl.text = _listing!.description;
    _locationCtrl.text = _listing!.location;
    // Prefer imageUrls list; fall back to imageUrl for older listings.
    _existingUrls = _listing!.imageUrls.isNotEmpty
        ? List<String>.from(_listing!.imageUrls)
        : _listing!.imageUrl.isNotEmpty
            ? [_listing!.imageUrl]
            : [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  int get _totalImageCount => _existingUrls.length + _newPaths.length;

  Future<void> _pickImages() async {
    final remaining = 8 - _totalImageCount;
    if (remaining <= 0) return;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );
    } catch (e) {
      setState(() => _uploadError = e.toString());
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final paths = result.files
        .take(remaining)
        .map((f) => f.path)
        .whereType<String>()
        .toList();

    setState(() {
      _newPaths.addAll(paths);
      _uploadError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_listing == null) return;

    final state = KoolanAppStateScope.of(context);
    setState(() => _isSaving = true);

    try {
      await state.updateListing(
        listing: _listing!,
        title: _titleCtrl.text,
        price: _priceCtrl.text,
        description: _descCtrl.text,
        location: _locationCtrl.text,
        newImagePaths: _newPaths,
        existingImageUrls: _existingUrls,
      );
      if (!mounted) return;
      state.popScreen();
    } catch (e) {
      setState(() => _uploadError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
          title: const Text('Edit Listing'),
          backgroundColor: cs.surface,
          elevation: 0,
        ),
        body: const Center(child: Text('Listing not found.')),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
        ),
        title: const Text(
          'Edit Listing',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.primary,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Images ─────────────────────────────────────────────────────
            _SectionLabel(label: 'Photos', cs: cs),
            const SizedBox(height: 8),
            _buildImagesRow(cs),
            if (_uploadError != null) ...[
              const SizedBox(height: 6),
              Text(_uploadError!,
                  style: TextStyle(fontSize: 12, color: cs.error)),
            ],
            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────────────────────
            _SectionLabel(label: 'Title', cs: cs),
            const SizedBox(height: 8),
            _buildField(
              controller: _titleCtrl,
              hint: 'e.g. Toyota Land Cruiser 2020',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              cs: cs,
            ),
            const SizedBox(height: 16),

            // ── Price ──────────────────────────────────────────────────────
            _SectionLabel(label: 'Price (ETB)', cs: cs),
            const SizedBox(height: 8),
            _buildField(
              controller: _priceCtrl,
              hint: 'e.g. 1500000',
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Price is required' : null,
              cs: cs,
            ),
            const SizedBox(height: 16),

            // ── Location ───────────────────────────────────────────────────
            _SectionLabel(label: 'Location', cs: cs),
            const SizedBox(height: 8),
            _buildField(
              controller: _locationCtrl,
              hint: 'e.g. Kebele 03, Jigjiga',
              cs: cs,
            ),
            const SizedBox(height: 16),

            // ── Description ────────────────────────────────────────────────
            _SectionLabel(label: 'Description', cs: cs),
            const SizedBox(height: 8),
            _buildField(
              controller: _descCtrl,
              hint: 'Describe your listing...',
              maxLines: 5,
              cs: cs,
            ),
            const SizedBox(height: 28),

            // ── Save button (also in app bar) ──────────────────────────────
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image row ───────────────────────────────────────────────────────────────

  Widget _buildImagesRow(ColorScheme cs) {
    final totalCount = _totalImageCount;
    final showAdd = totalCount < 8;

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing remote images
          for (int i = 0; i < _existingUrls.length; i++) ...[
            _RemoteImageTile(
              url: _existingUrls[i],
              cs: cs,
              onRemove: () => setState(() => _existingUrls.removeAt(i)),
            ),
            const SizedBox(width: 8),
          ],

          // New local images
          for (int i = 0; i < _newPaths.length; i++) ...[
            _LocalImageTile(
              path: _newPaths[i],
              cs: cs,
              onRemove: () => setState(() => _newPaths.removeAt(i)),
            ),
            const SizedBox(width: 8),
          ],

          // Add button
          if (showAdd)
            _AddTile(
              cs: cs,
              label: totalCount == 0 ? 'Add Photos' : null,
              onTap: _pickImages,
            ),
        ],
      ),
    );
  }

  // ── Shared text field ───────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required ColorScheme cs,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
