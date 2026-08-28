part of '../post_wizard_screen.dart';

class _BasicInfoSection extends StatelessWidget {
  final OnemarketAppState state;
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
  final OnemarketAppState state;
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
  final OnemarketAppState state;
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
  final OnemarketAppState state;
  final VoidCallback onRebuild;
  const _LocationSection({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final kebeleKeys = [
      'Kebele 01',
      'Kebele 02',
      'Kebele 03',
      'Kebele 04',
      'Kebele 05',
      'Kebele 06',
      'Kebele 07',
      'Kebele 08',
      'Kebele 09',
    ];
    final kebeleLabels = [
      s.wizardLocationKebele01,
      s.wizardLocationKebele02,
      s.wizardLocationKebele03,
      s.wizardLocationKebele04,
      s.wizardLocationKebele05,
      s.wizardLocationKebele06,
      s.wizardLocationKebele07,
      s.wizardLocationKebele08,
      s.wizardLocationKebele09,
    ];

    final cityValue = OnemarketCities.resolve(state.postCity);
    final cityItems = <String>[
      ...OnemarketCities.all,
      if (!OnemarketCities.all
          .any((c) => c.toLowerCase() == cityValue.toLowerCase()))
        cityValue,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          label: s.wizardCityLabel,
          isRequired: true,
          requiredSuffix: s.wizardRequired,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(cityValue),
          initialValue: cityValue,
          decoration: InputDecoration(
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
          ),
          items: [
            for (final city in cityItems)
              DropdownMenuItem(value: city, child: Text(city)),
          ],
          onChanged: (v) {
            if (v == null) return;
            state.postCity = v;
            onRebuild();
          },
        ),
        const SizedBox(height: 16),
        _DropdownOrOther(
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Specifications (4 dropdowns with Other, per category)
// ─────────────────────────────────────────────────────────────────────────────

