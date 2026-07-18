import 'package:flutter/material.dart';

import '../models/syncable_entity.dart';
import '../services/app_state.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onRetry;

  const SyncStatusBadge({super.key, required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    switch (status) {
      case SyncStatus.local:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            s.syncLocal,
            style: TextStyle(fontSize: 11, color: cs.primary),
          ),
        );
      case SyncStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(s.syncPending,
                style: TextStyle(fontSize: 11, color: cs.primary)),
          ],
        );
      case SyncStatus.synced:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: cs.tertiary),
            const SizedBox(width: 6),
            Text(s.syncSynced,
                style: TextStyle(fontSize: 11, color: cs.tertiary)),
          ],
        );
      case SyncStatus.failed:
        return InkWell(
          onTap: onRetry,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 14, color: cs.error),
              const SizedBox(width: 6),
              Text(s.syncFailed,
                  style: TextStyle(fontSize: 11, color: cs.error)),
            ],
          ),
        );
    }
  }
}
