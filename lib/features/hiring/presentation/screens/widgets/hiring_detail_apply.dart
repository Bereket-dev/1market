part of '../hiring_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Detail row and apply section sub-widgets for HiringDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Apply section ─────────────────────────────────────────────────────────────
// Renders either the "already applied" confirmation badge or the apply button
// with optional error banner.

class _ApplySection extends StatelessWidget {
  final bool alreadyApplied;
  final bool applying;
  final String? applyError;
  final bool postIsOpen;
  final VoidCallback onApply;

  const _ApplySection({
    required this.alreadyApplied,
    required this.applying,
    required this.applyError,
    required this.postIsOpen,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    if (alreadyApplied) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.hiringAlreadyApplied,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (applyError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    applyError!,
                    style: TextStyle(color: cs.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          icon: applying
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: Text(s.hiringApplyButton),
          onPressed: (applying || !postIsOpen) ? null : onApply,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}
