import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../shared/models/application.dart';
import '../../../../shared/models/profile.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

/// Full applicant detail view — opened when the poster taps an applicant row.
///
/// Shows:
/// - Applicant profile photo, name, verification badge, rating
/// - Applied service details (description, category, experience, price, CV)
/// - Job post requirements (description from hiring post)
/// - Service reviews
/// - Accept / Reject / Back-to-Review action buttons (context-sensitive)
/// - Message button to open a direct chat with the applicant
class HiringApplicantDetailScreen extends StatefulWidget {
  final String applicationId;
  final String postId;

  const HiringApplicantDetailScreen({
    super.key,
    required this.applicationId,
    required this.postId,
  });

  @override
  State<HiringApplicantDetailScreen> createState() =>
      _HiringApplicantDetailScreenState();
}

class _HiringApplicantDetailScreenState
    extends State<HiringApplicantDetailScreen> {
  bool _loadingExtras = true;
  bool _chatLoading = false;
  UserProfile? _applicantProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final state = KoolanAppStateScope.of(context);
    final app = _application(state);
    if (app == null) {
      setState(() => _loadingExtras = false);
      return;
    }

    // Load reviews for the service in parallel.
    await state.loadReviewsForService(app.serviceId);

    if (mounted) setState(() => _loadingExtras = false);
  }

  Application? _application(KoolanAppState state) {
    final list = state.getApplicationsForPost(widget.postId);
    try {
      return list.firstWhere((a) => a.id == widget.applicationId);
    } catch (_) {
      return null;
    }
  }

  // ── Status actions ────────────────────────────────────────────────────────

  Future<void> _setStatus(
    KoolanAppState state,
    ApplicationStatus newStatus,
  ) async {
    await state.updateApplicationStatus(
      applicationId: widget.applicationId,
      hiringPostId: widget.postId,
      newStatus: newStatus,
    );
  }

  Future<void> _openChat(KoolanAppState state, Application app) async {
    setState(() => _chatLoading = true);
    final post = state.getHiringPostById(widget.postId);
    if (post == null) {
      setState(() => _chatLoading = false);
      return;
    }
    final threadId = await state.startChatForApplication(
      applicantId: app.applicantId,
      posterId: post.posterId,
    );
    if (!mounted) return;
    setState(() => _chatLoading = false);

    if (threadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.s.applicantDetailChatError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final idx = state.chatSessions.indexWhere((s) => s.id == threadId);
    if (idx != -1) {
      state.pushScreen(ActiveChatScreenRoute(idx));
    }
  }

  Future<void> _launchUrl(String url) async {
    // Show the CV URL in a dialog and allow the user to copy it.
    // (url_launcher is not in this project's dependencies.)
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('CV / Resume'),
          content: SelectableText(
            url,
            style: TextStyle(
              fontSize: 13,
              color: cs.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CV link copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy link'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    final app = _application(state);
    if (app == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
          title: Text(s.applicantDetailTitle),
          backgroundColor: cs.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final service = state.getServiceById(app.serviceId);
    final reviews = state.getReviewsForService(app.serviceId);
    final post = state.getHiringPostById(widget.postId);
    final applicantName = app.applicantName ?? s.reviewsFallbackUserName;
    final status = app.status;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.applicantDetailTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status chip ───────────────────────────────────────────────────
          _StatusChip(status: status),
          const SizedBox(height: 16),

          // ── Applicant profile section ─────────────────────────────────────
          _SectionHeader(title: s.applicantDetailProfileSection),
          const SizedBox(height: 10),
          _ProfileCard(
            applicantName: applicantName,
            avatarUrl: app.applicantAvatarUrl,
            profile: _applicantProfile,
            submittedAt: app.submittedAt,
            submittedLabel: s.applicantDetailSubmittedAt,
            verifiedLabel: s.applicantDetailVerified,
            unverifiedLabel: s.applicantDetailUnverified,
          ),
          const SizedBox(height: 20),

          // ── Applied service section ────────────────────────────────────────
          _SectionHeader(title: s.applicantDetailServiceSection),
          const SizedBox(height: 10),
          if (service != null)
            _ServiceCard(
              service: service,
              cvLabel: s.applicantDetailCvSection,
              viewCvLabel: s.applicantDetailCvView,
              noCvLabel: s.applicantDetailNoCv,
              experienceLabel: s.applicantDetailExperience,
              onViewCv: _launchUrl,
            )
          else
            _PlaceholderCard(
              icon: Icons.work_outline,
              label: app.serviceName ?? s.profileMyServices,
            ),
          const SizedBox(height: 20),

          // ── Job requirements from post ────────────────────────────────────
          if (post != null && post.description.isNotEmpty) ...[
            _SectionHeader(
              title: '${s.hiringDescriptionLabel} (${post.title})',
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.category.isNotEmpty) ...[
                    _LabelValue(
                      label: s.hiringCategoryLabel,
                      value: post.category,
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (post.location.isNotEmpty) ...[
                    _LabelValue(
                      label: s.hiringLocationLabel,
                      value: post.location,
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (post.priceRange.isNotEmpty) ...[
                    _LabelValue(
                      label: s.hiringDetailBudget,
                      value: post.priceRange,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    post.description,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Reviews section ───────────────────────────────────────────────
          _SectionHeader(title: s.applicantDetailReviewsSection),
          const SizedBox(height: 10),
          if (_loadingExtras)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s.applicantDetailNoReviews,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          else
            ...reviews.map((r) => _ReviewRow(review: r)),

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────────
          _ActionButtons(
            status: status,
            chatLoading: _chatLoading,
            acceptLabel: s.applicantDetailAccept,
            rejectLabel: s.applicantDetailReject,
            backToReviewLabel: s.applicantDetailBackToReview,
            chatLabel: s.applicantDetailChat,
            onAccept: () => _setStatus(state, ApplicationStatus.accepted),
            onReject: () => _setStatus(state, ApplicationStatus.rejected),
            onBackToReview: () =>
                _setStatus(state, ApplicationStatus.reviewed),
            onChat: () => _openChat(state, app),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: cs.primary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final ApplicationStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    final color = switch (status) {
      ApplicationStatus.submitted => cs.primary,
      ApplicationStatus.reviewed => cs.tertiary,
      ApplicationStatus.accepted => Colors.green,
      ApplicationStatus.rejected => cs.error,
    };
    final icon = switch (status) {
      ApplicationStatus.submitted => Icons.send_outlined,
      ApplicationStatus.reviewed => Icons.visibility_outlined,
      ApplicationStatus.accepted => Icons.check_circle_outline,
      ApplicationStatus.rejected => Icons.cancel_outlined,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                s.applicationStatusLabel(status.name),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String applicantName;
  final String? avatarUrl;
  final UserProfile? profile;
  final DateTime submittedAt;
  final String submittedLabel;
  final String verifiedLabel;
  final String unverifiedLabel;

  const _ProfileCard({
    required this.applicantName,
    this.avatarUrl,
    this.profile,
    required this.submittedAt,
    required this.submittedLabel,
    required this.verifiedLabel,
    required this.unverifiedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = applicantName.isNotEmpty
        ? applicantName[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedImageWidget(
                    imageUrl: avatarUrl!,
                    width: 60,
                    height: 60,
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        cs.primaryContainer.withValues(alpha: 0.5),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verification
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        applicantName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    // Profile rating if available
                    if (profile != null && profile!.rating > 0) ...[
                      RatingStars(
                        rating: profile!.rating,
                        reviewCount: profile!.reviewsCount,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // City if available
                if (profile?.city != null && profile!.city!.isNotEmpty)
                  Text(
                    profile!.city!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 6),
                // Submitted date
                Text(
                  '$submittedLabel: ${_formatDate(submittedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Service service;
  final String cvLabel;
  final String viewCvLabel;
  final String noCvLabel;
  final String experienceLabel;
  final void Function(String url) onViewCv;

  const _ServiceCard({
    required this.service,
    required this.cvLabel,
    required this.viewCvLabel,
    required this.noCvLabel,
    required this.experienceLabel,
    required this.onViewCv,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + category
          Text(
            service.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _Chip(label: service.category, color: cs.primary),
              const SizedBox(width: 8),
              if (service.availability)
                _Chip(
                  label: '✓ Available',
                  color: Colors.green,
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          if (service.description.isNotEmpty) ...[
            Text(
              service.description,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Cover description / pitch
          if (service.coverDescription.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                '"${service.coverDescription}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Detail rows
          _LabelValue(
            label: experienceLabel,
            value: '${service.yearsOfExperience} yrs',
          ),
          const SizedBox(height: 4),
          _LabelValue(
            label: 'Price',
            value: service.priceRange,
          ),
          const SizedBox(height: 4),
          _LabelValue(
            label: 'Location',
            value: service.location,
          ),
          const SizedBox(height: 12),
          // CV row
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                cvLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (service.cvFileUrl != null &&
                  service.cvFileUrl!.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => onViewCv(service.cvFileUrl!),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(viewCvLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                )
              else
                Text(
                  noCvLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Review row ────────────────────────────────────────────────────────────────

class _ReviewRow extends StatelessWidget {
  final ServiceReview review;
  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = review.reviewerName ?? 'User';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
              backgroundImage: review.reviewerAvatarUrl != null
                  ? NetworkImage(review.reviewerAvatarUrl!)
                  : null,
              child: review.reviewerAvatarUrl == null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Star rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 13,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (review.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.comment,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
