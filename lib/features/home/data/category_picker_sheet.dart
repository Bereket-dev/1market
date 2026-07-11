import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class _PickerOption {
  final String label;
  final IconData icon;
  final String key;
  const _PickerOption(this.label, this.icon, this.key);
}

/// Bottom sheet for choosing a listing category before entering the post wizard.
class CategoryPickerSheet extends StatelessWidget {
  final void Function(String category) onSelect;

  const CategoryPickerSheet({super.key, required this.onSelect});

  static const _options = [
    _PickerOption('Cars', Icons.directions_car, 'CARS'),
    _PickerOption('Houses', Icons.home, 'HOUSES'),
    _PickerOption('Land', Icons.landscape, 'LAND'),
    _PickerOption('Skills', Icons.construction, 'SKILLS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kOutlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'What would you like to post?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final opt = _options[index];
              return Card(
                color: kSurfaceContainerLow,
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
                        backgroundColor: kPrimary.withOpacity(0.1),
                        child: Icon(opt.icon, color: kPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opt.label,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kOnSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
