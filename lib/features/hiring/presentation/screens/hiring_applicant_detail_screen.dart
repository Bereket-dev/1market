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
part 'widgets/hiring_applicant_detail_widgets.dart';
part 'widgets/hiring_applicant_detail_helpers.dart';
part 'widgets/hiring_applicant_detail_cv.dart';

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
