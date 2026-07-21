import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/similar_section.dart';

/// Read-only detail view for a service.
///
/// Shows all fields before any further action.
/// Full apply/hiring linkage is Phase C Part 2 — see TODO comment below.
class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Record this view for the interaction penalty in recommendations.
    KoolanAppStateScope.of(context).recordItemViewed(widget.serviceId);
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final service = state.getServiceById(widget.serviceId);

    if (service == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
            tooltip: s.wizardBack,
          ),
          title: Text(s.servicesDetailTitle),
        ),
        body: Center(
          child: Text(
            s.listingNotFound,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ─────────────────────────────────────────
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: service.imageUrl.isNotEmpty
                      ? CachedImageWidget(
                          imageUrl: service.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 260,
                          errorWidget: _ServiceHeroPlaceholder(cs: cs),
                        )
                      : _ServiceHeroPlaceholder(cs: cs),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title + availability ──────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              service.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: service.availability
                                  ? cs.primaryContainer.withValues(alpha: 0.3)
                                  : cs.errorContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: service.availability
                                      ? cs.primary
                                      : cs.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  service.availability
                                      ? s.servicesAvailable
                                      : s.servicesUnavailable,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: service.availability
                                        ? cs.primary
                                        : cs.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ── Category ────────────────────────────────────────
                      Text(
                        service.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Cover description ────────────────────────────────
                      Text(
                        service.coverDescription,
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Divider(height: 32),
                      // ── Detail rows ────────────────────────────────────
                      _DetailRow(
                        icon: Icons.description_outlined,
                        label: s.servicesDescriptionLabel,
                        value: service.description,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.work_history_outlined,
                        label: s.servicesDetailExperience,
                        value: s.servicesDetailExperienceYears.replaceFirst(
                          '{n}',
                          service.yearsOfExperience.toString(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.payments_outlined,
                        label: s.servicesDetailPriceRange,
                        value: service.priceRange,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: s.servicesDetailLocation,
                        value: service.location,
                      ),
                      const SizedBox(height: 12),
                      // ── CV ────────────────────────────────────────────
                      _DetailRow(
                        icon: Icons.attach_file,
                        label: s.servicesDetailCv,
                        value: service.cvFileUrl != null
                            ? '${s.servicesDetailCvView}: ${service.cvFileUrl!.split('/').last}'
                            : s.servicesDetailNoCv,
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 12),
                      // ── Inline reviews (load + submit in place) ──────
                      _InlineReviewsSection(serviceId: widget.serviceId),
                      const SizedBox(height: 16),
                      // ── Similar services ─────────────────────────────
                      SimilarServicesSection(anchor: service),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Overlay: back button + edit button ─────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverlayCircleButton(
                  icon: Icons.arrow_back,
                  onPressed: () => state.popScreen(),
                ),
                // Edit button — owner only
                if (service.ownerId == state.profile?.id)
                  _OverlayCircleButton(
                    icon: Icons.edit_outlined,
                    onPressed: () =>
                        state.pushScreen(ServiceEditScreenRoute(service.id)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service hero placeholder ──────────────────────────────────────────────────

class _ServiceHeroPlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _ServiceHeroPlaceholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      color: cs.primaryContainer.withValues(alpha: 0.25),
      child: Icon(
        Icons.work_outline_rounded,
        size: 72,
        color: cs.primary.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── Overlay circle button (back / edit on hero image) ─────────────────────────

class _OverlayCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _OverlayCircleButton(
      {required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

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
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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

  int _rating = 5;
  final _commentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await KoolanAppStateScope.of(context)
        .loadReviewsForService(widget.serviceId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = KoolanAppStateScope.of(context);
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
              onPressed: () => setState(() {
                _showForm = !_showForm;
                _submitError = null;
                _successMessage = null;
              }),
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
