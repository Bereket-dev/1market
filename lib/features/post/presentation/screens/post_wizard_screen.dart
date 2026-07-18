import 'package:flutter/material.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/services/app_state.dart';

class PostWizardScreen extends StatefulWidget {
  const PostWizardScreen({super.key});

  @override
  State<PostWizardScreen> createState() => _PostWizardScreenState();
}

class _PostWizardScreenState extends State<PostWizardScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      KoolanAppStateScope.of(context).resetWizard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(children: [
          // ── Top header ──────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: cs.primary),
                  onPressed: () {
                    if (state.postStep > 1) {
                      setState(() => state.postStep--);
                    } else {
                      state.popScreen();
                    }
                  },
                ),
                Text(state.s.wizardTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                Text(
                    state.s.wizardStepOf.replaceAll(
                        '{step}', '${state.postStep}'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant)),
              ],
            ),
          ),

          // ── Progress bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LinearProgressIndicator(
              value: state.postStep / 4.0,
              color: cs.primary,
              backgroundColor: cs.surfaceContainerHighest,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),

          // ── Step content ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStep(state, cs),
            ),
          ),

          // ── CTA ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  if (state.postStep < 4) {
                    setState(() => state.postStep++);
                  } else {
                    state.submitPost();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                state.postStep == 4
                    ? state.s.wizardSubmit
                    : state.s.wizardNext,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep(KoolanAppState state, ColorScheme cs) {
    switch (state.postStep) {
      case 1:
        return _Step1(state: state, cs: cs, onRebuild: () => setState(() {}));
      case 2:
        return _Step2(state: state, cs: cs);
      case 3:
        return _Step3(state: state, cs: cs);
      default:
        return _Step4(state: state, cs: cs, onRebuild: () => setState(() {}));
    }
  }
}

// ── Step 1 — Category ─────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  final VoidCallback onRebuild;
  const _Step1(
      {required this.state, required this.cs, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final cats = [
      (s.wizardCatSkillsTitle, s.wizardCatSkillsDesc, Icons.construction, 'SKILLS'),
      (s.wizardCatCarsTitle,   s.wizardCatCarsDesc,   Icons.directions_car, 'CARS'),
      (s.wizardCatHousesTitle, s.wizardCatHousesDesc, Icons.home,           'HOUSES'),
      (s.wizardCatLandTitle,   s.wizardCatLandDesc,   Icons.landscape,      'LAND'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.wizardStartPosting,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text(
        s.wizardSelectType,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 24),
      ...cats.map((c) {
        final (title, desc, icon, key) = c;
        final sel = state.postCategory == key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CategoryCard(
            title: title,
            desc: desc,
            icon: icon,
            isSelected: sel,
            cs: cs,
            onTap: () {
              state.postCategory = key;
              onRebuild();
            },
          ),
        );
      }),
    ]);
  }
}

class _CategoryCard extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isSelected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.3)
          : cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(
              backgroundColor:
                  isSelected ? cs.primary : cs.surfaceContainerHighest,
              child: Icon(icon,
                  color: isSelected ? cs.onPrimary : cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ]),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: cs.primary, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Step 2 — Details ──────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  const _Step2({required this.state, required this.cs});

  // Returns (titleHint, priceHint, priceLabel) per category
  static ({String titleHint, String priceLabel, String priceHint}) _hints(
      String cat, AppStrings strings) {
    return switch (cat) {
      'CARS' => (
          titleHint: strings.wizardCarsTitleHint,
          priceLabel: strings.wizardCarsPriceLabel,
          priceHint: strings.wizardCarsPriceHint,
        ),
      'HOUSES' => (
          titleHint: strings.wizardHousesTitleHint,
          priceLabel: strings.wizardHousesPriceLabel,
          priceHint: strings.wizardHousesPriceHint,
        ),
      'LAND' => (
          titleHint: strings.wizardLandTitleHint,
          priceLabel: strings.wizardLandPriceLabel,
          priceHint: strings.wizardLandPriceHint,
        ),
      _ => (
          // SKILLS
          titleHint: strings.wizardSkillsTitleHint,
          priceLabel: strings.wizardSkillsPriceLabel,
          priceHint: strings.wizardSkillsPriceHint,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final h = _hints(state.postCategory, state.s);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(state.s.wizardDetailsTitle,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text(state.s.wizardDetailsSubtitle,
          style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 24),
      _field(
        state.postCategory == 'SKILLS' ? state.s.wizardNameTitleLabel : state.s.wizardTitleLabel,
        state.postTitle,
        h.titleHint,
        (v) => state.postTitle = v,
        validator: (v) =>
            v == null || v.trim().isEmpty ? state.s.wizardTitleRequired : null,
      ),
      const SizedBox(height: 16),
      _field(
        h.priceLabel,
        state.postPrice,
        h.priceHint,
        (v) => state.postPrice = v,
        validator: (v) =>
            v == null || v.trim().isEmpty ? state.s.wizardPriceRequired : null,
      ),
      const SizedBox(height: 16),
      Text(state.s.wizardLocationZone,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: state.postLocation,
        dropdownColor: cs.surfaceContainerHighest,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        items: ['Kebele 01', 'Kebele 02', 'Kebele 03', 'Kebele 04',
                'Kebele 05', 'Kebele 06']
            .map((k) => DropdownMenuItem(value: k, child: Text(k)))
            .toList(),
        onChanged: (v) => state.postLocation = v ?? 'Kebele 06',
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.6))),
        ),
      ),
    ]);
  }
}

// ── Step 3 — Specs ────────────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  const _Step3({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    final cat = state.postCategory;
    final fields = _fieldsFor(cat);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(state.s.wizardSpecsTitle,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text(state.s.wizardSpecsSubtitle,
          style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 24),
      ...fields.asMap().entries.expand((e) {
        final (label, hint, setter) = e.value;
        final initial = _specValue(state, e.key);
        return [
          _field(label, initial, hint, setter),
          const SizedBox(height: 16),
        ];
      }),
    ]);
  }

  List<(String, String, void Function(String))> _fieldsFor(String cat) =>
      switch (cat) {
        'CARS' => [
            ('Year', 'e.g. 2022', (v) => state.postSpec1 = v),
            ('Mileage', 'e.g. 12,000 km', (v) => state.postSpec2 = v),
            ('Transmission', 'Automatic / Manual', (v) => state.postSpec3 = v),
            ('Fuel Type', 'Petrol / Diesel', (v) => state.postSpec4 = v),
          ],
        'HOUSES' => [
            ('Bedrooms', 'e.g. 4 Bed', (v) => state.postSpec1 = v),
            ('Bathrooms', 'e.g. 3 Bath', (v) => state.postSpec2 = v),
            ('Area size', 'e.g. 350 m²', (v) => state.postSpec3 = v),
            ('Security', 'e.g. 24/7', (v) => state.postSpec4 = v),
          ],
        'LAND' => [
            ('Plot Size', 'e.g. 1000 sqm', (v) => state.postSpec1 = v),
            ('Land Use', 'Residential / Agricultural', (v) => state.postSpec2 = v),
            ('Title Deed', 'Available / Pending', (v) => state.postSpec3 = v),
            ('Road Access', 'Yes / No', (v) => state.postSpec4 = v),
          ],
        _ => [
            ('Service category', 'e.g. Electrician', (v) => state.postSpec1 = v),
            ('Years experience', 'e.g. 5 years', (v) => state.postSpec2 = v),
            ('Key skills', 'e.g. Wiring, Repairs', (v) => state.postSpec3 = v),
            ('ID Verification', 'Yes / Pending', (v) => state.postSpec4 = v),
          ],
      };

  String _specValue(KoolanAppState s, int i) => switch (i) {
        0 => s.postSpec1,
        1 => s.postSpec2,
        2 => s.postSpec3,
        _ => s.postSpec4,
      };
}

// ── Step 4 — Finalize ─────────────────────────────────────────────────────────

class _Step4 extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  final VoidCallback onRebuild;
  const _Step4(
      {required this.state, required this.cs, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(state.s.wizardFinalizeTitle,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text(state.s.wizardFinalizeSubtitle,
          style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 24),
      Text(state.s.wizardDescriptionLabel,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: state.postDescription,
        onChanged: (v) => state.postDescription = v,
        maxLines: 4,
        style: TextStyle(color: cs.onSurface),
        decoration: InputDecoration(
          hintText: state.s.wizardDescriptionHint,
          hintStyle: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5))),
        ),
      ),
      const SizedBox(height: 24),

      // Photo attachment tile
      Card(
        color: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        elevation: 0,
        child: InkWell(
          onTap: () {
            state.postMainPhotoAttached = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.s.wizardPhotoMock)),
            );
            onRebuild();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(children: [
                Icon(
                  state.postMainPhotoAttached
                      ? Icons.check_circle
                      : Icons.cloud_upload_outlined,
                  size: 48,
                  color: state.postMainPhotoAttached
                      ? cs.tertiary
                      : cs.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  state.postMainPhotoAttached
                      ? state.s.wizardAttached
                      : state.s.wizardAttachMedia,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(state.s.wizardMediaHint,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            cs.onSurfaceVariant.withValues(alpha: 0.6))),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Shared field builder ──────────────────────────────────────────────────────

Widget _field(
  String label,
  String initial,
  String hint,
  void Function(String) onChanged, {
  String? Function(String?)? validator,
}) {
  return Builder(builder: (context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(color: cs.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2)),
        ),
      ),
    ]);
  });
}
