import 'package:flutter/material.dart';
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
                Text('Step ${state.postStep} of 4',
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

  static const _cats = [
    ('Professional Service', 'Post a skilled worker profile.', Icons.construction, 'SKILLS'),
    ('Vehicles / Cars', 'Sell or rent cars, motorbikes, machinery.', Icons.directions_car, 'CARS'),
    ('Real Estate / Houses', 'List houses, apartments, villas.', Icons.home, 'HOUSES'),
    ('Land / Plots', 'Sell or lease farming fields or commercial sites.', Icons.landscape, 'LAND'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Start posting',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text(
        'Select what type of ad you\'d like to list in Jigjiga.',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 24),
      ..._cats.map((c) {
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
      String cat) {
    return switch (cat) {
      'CARS' => (
          titleHint: 'e.g. 2022 Toyota Land Cruiser Prado',
          priceLabel: 'Asking Price',
          priceHint: 'e.g. ETB 2,800,000 or \$42,500',
        ),
      'HOUSES' => (
          titleHint: 'e.g. Modern 4-Bedroom Villa in Kebele 04',
          priceLabel: 'Price / Rent',
          priceHint: 'e.g. ETB 145,000 or \$450 /mo',
        ),
      'LAND' => (
          titleHint: 'e.g. Residential Plot in Kebele 02',
          priceLabel: 'Asking Price',
          priceHint: 'e.g. ETB 4,200,000',
        ),
      _ => (
          // SKILLS
          titleHint: 'e.g. Hodan Ahmed – Professional Housekeeper',
          priceLabel: 'Rate / Fee',
          priceHint: 'e.g. \$45 /hr  or  Unlock for 30 ETB',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final h = _hints(state.postCategory);
    final catLabel = switch (state.postCategory) {
      'CARS' => 'vehicle',
      'HOUSES' => 'property',
      'LAND' => 'land plot',
      _ => 'service',
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Details & Title',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text('Describe your $catLabel with a clear title and pricing.',
          style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 24),
      _field(
        state.postCategory == 'SKILLS' ? 'Your Name / Title' : 'Title',
        state.postTitle,
        h.titleHint,
        (v) => state.postTitle = v,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Title is required' : null,
      ),
      const SizedBox(height: 16),
      _field(
        h.priceLabel,
        state.postPrice,
        h.priceHint,
        (v) => state.postPrice = v,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Price is required' : null,
      ),
      const SizedBox(height: 16),
      Text('Location Zone',
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
      Text('Specifications',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text('Provide specs for ${cat.toLowerCase()}.',
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
      Text('Finalize Post',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text('Write a detailed description and attach media.',
          style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 24),
      Text('Description',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: state.postDescription,
        onChanged: (v) => state.postDescription = v,
        maxLines: 4,
        style: TextStyle(color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Briefly explain condition, location merits…',
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
              const SnackBar(
                  content: Text('Mock photo attached successfully!')),
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
                      ? '1 file attached'
                      : 'Attach media files',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text('JPG, PNG, MP4 up to 50MB',
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
