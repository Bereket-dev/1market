part of '../hiring_applicant_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CV viewer dialog for HiringApplicantDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a dialog with the CV URL and a "Copy link" action.
/// (url_launcher is not in this project's dependencies.)
Future<void> _showCvDialog(BuildContext context, String url) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: const Text('CV / Resume'),
        content: SelectableText(
          url,
          style: TextStyle(
            fontSize: 13,
            color: cs.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CV link copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy link'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
