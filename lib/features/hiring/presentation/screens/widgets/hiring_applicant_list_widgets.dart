part of '../hiring_applicant_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widgets for HiringApplicantListScreen
// ─────────────────────────────────────────────────────────────────────────────

// ── Applicant row ─────────────────────────────────────────────────────────────

class _ApplicantRow extends StatelessWidget {
  final Application application;
  final VoidCallback onTap;

  const _ApplicantRow({
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s  = state.s;
    final cs = Theme.of(context).colorScheme;
    final displayName =
        application.applicantName ?? s.reviewsFallbackUserName;
    final serviceName = application.serviceName ?? s.profileMyServices;

    final statusColor = switch (application.status) {
      ApplicationStatus.submitted => cs.primary,
      ApplicationStatus.reviewed  => cs.tertiary,
      ApplicationStatus.accepted  => Colors.green,
      ApplicationStatus.rejected  => cs.error,
    };

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              // Name + service
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface)),
                    Text(serviceName,
                        style:
                            TextStyle(fontSize: 12, color: cs.primary)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.applicationStatusLabel(application.status.name),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
              const SizedBox(width: 8),
              SyncStatusBadge(status: application.syncStatus),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error / retry state ───────────────────────────────────────────────────────

class _ApplicantListError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ApplicantListError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(s.hiringNoApplicantsYet,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(s.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _ApplicantListEmpty extends StatelessWidget {
  const _ApplicantListEmpty();

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(s.hiringNoApplicantsYet,
          style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }
}
