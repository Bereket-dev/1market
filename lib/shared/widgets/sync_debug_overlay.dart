import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/app_state.dart';

/// Debug-only overlay showing aggregate sync metrics from [OnemarketAppState.syncObservability].
///
/// Visible only in debug builds. Does not register on [OnemarketAppStateScope] —
/// receives [appState] directly from [_ShellScaffold].
class SyncDebugOverlay extends StatelessWidget {
  const SyncDebugOverlay({super.key, required this.appState});

  final OnemarketAppState appState;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([appState, appState.syncObservability]),
      builder: (context, _) {
        final status = appState.syncObservability;
        final cs = Theme.of(context).colorScheme;

        return Material(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.92),
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: cs.onSurface,
                height: 1.35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sync debug',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  Text('Last OK: ${status.lastSyncLabel}'),
                  Text('Pending: ${status.pendingOperations}'),
                  Text(
                    'Needs attention: ${status.failedOperations}',
                    style: status.hasFailures
                        ? TextStyle(color: cs.error, fontWeight: FontWeight.bold)
                        : null,
                  ),
                  Text('BW: ${status.bandwidthLabel}'),
                  if (status.lastSyncDuration != null)
                    Text('Duration: ${status.lastSyncDuration!.inMilliseconds}ms'),
                  if (appState.isRefreshing) const Text('↻ refreshing'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
