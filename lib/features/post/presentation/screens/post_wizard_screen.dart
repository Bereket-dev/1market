import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
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

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Top header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kPrimary),
                    onPressed: () {
                      if (state.postStep > 1) {
                        setState(() => state.postStep--);
                      } else {
                        state.popScreen();
                      }
                    },
                  ),
                  Text(
                    state.s.wizardTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Step ${state.postStep} of 4',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: kOnSurfaceVariant),
                  ),
                ],
              ),
            ),

            // ── Progress bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: state.postStep / 4.0,
                color: kPrimary,
                backgroundColor: kSurfaceContainerHigh,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),

            // ── Step content ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStepContent(state),
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────────────────
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
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  state.postStep == 4
                      ? state.s.wizardSubmit
                      : state.s.wizardNext,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(KoolanAppState state) {
    switch (state.postStep) {
      case 1:
        return _Step1Category(state: state, onRebuild: () => setState(() {}));
      case 2:
        return _Step2Details(state: state);
      case 3:
        return _Step3Specs(state: state, onRebuild: () => setState(() {}));
      default:
        return _Step4Finalize(state: state, onRebuild: () => setState(() {}));
    }
  }
}

// ── Step 1 — Category ─────────────────────────────────────────────────────────

class _Step1Category extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;

  const _Step1Category({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Start posting',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select what type of classified ad or worker profile you\'d like '
          'to list in Jigjiga.',
          style: TextStyle(color: kOnSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _CategorySelectionCard(
          title: 'Professional Service',
          desc: 'Post a skilled worker profile with verified bio and credentials.',
          icon: Icons.construction,
          isSelected: state.postCategory == 'SKILLS',
          onTap: () {
            state.postCategory = 'SKILLS';
            onRebuild();
          },
        ),
        const SizedBox(height: 16),
        _CategorySelectionCard(
          title: 'Vehicles / Cars',
          desc: 'Sell or rent out cars, motorbikes, or heavy machinery.',
          icon: Icons.directions_car,
          isSelected: state.postCategory == 'CARS',
          onTap: () {
            state.postCategory = 'CARS';
            onRebuild();
          },
        ),
        const SizedBox(height: 16),
        _CategorySelectionCard(
          title: 'Real Estate / Houses',
          desc: 'List houses, apartments, villas, or hotel rooms.',
          icon: Icons.home,
          isSelected: state.postCategory == 'HOUSES',
          onTap: () {
            state.postCategory = 'HOUSES';
            onRebuild();
          },
        ),
        const SizedBox(height: 16),
        _CategorySelectionCard(
          title: 'Land / Plots',
          desc: 'Sell or lease farming fields, residential plots, or commercial sites.',
          icon: Icons.landscape,
          isSelected: state.postCategory == 'LAND',
          onTap: () {
            state.postCategory = 'LAND';
            onRebuild();
          },
        ),
      ],
    );
  }
}

class _CategorySelectionCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategorySelectionCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isSelected ? kPrimary.withOpacity(0.05) : kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? kPrimary : kOutlineVariant.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isSelected ? kPrimary : kSurfaceContainerHigh,
                child: Icon(icon,
                    color: isSelected ? Colors.white : kPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                          fontSize: 12, color: kOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2 — Details ─────────────────────────────────────────────────────────

class _Step2Details extends StatelessWidget {
  final KoolanAppState state;
  const _Step2Details({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details & Title',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Provide a title and pricing details for your ad.',
          style: TextStyle(color: kOnSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _wizardField(
          label: 'Title',
          initial: state.postTitle,
          hint: 'e.g. Toyota Hilux 2021 Raider',
          onChanged: (v) => state.postTitle = v,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 16),
        _wizardField(
          label: 'Price / Rate',
          initial: state.postPrice,
          hint: 'e.g. 4,500,000 or 15,000 /mo',
          onChanged: (v) => state.postPrice = v,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Price is required' : null,
        ),
        const SizedBox(height: 16),
        const Text('Location Zone',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: state.postLocation,
          items: ['Kebele 01', 'Kebele 02', 'Kebele 03',
                  'Kebele 04', 'Kebele 05', 'Kebele 06']
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (val) => state.postLocation = val ?? 'Kebele 06',
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ── Step 3 — Specifications ───────────────────────────────────────────────────

class _Step3Specs extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _Step3Specs({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final cat = state.postCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide specifications specific to ${cat.toLowerCase()}.',
          style: const TextStyle(color: kOnSurfaceVariant),
        ),
        const SizedBox(height: 24),
        if (cat == 'CARS') ...[
          _wizardField(label: 'Year', initial: state.postSpec1,
              hint: 'e.g. 2022', onChanged: (v) => state.postSpec1 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Mileage', initial: state.postSpec2,
              hint: 'e.g. 12,000 km', onChanged: (v) => state.postSpec2 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Transmission', initial: state.postSpec3,
              hint: 'Automatic / Manual', onChanged: (v) => state.postSpec3 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Fuel Type', initial: state.postSpec4,
              hint: 'Petrol / Diesel', onChanged: (v) => state.postSpec4 = v),
        ] else if (cat == 'HOUSES') ...[
          _wizardField(label: 'Bedrooms', initial: state.postSpec1,
              hint: 'e.g. 4 Bed', onChanged: (v) => state.postSpec1 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Bathrooms', initial: state.postSpec2,
              hint: 'e.g. 3 Bath', onChanged: (v) => state.postSpec2 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Area size', initial: state.postSpec3,
              hint: 'e.g. 350 m²', onChanged: (v) => state.postSpec3 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Security', initial: state.postSpec4,
              hint: 'e.g. 24/7', onChanged: (v) => state.postSpec4 = v),
        ] else if (cat == 'LAND') ...[
          _wizardField(label: 'Plot Size', initial: state.postSpec1,
              hint: 'e.g. 1000 sqm', onChanged: (v) => state.postSpec1 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Land Use', initial: state.postSpec2,
              hint: 'Residential / Agricultural', onChanged: (v) => state.postSpec2 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Title Deed status', initial: state.postSpec3,
              hint: 'Available / Pending', onChanged: (v) => state.postSpec3 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Road Access', initial: state.postSpec4,
              hint: 'Yes / No', onChanged: (v) => state.postSpec4 = v),
        ] else ...[
          _wizardField(label: 'Service category', initial: state.postSpec1,
              hint: 'e.g. Electrician', onChanged: (v) => state.postSpec1 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Years of experience', initial: state.postSpec2,
              hint: 'e.g. 5 years', onChanged: (v) => state.postSpec2 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'Key skills specialty', initial: state.postSpec3,
              hint: 'e.g. Wiring, Repairs', onChanged: (v) => state.postSpec3 = v),
          const SizedBox(height: 16),
          _wizardField(label: 'ID Verification status', initial: state.postSpec4,
              hint: 'Yes / Pending', onChanged: (v) => state.postSpec4 = v),
        ],
      ],
    );
  }
}

// ── Step 4 — Finalize ─────────────────────────────────────────────────────────

class _Step4Finalize extends StatelessWidget {
  final KoolanAppState state;
  final VoidCallback onRebuild;
  const _Step4Finalize({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Finalize Post',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Write a detailed description and attach media files.',
          style: TextStyle(color: kOnSurfaceVariant),
        ),
        const SizedBox(height: 24),

        // Description
        const Text('Description',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: state.postDescription,
          onChanged: (v) => state.postDescription = v,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Briefly explain condition, location merits, and escrow preferences...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        // Photo attachment
        Card(
          color: kSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: kOutlineVariant.withValues(alpha: 0.4),
                style: BorderStyle.solid),
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
                child: Column(
                  children: [
                    Icon(
                      state.postMainPhotoAttached
                          ? Icons.check_circle
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: state.postMainPhotoAttached
                          ? kVerifiedColor
                          : kPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.postMainPhotoAttached
                          ? '1 file attached'
                          : 'Attach media files',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG, MP4 up to 50MB',
                      style: TextStyle(
                          fontSize: 12,
                          color: kOnSurfaceVariant.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared field builder ──────────────────────────────────────────────────────

Widget _wizardField({
  required String label,
  required String initial,
  required String hint,
  required void Function(String) onChanged,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );
}
