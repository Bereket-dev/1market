part of '../post_wizard_screen.dart';

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

