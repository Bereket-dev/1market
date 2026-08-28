part of '../profile_screen.dart';

// ── Services tab ──────────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  final List<Service> services;
  final VoidCallback onManageTap;
  final VoidCallback onAddServiceTap;
  final VoidCallback onMyHiringPostsTap;
  final VoidCallback onMyApplicationsTap;
  final int hiringPostCount;
  final int applicationCount;

  const _ServicesTab({
    required this.services,
    required this.onManageTap,
    required this.onAddServiceTap,
    required this.onMyHiringPostsTap,
    required this.onMyApplicationsTap,
    required this.hiringPostCount,
    required this.applicationCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final state = OnemarketAppStateScope.of(context);
    final s     = state.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Action buttons ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onManageTap,
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: Text(s.profileManageAll),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAddServiceTap,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(s.servicesAddNew),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Service cards ─────────────────────────────────────────────────
        if (services.isEmpty) ...[
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 38,
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(Icons.work_outline,
                size: 36, color: cs.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Text(s.profileNoServices,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(s.profileNoServicesSub,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length > 3 ? 3 : services.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final service = services[index];
              return _ProfileServiceCard(
                service: service,
                onTap: () => state.pushScreen(
                    ServiceDetailScreenRoute(service.id)),
              );
            },
          ),
          if (services.length > 3) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onManageTap,
              child: Text(
                '+ ${services.length - 3} more services',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],

        Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 4),

        _ProfileActionRow(
          icon: Icons.work_outline,
          label: s.profileMyHiringPosts,
          badge: hiringPostCount > 0 ? '$hiringPostCount' : null,
          onTap: onMyHiringPostsTap,
        ),
        const SizedBox(height: 4),
        _ProfileActionRow(
          icon: Icons.send_outlined,
          label: s.profileMyApplications,
          badge: applicationCount > 0 ? '$applicationCount' : null,
          onTap: onMyApplicationsTap,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Rich service preview card used in the profile Services tab.
/// Taps into ServiceDetailScreen.
class _ProfileServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;
  const _ProfileServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final isAvail = service.availability;
    final s       = OnemarketAppStateScope.of(context).s;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvail
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: isAvail ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image / placeholder ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: service.imageUrl.isNotEmpty
                  ? CachedImageWidget(
                      imageUrl: service.imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorWidget: _ServicePlaceholder(cs: cs),
                    )
                  : _ServicePlaceholder(cs: cs),
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service.category,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Title
                  Text(
                    service.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Price
                  if (service.priceRange.isNotEmpty)
                    Text(
                      service.priceRange,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: cs.primary),
                    ),
                  const SizedBox(height: 3),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          service.location,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Availability dot + arrow ───────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvail ? cs.primary : cs.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAvail ? s.servicesAvailable : s.servicesUnavailable,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAvail ? cs.primary : cs.error),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _ServicePlaceholder({required this.cs});
  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        color: cs.primaryContainer.withValues(alpha: 0.3),
        child: Icon(Icons.work_outline_rounded,
            color: cs.primary.withValues(alpha: 0.6), size: 28),
      );
}

