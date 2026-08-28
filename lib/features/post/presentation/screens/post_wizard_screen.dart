import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/onemarket_cities.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/phone_prompt.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
import '../../../../shared/models/syncable_entity.dart';
part 'widgets/post_wizard_specs.dart';
part 'widgets/post_wizard_media.dart';
part 'widgets/post_wizard_header.dart';
part 'widgets/post_wizard_fields.dart';
part 'widgets/post_wizard_basic_info.dart';

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
      OnemarketAppStateScope.of(context).resetWizard();
    });
  }

  Future<void> _onSubmit(OnemarketAppState state) async {
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
    final state = OnemarketAppStateScope.of(context);
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
