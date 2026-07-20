import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/services/app_state.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.servicesDetailTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + availability ──────────────────────────────────────
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
                        color: service.availability ? cs.primary : cs.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        service.availability
                            ? s.servicesAvailable
                            : s.servicesUnavailable,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              service.availability ? cs.primary : cs.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ── Category ─────────────────────────────────────────────────
            Text(
              service.category,
              style: TextStyle(
                fontSize: 14,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // ── Cover description ─────────────────────────────────────────
            Text(
              service.coverDescription,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 32),
            // ── Detail rows ───────────────────────────────────────────────
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
            // ── CV ────────────────────────────────────────────────────────
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
            // ── Reviews section ────────────────────────────────────────────
            _ReviewsSectionHeader(serviceId: widget.serviceId),
            const SizedBox(height: 24),
            // ── Phase C Part 2 note ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.servicesDetailApplyNote,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Similar services ───────────────────────────────────────────
            SimilarServicesSection(anchor: service),
          ],
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

// ── Reviews section header (Section 5 wires in the full list) ─────────────────

class _ReviewsSectionHeader extends StatelessWidget {
  final String serviceId;
  const _ReviewsSectionHeader({required this.serviceId});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          s.reviewsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        // Navigate to reviews sub-screen (wired in Section 5)
        TextButton.icon(
          icon: const Icon(Icons.rate_review_outlined, size: 16),
          label: Text(s.reviewsSubmitTitle),
          onPressed: () =>
              state.pushScreen(ServiceReviewsScreenRoute(serviceId)),
        ),
      ],
    );
  }
}
