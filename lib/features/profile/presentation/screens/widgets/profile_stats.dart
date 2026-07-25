part of '../profile_screen.dart';

// ── Stat cell widget ──────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final String? sub;

  const _StatCell({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      if (icon != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: iconColor ?? cs.primary, size: 16),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface)),
        ])
      else
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface)),
      Text(sub ?? label,
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
    ]);
  }
}

