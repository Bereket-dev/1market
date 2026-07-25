import 'package:flutter/material.dart';

import '../../../../core/widgets/rating_stars.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
part 'widgets/service_reviews_widgets.dart';
part 'widgets/service_reviews_form.dart';

/// Displays reviews for a service and allows the current user to submit one.
///
/// TODO (Phase C Part 2): Gate review submission on a completed HiringApplication
/// for this service. For Part 1, any authenticated user can leave a review.
/// Once the HiringApplications table is introduced, add a check:
///   final canReview = await repo.hasCompletedEngagement(serviceId, userId);
///   if (!canReview) show "Complete a job first" message.
class ServiceReviewsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceReviewsScreen({super.key, required this.serviceId});

  @override
  State<ServiceReviewsScreen> createState() => _ServiceReviewsScreenState();
}

class _ServiceReviewsScreenState extends State<ServiceReviewsScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _submitError;
  String? _successMessage;
  bool _initialized = false;

  // Submit form state
  int _rating = 5;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = KoolanAppStateScope.of(context);
    // Serve from cache immediately — no spinner if we already have data.
    if (state.getReviewsForService(widget.serviceId).isNotEmpty) {
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final state = KoolanAppStateScope.of(context);
    await state.loadReviewsForService(widget.serviceId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = KoolanAppStateScope.of(context);

    // Auth gate: review submission requires sign-in.
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
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _successMessage = state.s.reviewsThankYou;
        _commentController.clear();
        _rating = 5;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final reviews = state.getReviewsForService(widget.serviceId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.reviewsTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Phase C Part 2 gating note ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      // TODO (Phase C Part 2): Replace with gating check
                      s.reviewsAnonymousHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Submit form ────────────────────────────────────────────────
            Text(
              s.reviewsSubmitTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Star rating picker — labelled ──────────────────────
                  Row(
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.reviewsRatingLabel,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      _StarPicker(
                        value: _rating,
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── Comment ────────────────────────────────────────────
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: s.reviewsCommentLabel,
                      hintText: s.reviewsCommentHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? s.reviewsCommentRequired : null,
                  ),
                  const SizedBox(height: 12),
                  // ── Submit button ─────────────────────────────────────
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(s.reviewsSubmitButton),
                  ),
                  if (_successMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _successMessage!,
                      style: TextStyle(color: cs.primary),
                    ),
                  ],
                  if (_submitError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _submitError!,
                      style: TextStyle(color: cs.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            // ── Reviews list ───────────────────────────────────────────────
            Text(
              s.reviewsTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (reviews.isEmpty)
              Text(
                s.reviewsEmpty,
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              ...reviews.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(review: r),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Star picker — never icon-only ─────────────────────────────────────────────
