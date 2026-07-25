part of '../my_applications_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widgets for MyApplicationsScreen
// ─────────────────────────────────────────────────────────────────────────────

// ── Service group ─────────────────────────────────────────────────────────────

class _ServiceGroup extends StatelessWidget {
  final String serviceName;
  final List<Application> applications;

  const _ServiceGroup({
    required this.serviceName,
    required this.applications,
  });

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.work_outline, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                '${s.applicationsServiceGroupLabel}: $serviceName',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cs.onSurface),
              ),
            ],
          ),
        ),
        ...applications.map(
          (app) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ApplicationCard(application: app),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

// ── Application card ──────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final Application application;
  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    final postTitle =
        application.hiringPostTitle ?? s.hiringTitle;

    final statusColor = switch (application.status) {
      ApplicationStatus.submitted => cs.primary,
      ApplicationStatus.reviewed  => cs.tertiary,
      ApplicationStatus.accepted  => Colors.green,
      ApplicationStatus.rejected  => cs.error,
    };

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(postTitle,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        s.applicationStatusLabel(application.status.name),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(application.submittedAt),
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _ApplicationsEmpty extends StatelessWidget {
  const _ApplicationsEmpty();

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s     = state.s;
    final cs    = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(s.applicationsEmpty,
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.search),
            label: Text(s.hiringBrowseTitle),
            onPressed: () => state.pushScreen(HiringBrowseScreenRoute()),
          ),
        ],
      ),
    );
  }
}
