import 'package:flutter/material.dart';
import '../../../shared/models/app_strings.dart';
import '../../../shared/services/app_state.dart';

class _PickerOption {
  final String Function(AppStrings) label;
  final IconData icon;
  final String key;
  const _PickerOption(this.label, this.icon, this.key);
}

/// Bottom sheet for choosing a listing category before the post wizard.
class CategoryPickerSheet extends StatelessWidget {
  final void Function(String) onSelect;

  const CategoryPickerSheet({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    final options = [
      _PickerOption((s) => s.homeCategoryCars, Icons.directions_car, 'CARS'),
      _PickerOption((s) => s.homeCategoryHouses, Icons.home, 'HOUSES'),
      _PickerOption((s) => s.homeCategoryLand, Icons.landscape, 'LAND'),
      _PickerOption((s) => s.homeCategorySkills, Icons.construction, 'SKILLS'),
      _PickerOption((s) => s.homeCategoryOthers, Icons.category_outlined, 'OTHERS'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.pickerTitle,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: cs.onSurface),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final opt = options[index];
              return Card(
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: InkWell(
                  onTap: () => onSelect(opt.key),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            cs.primaryContainer.withValues(alpha: 0.3),
                        child: Icon(opt.icon, color: cs.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(opt.label(s),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.pickerCancel,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
