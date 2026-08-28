import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/errors/error_reporter.dart';
import '../services/app_state.dart';

/// Calm replacement for Flutter's red [ErrorWidget] in release builds.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.details,
  });

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final s = context
            .getInheritedWidgetOfExactType<OnemarketAppStateScope>()
            ?.notifier
            ?.s;
    final title = s?.errorSomethingWrong ?? 'Something went wrong';
    final reportLabel = s?.errorReport ?? 'Report';
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  Text(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    ErrorReporter.recordError(
                      details.exception,
                      details.stack,
                      reason: 'user_report_from_error_widget',
                    );
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(s?.errorReportThanks ?? 'Thanks — report sent.'),
                      ),
                    );
                  },
                  child: Text(reportLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
