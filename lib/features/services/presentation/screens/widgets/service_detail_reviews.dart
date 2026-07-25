part of '../service_detail_screen.dart';

// ── Inline reviews section — loads, displays and submits in place ─────────────

class _InlineReviewsSection extends StatefulWidget {
  final String serviceId;
  const _InlineReviewsSection({required this.serviceId});

  @override
  State<_InlineReviewsSection> createState() => _InlineReviewsSectionState();
}

class _InlineReviewsSectionState extends State<_InlineReviewsSection> {
  bool _loading = true;
  bool _submitting = false;
  bool _showForm = false;
  String? _submitError;
  String? _successMessage;
  bool _initialized = false;

  int _rating = 5;
  final _commentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = KoolanAppStateScope.of(context);
    // Serve cached reviews instantly — no spinner if we already have data.
    if (state.getReviewsForService(widget.serviceId).isNotEmpty) {
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = KoolanAppStateScope.of(context);
    await state.loadReviewsForService(widget.serviceId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = KoolanAppStateScope.of(context);

    // Auth gate: submitting a review requires sign-in.
    if (!state.isSignedIn) {
      showAuthGateSheet(context, reason: AuthGateReason.generic);
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
      _successMessage = null;
    });
    try {
      await state.submitReview(
        serviceId: widget.serviceId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _successMessage = state.s.reviewsThankYou;
        _commentCtrl.clear();
        _rating = 5;
        _showForm = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final reviews = state.getReviewsForService(widget.serviceId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ───────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                s.reviewsTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: cs.onSurface,
                ),
              ),
            ),
            // Toggle write-review form
            TextButton.icon(
              icon: Icon(
                _showForm
                    ? Icons.close_rounded
                    : Icons.rate_review_outlined,
                size: 16,
              ),
              label: Text(
                _showForm ? s.commonCancel : s.reviewsSubmitTitle,
              ),
              onPressed: () {
                setState(() {
                  _showForm = !_showForm;
                  _submitError = null;
                  _successMessage = null;
                });
              },
            ),
          ],
        ),

        // ── Success banner ───────────────────────────────────────────────
        if (_successMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style:
                        TextStyle(color: cs.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Write-review form ────────────────────────────────────────────
        if (_showForm) ...[
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Star picker
                Row(
                  children: [
                    Icon(Icons.star_outline,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(s.reviewsRatingLabel,
                        style:
                            TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    _StarPicker(
                      value: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Comment field
                TextFormField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: s.reviewsCommentLabel,
                    hintText: s.reviewsCommentHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? s.reviewsCommentRequired
                          : null,
                ),
                const SizedBox(height: 10),
                // Submit
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Text(s.reviewsSubmitButton),
                  ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _submitError!,
                    style:
                        TextStyle(color: cs.error, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Reviews list ─────────────────────────────────────────────────
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              s.reviewsEmpty,
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          )
        else
          ...reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(review: r),
              )),
      ],
    );
  }
}

// ── Star picker ───────────────────────────────────────────────────────────────

class _StarPicker extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const _StarPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              star <= value ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 28,
              semanticLabel: '$star stars',
            ),
          ),
        );
      }),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ServiceReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    final name = review.reviewerName ?? s.reviewsFallbackUserName;

    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        cs.primaryContainer.withValues(alpha: 0.4),
                    backgroundImage: review.reviewerAvatarUrl != null
                        ? NetworkImage(review.reviewerAvatarUrl!)
                        : null,
                    child: review.reviewerAvatarUrl == null
                        ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: cs.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        _ago(review.createdAt, s),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ]),
                RatingStars(
                  rating: review.rating.toDouble(),
                  reviewCount: null,
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt, s) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return s.reviewsTimeAgoYears(diff.inDays ~/ 365);
    if (diff.inDays >= 30) return s.reviewsTimeAgoMonths(diff.inDays ~/ 30);
    if (diff.inDays >= 1) return s.reviewsTimeAgoDays(diff.inDays);
    if (diff.inHours >= 1) return s.reviewsTimeAgoHours(diff.inHours);
    return s.reviewsTimeAgoJustNow;
  }
}
