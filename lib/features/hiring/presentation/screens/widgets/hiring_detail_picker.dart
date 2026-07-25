part of '../hiring_detail_screen.dart';

// ── Service picker sheet ──────────────────────────────────────────────────────

class _ServicePickerSheet extends StatefulWidget {
  final List<Service> services;
  final String postId;

  const _ServicePickerSheet({
    required this.services,
    required this.postId,
  });

  @override
  State<_ServicePickerSheet> createState() =>
      _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  Service? _selected;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.hiringSelectServiceTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.hiringSelectServiceHint,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // List of the user's own services — labelled radio items
          ...widget.services.map(
            (svc) => RadioListTile<Service>(
              value: svc,
              groupValue: _selected,
              title: Text(
                svc.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              subtitle: Text(
                svc.category,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                ),
              ),
              onChanged: (v) => setState(() => _selected = v),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(s.hiringApplyConfirm),
          ),
        ],
      ),
    );
  }
}
