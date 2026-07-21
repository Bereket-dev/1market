import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/sync_status_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ServiceManagementScreen
//
// This is the hub for a professional user's service profile.
//
// Context for first-time users:
//   A "service" on Koolan is your professional profile card — it tells
//   employers and clients what you do, your rate, and whether you are
//   currently available for hire. Toggling availability instantly makes you
//   discoverable (or hidden) in the marketplace search results.
//
// From here a user can:
//   • Create a new service profile
//   • Toggle availability ON/OFF for any service without opening the editor
//   • Tap a card to open the full editor (title, rate, description, CV, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class ServiceManagementScreen extends StatelessWidget {
  const ServiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state    = KoolanAppStateScope.of(context);
    final s        = state.s;
    final cs       = Theme.of(context).colorScheme;
    final services = state.getMyServices();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(
          s.servicesTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => state.pushScreen(ServiceEditScreenRoute(null)),
            icon: Icon(Icons.add_rounded, size: 18, color: cs.primary),
            label: Text(
              'New Service',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: cs.primary),
            ),
          ),
        ],
      ),
      body: services.isEmpty
          ? _EmptyServicesState(state: state, cs: cs)
          : _ServiceList(services: services, state: state, cs: cs),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — explains what a service is before any are created
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyServicesState extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  const _EmptyServicesState({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    final s = state.s;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          // Hero illustration
          CircleAvatar(
            radius: 56,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
            child: Icon(Icons.work_outline_rounded,
                size: 56, color: cs.primary),
          ),
          const SizedBox(height: 24),

          Text(
            'Set up your service profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Explanation card — onboarding copy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _OnboardingRow(
                  icon: Icons.search_rounded,
                  cs: cs,
                  text:
                      'Employers and clients search for professionals like you by skill category.',
                ),
                const SizedBox(height: 12),
                _OnboardingRow(
                  icon: Icons.toggle_on_rounded,
                  cs: cs,
                  text:
                      'Toggle your availability at any time — when you\'re available, you appear in results.',
                ),
                const SizedBox(height: 12),
                _OnboardingRow(
                  icon: Icons.handshake_outlined,
                  cs: cs,
                  text:
                      'Interested employers contact you directly through the chat to discuss the job.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: () =>
                state.pushScreen(ServiceEditScreenRoute(null)),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              s.servicesAddNew,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingRow extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final String text;
  const _OnboardingRow(
      {required this.icon, required this.cs, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service list
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceList extends StatelessWidget {
  final List<Service> services;
  final KoolanAppState state;
  final ColorScheme cs;
  const _ServiceList(
      {required this.services, required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    // Split into available vs unavailable so user can quickly see what to activate
    final available   = services.where((s) => s.availability).toList();
    final unavailable = services.where((s) => !s.availability).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Unavailable section — surfaces them first as a call to action
        if (unavailable.isNotEmpty) ...[
          _SectionHeader(
            label: 'Currently unavailable — tap toggle to go live',
            icon: Icons.visibility_off_rounded,
            cs: cs,
          ),
          const SizedBox(height: 8),
          ...unavailable.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceCard(service: s, state: state),
              )),
          if (available.isNotEmpty) const SizedBox(height: 8),
        ],

        if (available.isNotEmpty) ...[
          _SectionHeader(
            label: 'Available — visible to employers',
            icon: Icons.visibility_rounded,
            cs: cs,
          ),
          const SizedBox(height: 8),
          ...available.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceCard(service: s, state: state),
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;
  const _SectionHeader(
      {required this.label, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service card — cover image thumbnail + consistent layout matching
// _MyListingTile: [image left | info center | action pills bottom-right]
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Service service;
  final KoolanAppState state;
  const _ServiceCard({required this.service, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final s       = state.s;
    final isAvail = service.availability;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvail
              ? cs.primary.withValues(alpha: 0.35)
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: isAvail ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => state.pushScreen(ServiceEditScreenRoute(service.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover image thumbnail ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: service.imageUrl.isNotEmpty
                    ? CachedImageWidget(
                        imageUrl: service.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: _ServiceImagePlaceholder(cs: cs),
                      )
                    : _ServiceImagePlaceholder(cs: cs),
              ),
              const SizedBox(width: 12),

              // ── Info section ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip + sync badge
                    Row(
                      children: [
                        _ServiceChip(
                          label: service.category,
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          textColor: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        SyncStatusBadge(status: service.syncStatus),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      service.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price range
                    if (service.priceRange.isNotEmpty)
                      Text(
                        service.priceRange,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            service.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ── Availability toggle row ─────────────────────────
                    GestureDetector(
                      onTap: () => state.toggleServiceAvailability(
                          service.id, !isAvail),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAvail ? cs.primary : cs.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAvail
                                ? s.servicesAvailable
                                : s.servicesUnavailable,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAvail ? cs.primary : cs.error,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch.adaptive(
                              value: isAvail,
                              onChanged: (v) =>
                                  state.toggleServiceAvailability(
                                      service.id, v),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Action pills row ───────────────────────────────
                    Row(
                      children: [
                        _CardAction(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: cs.secondaryContainer
                              .withValues(alpha: 0.5),
                          iconColor: cs.secondary,
                          onTap: () => state.pushScreen(
                              ServiceEditScreenRoute(service.id)),
                        ),
                        const SizedBox(width: 8),
                        _CardAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: cs.error.withValues(alpha: 0.1),
                          iconColor: cs.error,
                          onTap: () => _confirmDeleteService(
                              context, state, service.id, s),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceImagePlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _ServiceImagePlaceholder({required this.cs});

  @override
  Widget build(BuildContext context) => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.work_outline_rounded,
          color: cs.primary.withValues(alpha: 0.5),
          size: 32,
        ),
      );
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _ServiceChip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete confirmation helper
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _confirmDeleteService(
  BuildContext context,
  KoolanAppState state,
  String serviceId,
  dynamic s,
) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.servicesDeleteButton),
      content: Text(s.servicesDeleteConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.servicesDeleteCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: Text(s.servicesDeleteConfirmButton),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await state.deleteService(serviceId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon + text pill action button
// ─────────────────────────────────────────────────────────────────────────────

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
