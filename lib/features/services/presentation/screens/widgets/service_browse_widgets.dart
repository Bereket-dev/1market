part of '../service_browse_screen.dart';

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool small;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 14,
          vertical: small ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Browse card ───────────────────────────────────────────────────────────────

class _ServiceBrowseCard extends StatelessWidget {
  final Service service;
  const _ServiceBrowseCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => state.pushScreen(ServiceDetailScreenRoute(service.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + availability dot (only available shown, but keep it visible)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  // Availability label — visible text, not icon-only
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          s.servicesAvailable,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Category
              Text(
                service.category,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Cover description
              Text(
                service.coverDescription,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Location + price row
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      service.location,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    service.priceRange,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // "View full profile" — labelled action, not bare icon
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.servicesBrowseApplyAction,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: cs.primary,
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBrowse extends StatelessWidget {
  final String message;
  const _EmptyBrowse({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 56,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
