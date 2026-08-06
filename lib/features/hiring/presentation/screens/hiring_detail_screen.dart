import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/share_service.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
import '../../../../shared/widgets/report_bottom_sheet.dart';
import '../../../../shared/widgets/similar_section.dart';
part 'widgets/hiring_detail_picker.dart';
part 'widgets/hiring_detail_hero.dart';
part 'widgets/hiring_detail_content.dart';
part 'widgets/hiring_detail_apply.dart';

/// Full detail view for a hiring post.
/// Shows all fields. User must read the full post before applying.
/// Never a blind one-tap apply.
///
/// Apply flow (Section 3):
/// 1. User taps "Apply now".
/// 2. If user has no services → prompt to create one first.
/// 3. If user has services → show service picker sheet.
/// 4. Duplicate check (same post + same service) before submit.
class HiringDetailScreen extends StatefulWidget {
  final String postId;
  const HiringDetailScreen({super.key, required this.postId});

  @override
  State<HiringDetailScreen> createState() => _HiringDetailScreenState();
}

class _HiringDetailScreenState extends State<HiringDetailScreen> {
  bool _applying = false;
  String? _applyError;
  bool _alreadyApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAlreadyApplied();
    // Record this view for the interaction penalty in recommendations.
    KoolanAppStateScope.of(context).recordItemViewed(widget.postId);
  }

  void _checkAlreadyApplied() {
    final state = KoolanAppStateScope.of(context);
    final userId = state.currentUser?.id;
    if (userId == null) return;
    // Check in-memory: if any application in myApplications matches this post.
    final applied = state.myApplications
        .any((a) => a.hiringPostId == widget.postId);
    // Only call setState if the value actually changed to avoid rebuild loops.
    if (applied != _alreadyApplied) {
      setState(() => _alreadyApplied = applied);
    }
  }

  Future<void> _startApply(BuildContext context) async {
    final state = KoolanAppStateScope.of(context);

    // Auth gate: guests cannot apply — show soft-gate sheet instead.
    if (!state.isSignedIn) {
      showAuthGateSheet(context, reason: AuthGateReason.apply);
      return;
    }

    final s = state.s;
    final myServices = state.getMyServices();

    if (myServices.isEmpty) {
      // No services — prompt user to create one first.
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.hiringSelectServiceTitle),
          content: Text(s.hiringNoServicesPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.hiringDeleteCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                state.pushScreen(ServiceEditScreenRoute(null));
              },
              child: Text(s.hiringNoServicesAction),
            ),
          ],
        ),
      );
      return;
    }

    // Show service selector sheet.
    if (!context.mounted) return;
    final selectedService = await showModalBottomSheet<Service>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ServicePickerSheet(
        services: myServices,
        postId: widget.postId,
      ),
    );

    if (selectedService == null) return;
    if (!context.mounted) return;

    // Duplicate check (in-memory first, then optimistic — server enforces via UNIQUE).
    final isDuplicate = state.myApplications.any(
      (a) =>
          a.hiringPostId == widget.postId &&
          a.serviceId == selectedService.id,
    );
    if (isDuplicate) {
      setState(() => _applyError = s.hiringDuplicateError);
      return;
    }

    setState(() {
      _applying = true;
      _applyError = null;
    });

    try {
      await state.submitApplication(
        hiringPostId: widget.postId,
        serviceId: selectedService.id,
      );
      if (!mounted) return;
      setState(() {
        _alreadyApplied = true;
        _applyError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.hiringApplySuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString().toLowerCase();
      // Catch server-side unique constraint violation.
      if (errMsg.contains('duplicate') ||
          errMsg.contains('unique') ||
          errMsg.contains('23505')) {
        setState(() => _applyError = s.hiringDuplicateError);
      } else {
        setState(() => _applyError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final post = state.getHiringPostById(widget.postId);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
            tooltip: s.wizardBack,
          ),
          title: Text(s.hiringDetailTitle),
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.hiringDetailTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          // Report button — non-owner only
          if (post.posterId != state.currentUser?.id)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: s.reportMenuLabel,
              onPressed: () => showReportBottomSheet(
                context,
                targetType: 'hiring_post',
                hiringPostId: post.id,
                reportedUserId: post.posterId,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: s.shareHiringSubject,
            onPressed: () {
              final box = context.findRenderObject() as RenderBox?;
              ShareService.shareHiringPost(
                post,
                state.s,
                sharePositionOrigin: box != null
                    ? box.localToGlobal(Offset.zero) & box.size
                    : null,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image (if present) ────────────────────────────────
            if (post.imageUrl.isNotEmpty || post.imageUrls.isNotEmpty) ...[
              _HiringHeroCarousel(
                imageUrl: post.imageUrl,
                imageUrls: post.imageUrls,
              ),
              const SizedBox(height: 20),
            ],
            // ── Title + status ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.title,
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
                    color: post.isOpen
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
                        color: post.isOpen ? cs.primary : cs.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.isOpen
                            ? s.hiringStatusOpen
                            : s.hiringStatusClosed,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: post.isOpen
                              ? cs.primary
                              : cs.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              post.category,
              style: TextStyle(
                fontSize: 14,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              post.description,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface,
                height: 1.5,
              ),
            ),
            const Divider(height: 32),
            // ── Detail rows ───────────────────────────────────────────
            _DetailRow(
              icon: Icons.payments_outlined,
              label: s.hiringDetailBudget,
              value: post.priceRange.isNotEmpty
                  ? post.priceRange
                  : s.servicesBrowseFilterAll,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: s.hiringLocationLabel,
              value: post.location,
            ),
            // ── Report link — non-poster only ─────────────────────────
            if (post.posterId != state.currentUser?.id) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => showReportBottomSheet(
                  context,
                  targetType: 'hiring_post',
                  hiringPostId: post.id,
                  reportedUserId: post.posterId,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      s.reportMenuLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // ── Apply section ─────────────────────────────────────────
            if (_alreadyApplied) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: cs.primary,
                    ),
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
              ),
            ] else ...[
              if (_applyError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: cs.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _applyError!,
                          style: TextStyle(
                            color: cs.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                icon: _applying
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
                onPressed:
                    (_applying || !post.isOpen) ? null : () => _startApply(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
            // ── Similar hiring posts ──────────────────────────────────
            const SizedBox(height: 8),
            SimilarHiringSection(anchor: post),
          ],
        ),
      ),
    );
  }
}

// ── Hiring hero carousel ──────────────────────────────────────────────────────
// Renders a swipeable PageView when the post has multiple images, or a single
// image when it has only one. HiringPost currently carries one imageUrl — the
// widget is structured to grow when imageUrls is added to the model.
