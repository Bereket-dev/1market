part of '../service_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Delete confirmation helper
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _confirmDeleteService(
  BuildContext context,
  OnemarketAppState state,
  String serviceId,
  dynamic s,
) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.servicesDeleteButton),
      content: Text(s.servicesDeleteConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.servicesDeleteCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: Text(s.servicesDeleteConfirmButton),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await state.deleteService(serviceId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon + text pill action button
// ─────────────────────────────────────────────────────────────────────────────

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
