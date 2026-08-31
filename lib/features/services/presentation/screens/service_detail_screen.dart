import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/share_service.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
import '../../../../shared/widgets/cv_viewer.dart';
import '../../../../shared/widgets/report_bottom_sheet.dart';
import '../../../../shared/widgets/similar_section.dart';
part 'widgets/service_detail_reviews.dart';
part 'widgets/service_detail_hero.dart';

/// Read-only detail view for a service.
///
/// Hire via job posts: open a hiring post and accept the provider's application.
/// Reviews are gated on that accepted engagement.
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
    OnemarketAppStateScope.of(context).recordItemViewed(widget.serviceId);
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
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
                // ── Hero image carousel ────────────────────────────────
                _ServiceHeroCarousel(
                  imageUrl: service.imageUrl,
                  imageUrls: service.imageUrls,
                  ownerId: service.ownerId,
                  state: state,
                  serviceId: service.id,
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
                      const SizedBox(height: 12),
                      // ── View owner profile ───────────────────────────────
                      OutlinedButton.icon(
                        onPressed: () => state.pushScreen(
                          PublicProfileScreenRoute(service.ownerId),
                        ),
                        icon: const Icon(Icons.person_outline, size: 16),
                        label: Text(state.s.detailViewProfile),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: cs.outlineVariant),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                      // ── Report link — non-owner only ─────────────────────
                      if (service.ownerId != state.profile?.id) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => showReportBottomSheet(
                            context,
                            targetType: 'service',
                            serviceId: service.id,
                            reportedUserId: service.ownerId,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 15,
                                color: cs.onSurfaceVariant,
                              ),
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
                        value:
                            service.cvFileUrl != null &&
                                service.cvFileUrl!.isNotEmpty
                            ? CvViewer.fileName(service.cvFileUrl!)
                            : s.servicesDetailNoCv,
                        actionLabel:
                            service.cvFileUrl != null &&
                                service.cvFileUrl!.isNotEmpty
                            ? s.servicesDetailCvView
                            : null,
                        onAction:
                            service.cvFileUrl != null &&
                                service.cvFileUrl!.isNotEmpty
                            ? () => CvViewer.open(context, service.cvFileUrl!)
                            : null,
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 12),
                      // ── Inline reviews (load + submit in place) ──────
                      _InlineReviewsSection(serviceId: widget.serviceId),
                      const SizedBox(height: 16),
                      if (service.ownerId == state.profile?.id)
                        _OwnerServiceActions(service: service, state: state),
                      const SizedBox(height: 8),
                      // ── Similar services ─────────────────────────────
                      SimilarServicesSection(anchor: service),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Overlay: back button + share + edit button ──────────────────
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
                Row(
                  children: [
                    // Report button — non-owner only
                    if (service.ownerId != state.profile?.id) ...[
                      _OverlayCircleButton(
                        icon: Icons.flag_outlined,
                        onPressed: () => showReportBottomSheet(
                          context,
                          targetType: 'service',
                          serviceId: service.id,
                          reportedUserId: service.ownerId,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Share button — visible to all
                    _OverlayCircleButton(
                      icon: Icons.share_outlined,
                      onPressed: () {
                        final box = context.findRenderObject() as RenderBox?;
                        ShareService.shareService(
                          service,
                          state.s,
                          sharePositionOrigin: box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null,
                        );
                      },
                    ),
                    // Edit button — owner only
                    if (service.ownerId == state.profile?.id) ...[
                      const SizedBox(width: 8),
                      _OverlayCircleButton(
                        icon: Icons.edit_outlined,
                        onPressed: () => state.pushScreen(
                          ServiceEditScreenRoute(service.id),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service hero carousel ─────────────────────────────────────────────────────
// Renders a swipeable PageView carousel when the service has multiple images,
// or a single image / placeholder when it has zero or one.
// Currently Service only carries imageUrl — the widget is structured to
// accept a list so it can grow when imageUrls is added to the model.

class _OwnerServiceActions extends StatelessWidget {
  final Service service;
  final OnemarketAppState state;

  const _OwnerServiceActions({required this.service, required this.state});

  Future<void> _toggle(BuildContext context) async {
    final next = !service.availability;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          next
              ? state.s.servicesMakeAvailable
              : state.s.servicesMakeUnavailable,
        ),
        content: Text(state.s.servicesAvailabilityBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.s.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              next
                  ? state.s.servicesMakeAvailable
                  : state.s.servicesMakeUnavailable,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.toggleServiceAvailability(service.id, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nextLabel = service.availability
        ? state.s.servicesMakeUnavailable
        : state.s.servicesMakeAvailable;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.s.servicesAvailabilityLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _toggle(context),
            icon: Icon(
              service.availability
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            label: Text(nextLabel),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
