part of '../hiring_applicant_detail_screen.dart';

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final ApplicationStatus status;
  final bool chatLoading;
  final String acceptLabel;
  final String rejectLabel;
  final String backToReviewLabel;
  final String chatLabel;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onBackToReview;
  final VoidCallback onChat;

  const _ActionButtons({
    required this.status,
    required this.chatLoading,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.backToReviewLabel,
    required this.chatLabel,
    required this.onAccept,
    required this.onReject,
    required this.onBackToReview,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Accept / Reject / Back-to-review row
        if (status == ApplicationStatus.rejected) ...[
          // Only "Back to Review" when rejected
          OutlinedButton.icon(
            onPressed: onBackToReview,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(backToReviewLabel),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: cs.tertiary),
              foregroundColor: cs.tertiary,
            ),
          ),
        ] else if (status == ApplicationStatus.accepted) ...[
          // Already accepted — only show "Back to review" as an undo
          OutlinedButton.icon(
            onPressed: onBackToReview,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(backToReviewLabel),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: cs.outline),
            ),
          ),
        ] else ...[
          // submitted or reviewed — show Accept + Reject
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(acceptLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(rejectLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        // Chat button — always visible
        FilledButton.tonalIcon(
          onPressed: chatLoading ? null : onChat,
          icon: chatLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onSecondaryContainer,
                  ),
                )
              : const Icon(Icons.chat_bubble_outline, size: 18),
          label: Text(chatLabel),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

// ── Placeholder card (when service not in local cache) ────────────────────────

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
