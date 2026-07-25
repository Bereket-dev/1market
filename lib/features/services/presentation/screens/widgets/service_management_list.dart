part of '../service_management_screen.dart';

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

