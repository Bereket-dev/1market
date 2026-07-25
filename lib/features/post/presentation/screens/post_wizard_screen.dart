import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/phone_prompt.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
import '../../../../shared/models/syncable_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PostWizardScreen  —  single-screen consolidated listing form
//
// All eligible classification fields (category, condition/status, every spec)
// use a dropdown with a final "Other…" option that reveals a free-text field.
// Free-text fields (title, price, description) remain open TextFormFields.
//
// Marketplace categories: CARS, HOUSES, LAND.
// "Professional Service / Skill" → immediate redirect to ServiceManagementScreen
//   (no wizard steps apply).
// ─────────────────────────────────────────────────────────────────────────────

class PostWizardScreen extends StatefulWidget {
  const PostWizardScreen({super.key});

  @override
  State<PostWizardScreen> createState() => _PostWizardScreenState();
}

class _PostWizardScreenState extends State<PostWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      KoolanAppStateScope.of(context).resetWizard();
    });
  }

  Future<void> _onSubmit(KoolanAppState state) async {
    setState(() => _submitAttempted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Prompt for phone if profile doesn't have one yet.
    // Returns false only on barrier dismiss — abort in that case.
    final proceed = await showPhonePromptIfNeeded(context, state);
    if (!proceed) return;

    final listingId = await state.submitPost();
    if (!mounted) return;
    // Pop the wizard and open the newly created listing's detail screen.
    state.popScreen();
    state.pushScreen(ListingDetailScreenRoute(listingId));
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Form(
        key: _formKey,
        autovalidateMode: _submitAttempted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            _PostFormHeader(state: state, top: top),

            // ── Scrollable form body ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section 1: Basic Info ─────────────────────────────
                    _FormSection(
                      label: state.s.wizardSectionBasic,
                      required: true,
                      child: _BasicInfoSection(
                        state: state,
                        onRebuild: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 2: Location ───────────────────────────────
                    // Only shown once a marketplace category is picked
                    if (_isMarketplaceCat(state.postCategory)) ...[
                      _FormSection(
                        label: state.s.wizardSectionLocation,
                        required: true,
                        child: _LocationSection(
                          state: state,
                          onRebuild: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Section 3: Specifications ─────────────────────
                      _FormSection(
                        label: state.s.wizardSectionSpecs,
                        required: false,
                        child: _SpecsSection(
                          state: state,
                          onRebuild: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Section 4: Description ────────────────────────
                      _FormSection(
                        label: state.s.wizardSectionDescription,
                        required: false,
                        child: _DescriptionSection(state: state),
                      ),
                      const SizedBox(height: 20),

                      // ── Section 5: Photos ─────────────────────────────
                      _FormSection(
                        label: state.s.wizardSectionMedia,
                        required: false,
                        child: _PhotosSection(
                          state: state,
                          onRebuild: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Upload error ──────────────────────────────────────
                    if (state.listingImageUploadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          state.listingImageUploadError!,
                          style: TextStyle(
                              fontSize: 13, color: cs.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Submit footer ─────────────────────────────────────────────
            if (_isMarketplaceCat(state.postCategory))
              _SubmitFooter(
                state: state,
                bottom: bottom,
                onSubmit: () => _onSubmit(state),
              ),
          ],
        ),
      ),
    );
  }

  bool _isMarketplaceCat(String cat) =>
      cat == 'CARS' || cat == 'HOUSES' || cat == 'LAND' || cat == 'OTHERS';
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _PostFormHeader extends StatelessWidget {
  final KoolanAppState state;
  final double top;
  const _PostFormHeader({required this.state, required this.top});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(4, top + 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            tooltip: state.s.wizardBack,
            onPressed: () => state.popScreen(),
          ),
          Expanded(
            child: Text(
              state.s.wizardTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Sync status badge — shows draft/pending/synced state
          if (state.isUploadingListingImages)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SyncStatusBadge(status: SyncStatus.pending),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section wrapper — renders a titled card-like grouping
// ─────────────────────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const _FormSection({
    required this.label,
    required this.required,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // required indicator: use the AppStrings getter (goes through _t)
    final s = KoolanAppStateScope.of(context).s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 0.3,
              ),
            ),
            if (required)
              Text(
                s.wizardRequired,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DropdownOrOther
//
// A dropdown that shows a list of translated options plus a final "Other…"
// option. When "Other…" is selected the dropdown collapses and a TextFormField
// appears so the user can type a custom value.
//
// The [value] / [onChanged] pair track the *internal* state value — the caller
// stores it in AppState. When value equals [_otherSentinel] the free-text
// field is active.
// ─────────────────────────────────────────────────────────────────────────────

const String _otherSentinel = '__other__';

class _DropdownOrOther extends StatefulWidget {
  final String label;
  final bool isRequired;
  final String? currentValue;
  final List<String> options; // translated display strings
  final List<String> optionKeys; // internal keys (same length as options)
  final String otherLabel; // translated "Other…"
  final String otherHint; // translated placeholder for free-text
  final String? requiredError;
  final ValueChanged<String> onChanged;

  const _DropdownOrOther({
    required this.label,
    required this.isRequired,
    required this.currentValue,
    required this.options,
    required this.optionKeys,
    required this.otherLabel,
    required this.otherHint,
    required this.onChanged,
    this.requiredError,
  });

  @override
  State<_DropdownOrOther> createState() => _DropdownOrOtherState();
}

class _DropdownOrOtherState extends State<_DropdownOrOther> {
  late TextEditingController _otherCtrl;
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    // If the current value is not in the known option keys it was typed — restore
    final inOptions = widget.currentValue == null ||
        widget.optionKeys.contains(widget.currentValue);
    _isOther = !inOptions && widget.currentValue!.isNotEmpty;
    _otherCtrl = TextEditingController(text: _isOther ? widget.currentValue : '');
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;

    // Resolve the dropdown value: if _isOther use the sentinel, otherwise use
    // the currentValue if it's in the known keys (else null = no selection).
    String? dropdownValue;
    if (_isOther) {
      dropdownValue = _otherSentinel;
    } else if (widget.currentValue != null &&
        widget.optionKeys.contains(widget.currentValue)) {
      dropdownValue = widget.currentValue;
    }

    final allOptionKeys = [...widget.optionKeys, _otherSentinel];
    final allOptionLabels = [...widget.options, widget.otherLabel];

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        _FieldLabel(
          label: widget.label,
          isRequired: widget.isRequired,
          requiredSuffix: s.wizardRequired,
        ),
        const SizedBox(height: 8),

        // Dropdown
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          dropdownColor: cs.surfaceContainerHighest,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: inputDecoration,
          validator: widget.isRequired
              ? (v) {
                  if (v == null) return widget.requiredError;
                  if (v == _otherSentinel && _otherCtrl.text.trim().isEmpty) {
                    return widget.requiredError;
                  }
                  return null;
                }
              : null,
          items: List.generate(allOptionKeys.length, (i) {
            final key = allOptionKeys[i];
            final lbl = allOptionLabels[i];
            final isOtherItem = key == _otherSentinel;
            return DropdownMenuItem<String>(
              value: key,
              child: Text(
                lbl,
                style: TextStyle(
                  color: isOtherItem
                      ? cs.onSurfaceVariant
                      : cs.onSurface,
                  fontStyle: isOtherItem
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            );
          }),
          onChanged: (v) {
            if (v == _otherSentinel) {
              setState(() {
                _isOther = true;
                _otherCtrl.clear();
              });
              widget.onChanged('');
            } else if (v != null) {
              setState(() => _isOther = false);
              widget.onChanged(v);
            }
          },
        ),

        // "Other" free-text field — slides in when sentinel is selected
        if (_isOther) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _otherCtrl,
            autofocus: true,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: inputDecoration.copyWith(
              hintText: widget.otherHint,
              hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            validator: widget.isRequired
                ? (v) => (v == null || v.trim().isEmpty)
                    ? widget.requiredError
                    : null
                : null,
            onChanged: (v) => widget.onChanged(v),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FieldLabel — label + optional required asterisk
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String requiredSuffix;
  const _FieldLabel({
    required this.label,
    required this.isRequired,
    required this.requiredSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: cs.onSurface)),
        if (isRequired)
          Text(requiredSuffix,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cs.error)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TextInputField — reusable labelled TextFormField
// ─────────────────────────────────────────────────────────────────────────────

class _TextInputField extends StatelessWidget {
  final String label;
  final String initial;
  final String hint;
  final bool isRequired;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;

  const _TextInputField({
    required this.label,
    required this.initial,
    required this.hint,
    required this.isRequired,
    required this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          label: label,
          isRequired: isRequired,
          requiredSuffix: s.wizardRequired,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            filled: true,
            fillColor: cs.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1 — Basic Info
// Category dropdown + condition dropdown + title + price
// ─────────────────────────────────────────────────────────────────────────────

class _BasicInfoSection extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _BasicInfoSection({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final s = state.s;

    // ── Category: fixed known set (CARS / HOUSES / LAND) ─────────────────────
    // "Other" is not applicable for category — skills redirect is a separate card.
    // CARS / HOUSES / LAND / OTHERS (SKILLS has its own redirect card below)
    final catKeys = ['CARS', 'HOUSES', 'LAND', 'OTHERS'];
    final catLabels = [
      s.wizardCatCarsTitle,
      s.wizardCatHousesTitle,
      s.wizardCatLandTitle,
      s.wizardCatOthersTitle,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category picker ────────────────────────────────────────────────
        _CategoryPickerField(
          state: state,
          catKeys: catKeys,
          catLabels: catLabels,
          onChanged: (v) {
            state.postCategory = v;
            // Reset condition and specs when category changes
            state.postCondition = '';
            state.postSpec1 = '';
            state.postSpec2 = '';
            state.postSpec3 = '';
            state.postSpec4 = '';
            onRebuild();
          },
        ),

        // ── Skills redirect card ───────────────────────────────────────────
        const SizedBox(height: 12),
        _SkillsRedirectCard(state: state),

        // ── Condition/Status — CARS / HOUSES / LAND only (OTHERS skips fixed fields)
        if (state.postCategory == 'CARS' ||
            state.postCategory == 'HOUSES' ||
            state.postCategory == 'LAND') ...[
          const SizedBox(height: 16),
          _DropdownOrOther(
            label: s.wizardConditionLabel,
            isRequired: true,
            currentValue: state.postCondition.isEmpty ? null : state.postCondition,
            options: _conditionLabels(state.postCategory, s),
            optionKeys: _conditionKeys(state.postCategory),
            otherLabel: s.wizardOther,
            otherHint: s.wizardOtherHint,
            requiredError: s.wizardConditionRequired,
            onChanged: (v) {
              state.postCondition = v;
              onRebuild();
            },
          ),
        ],

        // ── Title + Price — all marketplace categories including OTHERS ────────
        if (state.postCategory == 'CARS' ||
            state.postCategory == 'HOUSES' ||
            state.postCategory == 'LAND' ||
            state.postCategory == 'OTHERS') ...[
          const SizedBox(height: 16),
          _TextInputField(
            label: s.wizardTitleLabel,
            initial: state.postTitle,
            hint: _titleHint(state.postCategory, s),
            isRequired: true,
            onChanged: (v) => state.postTitle = v,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? s.wizardTitleRequired
                : null,
          ),
          const SizedBox(height: 16),
          _TextInputField(
            label: _priceLabel(state.postCategory, s),
            initial: state.postPrice,
            hint: _priceHint(state.postCategory, s),
            isRequired: true,
            onChanged: (v) => state.postPrice = v,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? s.wizardPriceRequired
                : null,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  /// Stable internal keys for condition — language-independent, stored in app state.
  List<String> _conditionKeys(String cat) {
    return switch (cat) {
      'CARS' => ['cond_car_new', 'cond_car_used', 'cond_car_fair', 'cond_car_parts'],
      'HOUSES' => ['cond_house_rent', 'cond_house_sale', 'cond_house_new', 'cond_house_reno'],
      _ => ['cond_land_available', 'cond_land_title', 'cond_land_nego'],
    };
  }

  /// Translated display labels for condition — matches _conditionKeys order.
  List<String> _conditionLabels(String cat, AppStrings s) {
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

  String _titleHint(String cat, AppStrings s) => switch (cat) {
        'CARS' => s.wizardCarsTitleHint,
        'HOUSES' => s.wizardHousesTitleHint,
        'OTHERS' => s.wizardCatOthersTitle,
        _ => s.wizardLandTitleHint,
      };

  String _priceLabel(String cat, AppStrings s) => switch (cat) {
        'CARS' => s.wizardCarsPriceLabel,
        'HOUSES' => s.wizardHousesPriceLabel,
        'OTHERS' => s.wizardLandPriceLabel,
        _ => s.wizardLandPriceLabel,
      };

  String _priceHint(String cat, AppStrings s) => switch (cat) {
        'CARS' => s.wizardCarsPriceHint,
        'HOUSES' => s.wizardHousesPriceHint,
        'OTHERS' => s.wizardLandPriceHint,
        _ => s.wizardLandPriceHint,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Category picker field — inline radio-style cards (no "Other" for category)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerField extends StatelessWidget {
  final KoolanAppState state;
  final List<String> catKeys;
  final List<String> catLabels;
  final ValueChanged<String> onChanged;
  const _CategoryPickerField({
    required this.state,
    required this.catKeys,
    required this.catLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          label: s.wizardCategoryLabel,
          isRequired: true,
          requiredSuffix: s.wizardRequired,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(catKeys.length, (i) {
            final key = catKeys[i];
            final lbl = catLabels[i];
            final selected = state.postCategory == key;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < catKeys.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onChanged(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primaryContainer.withValues(alpha: 0.35)
                          : cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.5),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _catIcon(key),
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lbl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? cs.primary
                                : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  IconData _catIcon(String key) => switch (key) {
        'CARS' => Icons.directions_car_rounded,
        'HOUSES' => Icons.home_rounded,
        'LAND' => Icons.landscape_rounded,
        'OTHERS' => Icons.category_outlined,
        _ => Icons.landscape_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Skills redirect card — no wizard steps; taps through to Profile
// ─────────────────────────────────────────────────────────────────────────────

class _SkillsRedirectCard extends StatelessWidget {
  final KoolanAppState state;
  const _SkillsRedirectCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    return InkWell(
      onTap: () {
        state.popScreen();
        state.pushScreen(ProfileScreenRoute());
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.tertiary.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.tertiaryContainer,
              child: Icon(Icons.person_rounded, color: cs.tertiary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.wizardSkillsCardTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.wizardSkillsCardBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cs.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.wizardSkillsCardDesc,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _MiniPill(
                        icon: Icons.construction_rounded,
                        label: s.wizardSkillsAddService,
                        cs: cs,
                      ),
                      _MiniPill(
                        icon: Icons.work_outline,
                        label: s.wizardSkillsPostJob,
                        cs: cs,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: cs.tertiary),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  const _MiniPill(
      {required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: cs.tertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 2 — Location (dropdown + Other)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _LocationSection({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final kebeleKeys = [
      'Kebele 01',
      'Kebele 02',
      'Kebele 03',
      'Kebele 04',
      'Kebele 05',
      'Kebele 06',
    ];
    final kebeleLabels = [
      s.wizardLocationKebele01,
      s.wizardLocationKebele02,
      s.wizardLocationKebele03,
      s.wizardLocationKebele04,
      s.wizardLocationKebele05,
      s.wizardLocationKebele06,
    ];

    return _DropdownOrOther(
      label: s.wizardLocationLabel,
      isRequired: true,
      currentValue: state.postLocation,
      options: kebeleLabels,
      optionKeys: kebeleKeys,
      otherLabel: s.wizardOther,
      otherHint: s.wizardOtherHint,
      requiredError: s.wizardCategoryRequired,
      onChanged: (v) {
        state.postLocation = v.isEmpty ? 'Kebele 06' : v;
        onRebuild();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Specifications (4 dropdowns with Other, per category)
// ─────────────────────────────────────────────────────────────────────────────

class _SpecsSection extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _SpecsSection({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final cat = state.postCategory;

    final specs = _specConfig(cat, s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _DropdownOrOther(
            label: specs[i].label,
            isRequired: false,
            currentValue: _specValue(i),
            options: specs[i].labels,
            optionKeys: specs[i].keys, // stable internal keys, never translated
            otherLabel: s.wizardOther,
            otherHint: s.wizardOtherHint,
            onChanged: (v) {
              _setSpec(i, v);
              onRebuild();
            },
          ),
        ],
      ],
    );
  }

  String _specValue(int i) {
    return switch (i) {
      0 => state.postSpec1,
      1 => state.postSpec2,
      2 => state.postSpec3,
      _ => state.postSpec4,
    };
  }

  void _setSpec(int i, String v) {
    switch (i) {
      case 0:
        state.postSpec1 = v;
      case 1:
        state.postSpec2 = v;
      case 2:
        state.postSpec3 = v;
      default:
        state.postSpec4 = v;
    }
  }

  List<_SpecDef> _specConfig(String cat, AppStrings s) {
    return switch (cat) {
      'CARS' => [
          _SpecDef(
            label: s.wizardCarsSpec1Label,
            keys: [
              '2024', '2023', '2022', '2021', '2020',
              '2019', '2018', '2017', '2016', '2015',
              '2014', '2013', '2012', '2010', '2008',
              '2005', '2000',
            ],
            labels: [
              '2024', '2023', '2022', '2021', '2020',
              '2019', '2018', '2017', '2016', '2015',
              '2014', '2013', '2012', '2010', '2008',
              '2005', '2000',
            ],
          ),
          _SpecDef(
            label: s.wizardCarsSpec2Label,
            keys: ['mileage_under10k', 'mileage_10k_50k', 'mileage_50k_150k', 'mileage_over150k'],
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
            keys: ['fuel_petrol', 'fuel_diesel', 'fuel_hybrid', 'fuel_electric', 'fuel_gas'],
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
      // OTHERS: 4 optional free-text spec pairs — no preset options.
      'OTHERS' => [
          _SpecDef(label: s.wizardOthersSpec1Label, keys: [], labels: []),
          _SpecDef(label: s.wizardOthersSpec2Label, keys: [], labels: []),
          _SpecDef(label: s.wizardOthersSpec3Label, keys: [], labels: []),
          _SpecDef(label: s.wizardOthersSpec4Label, keys: [], labels: []),
        ],
      _ /* LAND and any future categories */ => [
          _SpecDef(
            label: s.wizardLandSpec1Label,
            keys: ['land_size_small', 'land_size_medium', 'land_size_large', 'land_size_xlarge'],
            labels: [
              s.wizardLandSize1,
              s.wizardLandSize2,
              s.wizardLandSize3,
              s.wizardLandSize4,
            ],
          ),
          _SpecDef(
            label: s.wizardLandSpec2Label,
            keys: ['land_use_res', 'land_use_comm', 'land_use_agri', 'land_use_mixed'],
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
}

class _SpecDef {
  final String label;
  final List<String> keys;   // stable internal keys (stored in app state)
  final List<String> labels; // translated display strings (same length as keys)
  const _SpecDef({required this.label, required this.keys, required this.labels});
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 4 — Description (free-text, optional)
// ─────────────────────────────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  final KoolanAppState state;
  const _DescriptionSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    return _TextInputField(
      label: s.wizardDescriptionLabel,
      initial: state.postDescription,
      hint: s.wizardDescriptionHint,
      isRequired: false,
      onChanged: (v) => state.postDescription = v,
      maxLines: 4,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 5 — Photos (up to 8 images)
// ─────────────────────────────────────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _PhotosSection({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    final paths = state.postImagePaths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Count indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel(
              label: s.wizardPhotosLabel,
              isRequired: false,
              requiredSuffix: s.wizardRequired,
            ),
            Text(
              '${paths.length}/8',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal thumbnail strip + add button
        if (paths.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: paths.length + (paths.length < 8 ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == paths.length) {
                  return _AddImageButton(
                    onTap: () async {
                      await state.pickListingImages(context);
                      onRebuild();
                    },
                    cs: cs,
                    label: s.wizardAttachMedia,
                  );
                }
                return _ImageThumbnail(
                  path: paths[index],
                  cs: cs,
                  onRemove: () {
                    state.removeListingImage(index);
                    onRebuild();
                  },
                );
              },
            ),
          ),

        // Full-width upload zone when no images yet
        if (paths.isEmpty)
          InkWell(
            onTap: () async {
              await state.pickListingImages(context);
              onRebuild();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 40, color: cs.primary),
                  const SizedBox(height: 8),
                  Text(
                    s.wizardAttachMedia,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.wizardMediaHint,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant
                            .withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String path;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _ImageThumbnail(
      {required this.path, required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: BoxDecoration(
                  color: cs.error, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 14, color: cs.onError),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  final String label;
  const _AddImageButton(
      {required this.onTap, required this.cs, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 28, color: cs.primary),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit footer — single CTA button + offline banner
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitFooter extends StatelessWidget {
  final KoolanAppState state;
  final double bottom;
  final VoidCallback onSubmit;
  const _SubmitFooter({
    required this.state,
    required this.bottom,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    final isUploading = state.isUploadingListingImages;

    return Container(
      color: cs.surface,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Offline warning banner
          _OfflineBanner(state: state),

          const SizedBox(height: 8),

          // Submit button
          FilledButton.icon(
            onPressed: isUploading ? null : onSubmit,
            icon: isUploading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.onPrimary,
                    ),
                  )
                : Icon(Icons.check_rounded),
            label: Text(
              s.wizardSubmit,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline banner — shown when device is offline
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final KoolanAppState state;
  const _OfflineBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;

    // dataError is set by submitPost on network failure;
    // show the offline message so the user knows the draft will sync later.
    if (state.dataError == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.wizardOfflineBanner,
              style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
