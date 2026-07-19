import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/sync_status_badge.dart';

class ServiceManagementScreen extends StatelessWidget {
  const ServiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final services = state.getMyServices();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.servicesTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Add new service — prominent, not buried ─────────────────────
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(s.servicesAddNew),
              onPressed: () {
                state.pushScreen(ServiceEditScreenRoute(null));
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 16),
            if (services.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 56,
                        color: cs.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.profileNoServices,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.profileNoServicesSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.separated(
                  itemCount: services.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceCard(service: service);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => state.pushScreen(ServiceEditScreenRoute(service.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row + sync badge ─────────────────────────────────────
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
                  SyncStatusBadge(status: service.syncStatus),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                service.category,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service.coverDescription,
                style: TextStyle(color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // ── Availability row — toggle + visible label ──────────────────
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: service.availability
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${s.servicesAvailabilityLabel}: ',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          service.availability
                              ? s.servicesAvailable
                              : s.servicesUnavailable,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: service.availability
                                ? cs.primary
                                : cs.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Inline toggle with visible label — no bare icon
                  Text(
                    s.servicesToggleAvailability,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Switch.adaptive(
                    value: service.availability,
                    onChanged: (value) {
                      state.toggleServiceAvailability(service.id, value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
