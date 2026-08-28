import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';

import '../../../../core/widgets/rating_stars.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
part 'widgets/service_reviews_widgets.dart';
part 'widgets/service_reviews_form.dart';

/// Displays reviews for a service and allows eligible hirers to submit one.
///
/// Review submission requires an accepted application for this service on a
/// hiring post owned by the current user.
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
  bool _canReview = false;
  bool _isOwnService = false;

  // Submit form state
  int _rating = 5;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = OnemarketAppStateScope.of(context);
    // Serve from cache immediately — no spinner if we already have data.
    if (state.getReviewsForService(widget.serviceId).isNotEmpty) {
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final state = OnemarketAppStateScope.of(context);
    final service = state.getServiceById(widget.serviceId);
    final isOwn = service != null &&
        state.currentUser?.id != null &&
        service.ownerId == state.currentUser!.id;
    final canReview = !isOwn && await state.canReviewService(widget.serviceId);
    await state.loadReviewsForService(widget.serviceId);
    if (mounted) {
      setState(() {
        _loading = false;
        _canReview = canReview;
        _isOwnService = isOwn;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = OnemarketAppStateScope.of(context);

    // Auth gate: review submission requires sign-in.
    if (!state.isSignedIn) {
      showAuthGateSheet(context, reason: AuthGateReason.generic);
      return;
    }
    if (!_canReview) {
      setState(() => _submitError = state.s.reviewsGatingNote);
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
      setState(() => _submitError = ErrorMapper.userMessage(e, OnemarketAppStateScope.of(context).s));
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
    final state = OnemarketAppStateScope.of(context);
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
            if (_isOwnService)
              _ReviewGateBanner(message: s.reviewsOwnServiceHint, cs: cs)
            else if (!_canReview)
              _ReviewGateBanner(message: s.reviewsGatingNote, cs: cs)
            else ...[
              // ── Submit form (eligible hirers only) ─────────────────────
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.reviewsCommentRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
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
            ],
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

class _ReviewGateBanner extends StatelessWidget {
  final String message;
  final ColorScheme cs;
  const _ReviewGateBanner({required this.message, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              message,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Star picker — never icon-only ─────────────────────────────────────────────
