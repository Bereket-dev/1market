part of '../service_reviews_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Review submit form for ServiceReviewsScreen
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewSubmitForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final int rating;
  final TextEditingController commentController;
  final bool submitting;
  final String? successMessage;
  final String? submitError;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _ReviewSubmitForm({
    required this.formKey,
    required this.rating,
    required this.commentController,
    required this.submitting,
    required this.successMessage,
    required this.submitError,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Phase C Part 2 gating note ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.reviewsAnonymousHint,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(s.reviewsSubmitTitle,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface)),
          const SizedBox(height: 12),

          // Star rating picker
          Row(
            children: [
              Icon(Icons.star_outline,
                  size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(s.reviewsRatingLabel,
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(width: 12),
              _StarPicker(
                  value: rating, onChanged: onRatingChanged),
            ],
          ),
          const SizedBox(height: 12),

          // Comment
          TextFormField(
            controller: commentController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: s.reviewsCommentLabel,
              hintText: s.reviewsCommentHint,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? s.reviewsCommentRequired
                : null,
          ),
          const SizedBox(height: 12),

          // Submit button
          FilledButton(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(s.reviewsSubmitButton),
          ),

          if (successMessage != null) ...[
            const SizedBox(height: 8),
            Text(successMessage!,
                style: TextStyle(color: cs.primary)),
          ],
          if (submitError != null) ...[
            const SizedBox(height: 8),
            Text(submitError!,
                style: TextStyle(color: cs.error, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
