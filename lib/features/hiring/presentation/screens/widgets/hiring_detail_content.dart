part of '../hiring_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Content widgets for HiringDetailScreen body
// ─────────────────────────────────────────────────────────────────────────────

/// Title + open/closed status badge row.
class _PostTitleRow extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final bool isOpen;

  const _PostTitleRow({
    required this.title,
    required this.category,
    required this.description,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: cs.onSurface),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOpen
                    ? cs.primaryContainer.withValues(alpha: 0.3)
                    : cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle,
                      size: 8, color: isOpen ? cs.primary : cs.error),
                  const SizedBox(width: 4),
                  Text(
                    isOpen ? s.hiringStatusOpen : s.hiringStatusClosed,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOpen ? cs.primary : cs.error),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(category,
            style: TextStyle(
                fontSize: 14,
                color: cs.primary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Text(description,
            style:
                TextStyle(fontSize: 15, color: cs.onSurface, height: 1.5)),
      ],
    );
  }
}
