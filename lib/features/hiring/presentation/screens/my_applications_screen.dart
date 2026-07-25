import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../shared/models/application.dart';
import '../../../../shared/services/app_state.dart';
part 'widgets/my_applications_widgets.dart';

/// Applicant's grouped view of their own applications.
/// Grouped by the service they applied from:
///   Profile → Services → [service] → its applications
///
/// Accessible from Profile → "My Applications" section.
class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final grouped = state.getMyApplicationsGroupedByService();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
          tooltip: s.wizardBack,
        ),
        title: Text(s.applicationsTitle),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: grouped.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.applicationsEmpty,
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Prompt to browse jobs
                  FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(s.hiringBrowseTitle),
                    onPressed: () =>
                        state.pushScreen(HiringBrowseScreenRoute()),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.map((entry) {
                final serviceId = entry.key;
                final apps = entry.value;
                // Get the service name from the first application (denormalized).
                final serviceName = apps.first.serviceName ??
                    state.getServiceById(serviceId)?.title ??
                    s.profileMyServices;

                return _ServiceGroup(
                  serviceName: serviceName,
                  applications: apps,
                );
              }).toList(),
            ),
    );
  }
}

// ── Service group ─────────────────────────────────────────────────────────────
