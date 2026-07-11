import 'package:flutter/material.dart';

class _PickerOption {
  final String label;
  final IconData icon;
  final String key;
  const _PickerOption(this.label, this.icon, this.key);
}

/// Bottom sheet for choosing a listing category before the post wizard.
class CategoryPickerSheet extends StatelessWidget {
  final void Function(String) onSelect;

  const CategoryPickerSheet({super.key, required this.onSelect});

  static const _options = [
    _PickerOption('Cars', Icons.directions_car, 'CARS'),
    _PickerOption('Houses', Icons.home, 'HOUSES'),
    _PickerOption('Land', Icons.landscape, 'LAND'),
    _PickerOption('Skills', Icons.construction, 'SKILLS'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        // Use surface so it adapts to dark/light automatically
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
            'What would you like to post?',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: cs.onSurface),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _options.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final opt = _options[index];
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
                      Text(opt.label,
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
            child: Text('Cancel',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
