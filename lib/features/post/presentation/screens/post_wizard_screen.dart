import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/services/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PostWizardScreen
//
// Covers three marketplace categories: CARS, HOUSES, LAND (3 steps each).
// SKILLS is NOT a marketplace listing — it is a Service profile. Selecting
// "Professional Service" on Step 1 immediately redirects the user to
// ServiceManagementScreen with an explanation, instead of continuing the wizard.
// ─────────────────────────────────────────────────────────────────────────────

class PostWizardScreen extends StatefulWidget {
  const PostWizardScreen({super.key});

  @override
  State<PostWizardScreen> createState() => _PostWizardScreenState();
}

class _PostWizardScreenState extends State<PostWizardScreen> {
  final _formKey = GlobalKey<FormState>();

  // Total steps for marketplace listings (CARS / HOUSES / LAND)
  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      KoolanAppStateScope.of(context).resetWizard();
    });
  }

  void _onNext(KoolanAppState state) {
    // If SKILLS is selected, redirect instead of advancing the wizard.
    if (state.postCategory == 'SKILLS') {
      _redirectToServiceManagement(state);
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      if (state.postStep < _totalSteps) {
        setState(() => state.postStep++);
      } else {
        state.submitPost();
      }
    }
  }

  void _redirectToServiceManagement(KoolanAppState state) {
    // Pop the wizard first, then push service management so Back works cleanly.
    state.popScreen();
    state.pushScreen(ServiceManagementScreenRoute());
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSkills = state.postCategory == 'SKILLS';

    return Scaffold(
      backgroundColor: cs.surface,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _WizardHeader(
              state: state,
              totalSteps: _totalSteps,
              isSkills: isSkills,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _buildStep(state, cs),
              ),
            ),
            _WizardFooter(
              state: state,
              isSkills: isSkills,
              totalSteps: _totalSteps,
              onNext: () => _onNext(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(KoolanAppState state, ColorScheme cs) {
    switch (state.postStep) {
      case 1:
        return _Step1Category(
          state: state,
          onRebuild: () => setState(() {}),
        );
      case 2:
        return _Step2Details(state: state);
      case 3:
        return _Step3Finalize(
          state: state,
          onRebuild: () => setState(() {}),
        );
      default:
        return _Step1Category(
          state: state,
          onRebuild: () => setState(() {}),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header + progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  final KoolanAppState state;
  final int totalSteps;
  final bool isSkills;
  const _WizardHeader({
    required this.state,
    required this.totalSteps,
    required this.isSkills,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Safe area top
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: cs.primary),
                onPressed: () {
                  if (state.postStep > 1) {
                    state.postStep--;
                  } else {
                    state.popScreen();
                  }
                },
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
              // Step indicator — hidden when SKILLS selected (no steps apply)
              if (!isSkills)
                Text(
                  '${state.postStep} / $totalSteps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (!isSkills) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: state.postStep / totalSteps,
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer CTA
// ─────────────────────────────────────────────────────────────────────────────

class _WizardFooter extends StatelessWidget {
  final KoolanAppState state;
  final bool isSkills;
  final int totalSteps;
  final VoidCallback onNext;
  const _WizardFooter({
    required this.state,
    required this.isSkills,
    required this.totalSteps,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = state.postStep == totalSteps;

    final label = isSkills
        ? 'Go to My Services'
        : isLastStep
            ? state.s.wizardSubmit
            : state.s.wizardNext;

    final icon = isSkills
        ? Icons.arrow_forward_rounded
        : isLastStep
            ? Icons.check_rounded
            : Icons.arrow_forward_rounded;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: FilledButton.icon(
        onPressed: onNext,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Category picker
// ─────────────────────────────────────────────────────────────────────────────

class _Step1Category extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _Step1Category({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;

    // SKILLS card is rendered differently — it explains the redirect.
    final cats = [
      (s.wizardCatCarsTitle,   s.wizardCatCarsDesc,   Icons.directions_car_rounded, 'CARS'),
      (s.wizardCatHousesTitle, s.wizardCatHousesDesc, Icons.home_rounded,            'HOUSES'),
      (s.wizardCatLandTitle,   s.wizardCatLandDesc,   Icons.landscape_rounded,       'LAND'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          s.wizardStartPosting,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.wizardSelectType,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        // ── Marketplace listing options ───────────────────────────────────
        ...cats.map((c) {
          final (title, desc, icon, key) = c;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CategoryCard(
              title: title,
              desc: desc,
              icon: icon,
              catKey: key,
              isSelected: state.postCategory == key,
              isRedirect: false,
              onTap: () {
                state.postCategory = key;
                onRebuild();
              },
            ),
          );
        }),

        const SizedBox(height: 4),
        Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 12),

        // ── Skills / Professional Service — redirects to service mgmt ────
        _SkillsRedirectCard(state: state),

        const SizedBox(height: 8),
      ],
    );
  }
}

// Regular category selection card
class _CategoryCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final String catKey;
  final bool isSelected;
  final bool isRedirect;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.catKey,
    required this.isSelected,
    required this.isRedirect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.3)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isSelected ? cs.primary : cs.surfaceContainerHighest,
                child: Icon(
                  icon,
                  color: isSelected ? cs.onPrimary : cs.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Skills redirect card — explains that skills & job posts live on Profile,
// then navigates directly there on tap. No extra button needed.
class _SkillsRedirectCard extends StatelessWidget {
  final KoolanAppState state;
  const _SkillsRedirectCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        // Pop the wizard, then go straight to the Profile screen.
        state.popScreen();
        state.pushScreen(ProfileScreenRoute());
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.tertiary.withValues(alpha: 0.45)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cs.tertiaryContainer,
              child: Icon(Icons.person_rounded, color: cs.tertiary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with "Profile" badge
                  Row(
                    children: [
                      Text(
                        'Post Your Skill or Job',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cs.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Clear two-line description
                  Text(
                    'Your skills (services) and job posts are managed from your Profile — not here. Tap to go to your Profile and add them.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Pill hints showing what's available on Profile
                  Wrap(
                    spacing: 6,
                    children: [
                      _MiniPill(
                        icon: Icons.construction_rounded,
                        label: 'Add a Service',
                        cs: cs,
                      ),
                      _MiniPill(
                        icon: Icons.work_outline,
                        label: 'Post a Job',
                        cs: cs,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: cs.tertiary),
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
  const _MiniPill({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.tertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
// Step 2 — Details (title, price, location)
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Details extends StatelessWidget {
  final KoolanAppState state;
  const _Step2Details({required this.state});

  static ({String titleHint, String priceLabel, String priceHint}) _hints(
      String cat, AppStrings s) =>
      switch (cat) {
        'CARS' => (
            titleHint: s.wizardCarsTitleHint,
            priceLabel: s.wizardCarsPriceLabel,
            priceHint: s.wizardCarsPriceHint,
          ),
        'HOUSES' => (
            titleHint: s.wizardHousesTitleHint,
            priceLabel: s.wizardHousesPriceLabel,
            priceHint: s.wizardHousesPriceHint,
          ),
        _ => (
            titleHint: s.wizardLandTitleHint,
            priceLabel: s.wizardLandPriceLabel,
            priceHint: s.wizardLandPriceHint,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    final h = _hints(state.postCategory, s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          s.wizardDetailsTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(s.wizardDetailsSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        _WizardField(
          label: s.wizardTitleLabel,
          initial: state.postTitle,
          hint: h.titleHint,
          onChanged: (v) => state.postTitle = v,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? s.wizardTitleRequired : null,
        ),
        const SizedBox(height: 16),
        _WizardField(
          label: h.priceLabel,
          initial: state.postPrice,
          hint: h.priceHint,
          onChanged: (v) => state.postPrice = v,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? s.wizardPriceRequired : null,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Text(
          s.wizardLocationZone,
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: state.postLocation,
          dropdownColor: cs.surfaceContainerHighest,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          items: [
            'Kebele 01',
            'Kebele 02',
            'Kebele 03',
            'Kebele 04',
            'Kebele 05',
            'Kebele 06',
          ]
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) => state.postLocation = v ?? 'Kebele 06',
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Finalize (description + photo)
//
// NOTE: Specs are auto-filled from category defaults in submitPost().
// We skip the old "Specs" step because users rarely fill them accurately
// mid-post; they can be edited later from My Listings.
// ─────────────────────────────────────────────────────────────────────────────

class _Step3Finalize extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _Step3Finalize({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          s.wizardFinalizeTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(s.wizardFinalizeSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        Text(s.wizardDescriptionLabel,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: state.postDescription,
          onChanged: (v) => state.postDescription = v,
          maxLines: 4,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: s.wizardDescriptionHint,
            hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Photo attachment tile
        InkWell(
          onTap: () {
            state.postMainPhotoAttached = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.wizardPhotoMock)),
            );
            onRebuild();
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: state.postMainPhotoAttached
                  ? cs.tertiaryContainer.withValues(alpha: 0.3)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: state.postMainPhotoAttached
                    ? cs.tertiary.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: state.postMainPhotoAttached ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  state.postMainPhotoAttached
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_outlined,
                  size: 44,
                  color: state.postMainPhotoAttached
                      ? cs.tertiary
                      : cs.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  state.postMainPhotoAttached
                      ? s.wizardAttached
                      : s.wizardAttachMedia,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.wizardMediaHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared form field widget
// ─────────────────────────────────────────────────────────────────────────────

class _WizardField extends StatelessWidget {
  final String label;
  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _WizardField({
    required this.label,
    required this.initial,
    required this.hint,
    required this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
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
