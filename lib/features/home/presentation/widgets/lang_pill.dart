import 'package:flutter/material.dart';

/// One segment inside the EN / አማ / SO language toggle pill.
class LangPillSegment extends StatelessWidget {
  final String label;
  final bool isActive;

  const LangPillSegment({
    super.key,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
