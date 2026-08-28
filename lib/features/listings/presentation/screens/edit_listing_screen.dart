import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';

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

  // Selected category (CARS / HOUSES / LAND / OTHERS).
  String _category = 'CARS';

  // Condition/status and spec values — all editable.
  String _condition = '';
  String _spec1 = '';
  String _spec2 = '';
  String _spec3 = '';
  String _spec4 = '';

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

    final state = OnemarketAppStateScope.of(context);
    _listing = state.getListingById(widget.listingId);
    if (_listing == null) return;

    _titleCtrl.text = _listing!.title;
    // Strip leading "ETB " for editing convenience.
    _priceCtrl.text =
        _listing!.price.replaceFirst(RegExp(r'^ETB\s*'), '').trim();
    _descCtrl.text = _listing!.description;
    _locationCtrl.text = _listing!.location;
    _category = _listing!.category;
    _condition = _listing!.conditionOrStatus;
    _spec1 = _listing!.spec1Value ?? '';
    _spec2 = _listing!.spec2Value ?? '';
    _spec3 = _listing!.spec3Value ?? '';
    _spec4 = _listing!.spec4Value ?? '';
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
      setState(() => _uploadError = ErrorMapper.userMessage(e, OnemarketAppStateScope.of(context).s));
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

    final state = OnemarketAppStateScope.of(context);
    setState(() => _isSaving = true);

    try {
      await state.updateListing(
        listing: _listing!,
        title: _titleCtrl.text,
        price: _priceCtrl.text,
        description: _descCtrl.text,
        location: _locationCtrl.text,
        category: _category,
        conditionOrStatus: _condition,
        spec1Value: _spec1,
        spec2Value: _spec2,
        spec3Value: _spec3,
        spec4Value: _spec4,
        newImagePaths: _newPaths,
        existingImageUrls: _existingUrls,
      );
      if (!mounted) return;
      state.popScreen();
    } catch (e) {
      setState(() => _uploadError = ErrorMapper.userMessage(e, OnemarketAppStateScope.of(context).s));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
          title: Text(state.s.editListingTitle),
          backgroundColor: cs.surface,
          elevation: 0,
        ),
        body: Center(child: Text(state.s.listingNotFound)),
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
        title: Text(
          state.s.editListingTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
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

            // ── Category ───────────────────────────────────────────────────
            _SectionLabel(label: 'Category', cs: cs),
            const SizedBox(height: 8),
            _buildCategoryPicker(cs),
            const SizedBox(height: 20),

            // ── Condition / Status ─────────────────────────────────────────
            // Only shown for CARS / HOUSES / LAND; OTHERS skips fixed options.
            if (_category == 'CARS' ||
                _category == 'HOUSES' ||
                _category == 'LAND') ...[
              _EditDropdownOrOther(
                label: 'Condition / Status',
                currentValue: _condition.isEmpty ? null : _condition,
                options: _conditionLabels(_category),
                optionKeys: _conditionKeys(_category),
                otherLabel: 'Other…',
                otherHint: 'Describe the condition',
                onChanged: (v) => setState(() => _condition = v),
              ),
              const SizedBox(height: 16),
            ],

            // ── Specs (1–4) ────────────────────────────────────────────────
            // Shown for all marketplace categories; free-text for OTHERS.
            ..._buildSpecFields(cs),

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
              hint: 'e.g. Kebele 03, Dire Dawa',
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

  // ── Category picker ─────────────────────────────────────────────────────────

  static const _catKeys = ['CARS', 'HOUSES', 'LAND', 'OTHERS'];

  // ── Condition helpers ────────────────────────────────────────────────────────

  List<String> _conditionKeys(String cat) => switch (cat) {
        'CARS' => [
            'cond_car_new',
            'cond_car_used',
            'cond_car_fair',
            'cond_car_parts'
          ],
        'HOUSES' => [
            'cond_house_rent',
            'cond_house_sale',
            'cond_house_new',
            'cond_house_reno'
          ],
        _ => [
            'cond_land_available',
            'cond_land_title',
            'cond_land_nego'
          ],
      };

  List<String> _conditionLabels(String cat) {
    final s = OnemarketAppStateScope.of(context).s;
    return switch (cat) {
      'CARS' => [
          s.wizardCondCarNew,
          s.wizardCondCarUsed,
          s.wizardCondCarFair,
          s.wizardCondCarParts,
        ],
      'HOUSES' => [
          s.wizardCondHouseForRent,
          s.wizardCondHouseForSale,
          s.wizardCondHouseNewBuild,
          s.wizardCondHouseRenovated,
        ],
      _ => [
          s.wizardCondLandAvailable,
          s.wizardCondLandTitleReady,
          s.wizardCondLandNegotiable,
        ],
    };
  }

  // ── Spec helpers ─────────────────────────────────────────────────────────────

  List<Widget> _buildSpecFields(ColorScheme cs) {
    final s = OnemarketAppStateScope.of(context).s;
    final specs = _specConfig(_category, s);
    final values = [_spec1, _spec2, _spec3, _spec4];
    final setters = [
      (String v) => setState(() => _spec1 = v),
      (String v) => setState(() => _spec2 = v),
      (String v) => setState(() => _spec3 = v),
      (String v) => setState(() => _spec4 = v),
    ];

    final widgets = <Widget>[];
    for (int i = 0; i < specs.length; i++) {
      final spec = specs[i];
      if (spec.keys.isEmpty) {
        // Free-text spec (OTHERS category)
        widgets.add(_EditFreeTextField(
          label: spec.label,
          initialValue: values[i],
          hint: 'Enter value (optional)',
          onChanged: setters[i],
          cs: cs,
        ));
      } else {
        widgets.add(_EditDropdownOrOther(
          label: spec.label,
          currentValue: values[i].isEmpty ? null : values[i],
          options: spec.labels,
          optionKeys: spec.keys,
          otherLabel: 'Other…',
          otherHint: 'Enter value',
          onChanged: setters[i],
        ));
      }
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  List<_SpecDef> _specConfig(String cat, dynamic s) {
    return switch (cat) {
      'CARS' => [
          _SpecDef(
            label: s.wizardCarsSpec1Label,
            keys: [
              '2024', '2023', '2022', '2021', '2020', '2019', '2018',
              '2017', '2016', '2015', '2014', '2013', '2012', '2010',
              '2008', '2005', '2000'
            ],
            labels: [
              '2024', '2023', '2022', '2021', '2020', '2019', '2018',
              '2017', '2016', '2015', '2014', '2013', '2012', '2010',
              '2008', '2005', '2000'
            ],
          ),
          _SpecDef(
            label: s.wizardCarsSpec2Label,
            keys: [
              'mileage_under10k',
              'mileage_10k_50k',
              'mileage_50k_150k',
              'mileage_over150k'
            ],
            labels: [
              s.wizardCarsMileage1,
              s.wizardCarsMileage2,
              s.wizardCarsMileage3,
              s.wizardCarsMileage4,
            ],
          ),
          _SpecDef(
            label: s.wizardCarsSpec3Label,
            keys: ['tx_automatic', 'tx_manual', 'tx_cvt', 'tx_awd'],
            labels: [
              s.wizardCarsTxAutomatic,
              s.wizardCarsTxManual,
              s.wizardCarsTxCVT,
              s.wizardCarsTxAWD,
            ],
          ),
          _SpecDef(
            label: s.wizardCarsSpec4Label,
            keys: [
              'fuel_petrol',
              'fuel_diesel',
              'fuel_hybrid',
              'fuel_electric',
              'fuel_gas'
            ],
            labels: [
              s.wizardCarsFuelPetrol,
              s.wizardCarsFuelDiesel,
              s.wizardCarsFuelHybrid,
              s.wizardCarsFuelElectric,
              s.wizardCarsFuelGas,
            ],
          ),
        ],
      'HOUSES' => [
          _SpecDef(
            label: s.wizardHousesSpec1Label,
            keys: ['bed_1', 'bed_2', 'bed_3', 'bed_4', 'bed_5plus'],
            labels: [
              s.wizardHousesBed1,
              s.wizardHousesBed2,
              s.wizardHousesBed3,
              s.wizardHousesBed4,
              s.wizardHousesBed5,
            ],
          ),
          _SpecDef(
            label: s.wizardHousesSpec2Label,
            keys: ['bath_1', 'bath_2', 'bath_3plus'],
            labels: [
              s.wizardHousesBath1,
              s.wizardHousesBath2,
              s.wizardHousesBath3,
            ],
          ),
          _SpecDef(
            label: s.wizardHousesSpec3Label,
            keys: ['area_small', 'area_medium', 'area_large', 'area_xlarge'],
            labels: [
              s.wizardHousesArea1,
              s.wizardHousesArea2,
              s.wizardHousesArea3,
              s.wizardHousesArea4,
            ],
          ),
          _SpecDef(
            label: s.wizardHousesSpec4Label,
            keys: ['sec_low', 'sec_medium', 'sec_high', 'sec_gated'],
            labels: [
              s.wizardHousesSec1,
              s.wizardHousesSec2,
              s.wizardHousesSec3,
              s.wizardHousesSec4,
            ],
          ),
        ],
      'OTHERS' => [
          _SpecDef(label: s.wizardOthersSpec1Label, keys: [], labels: []),
          _SpecDef(label: s.wizardOthersSpec2Label, keys: [], labels: []),
          _SpecDef(label: s.wizardOthersSpec3Label, keys: [], labels: []),
          _SpecDef(label: s.wizardOthersSpec4Label, keys: [], labels: []),
        ],
      _ => [
          _SpecDef(
            label: s.wizardLandSpec1Label,
            keys: [
              'land_size_small',
              'land_size_medium',
              'land_size_large',
              'land_size_xlarge'
            ],
            labels: [
              s.wizardLandSize1,
              s.wizardLandSize2,
              s.wizardLandSize3,
              s.wizardLandSize4,
            ],
          ),
          _SpecDef(
            label: s.wizardLandSpec2Label,
            keys: [
              'land_use_res',
              'land_use_comm',
              'land_use_agri',
              'land_use_mixed'
            ],
            labels: [
              s.wizardLandUse1,
              s.wizardLandUse2,
              s.wizardLandUse3,
              s.wizardLandUse4,
            ],
          ),
          _SpecDef(
            label: s.wizardLandSpec3Label,
            keys: ['deed_full', 'deed_partial', 'deed_none'],
            labels: [
              s.wizardLandDeed1,
              s.wizardLandDeed2,
              s.wizardLandDeed3,
            ],
          ),
          _SpecDef(
            label: s.wizardLandSpec4Label,
            keys: ['road_paved', 'road_gravel', 'road_none'],
            labels: [
              s.wizardLandRoad1,
              s.wizardLandRoad2,
              s.wizardLandRoad3,
            ],
          ),
        ],
    };
  }

  Widget _buildCategoryPicker(ColorScheme cs) {
    final icons = {
      'CARS': Icons.directions_car_rounded,
      'HOUSES': Icons.home_rounded,
      'LAND': Icons.landscape_rounded,
      'OTHERS': Icons.category_outlined,
    };
    final s = OnemarketAppStateScope.of(context).s;
    final labels = {
      'CARS': s.wizardCatCarsTitle,
      'HOUSES': s.wizardCatHousesTitle,
      'LAND': s.wizardCatLandTitle,
      'OTHERS': s.wizardCatOthersTitle,
    };

    return Row(
      children: _catKeys.map((key) {
        final selected = _category == key;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: key != _catKeys.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _category = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primaryContainer.withValues(alpha: 0.35)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.5),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[key]!,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[key]!,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Image row ───────────────────────────────────────────────────────────────

  Widget _buildImagesRow(ColorScheme cs) {    final totalCount = _totalImageCount;
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
    String? labelOverride,
    ValueChanged<String>? onChanged,
  }) {
    final field = TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      onChanged: onChanged,
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

    if (labelOverride != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labelOverride,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          field,
        ],
      );
    }
    return field;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
