import 'package:flutter/material.dart';

import '../models/app_strings.dart';
import '../services/app_state.dart';
import 'auth_gate_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showReportBottomSheet
//
// Convenience function to open the report sheet as a modal bottom sheet.
//
// Pass exactly one of [listingId], [serviceId], or [hiringPostId] and the
// matching [targetType] string ('listing' | 'service' | 'hiring_post').
// [reportedUserId] is the owner/poster so we can attach it to the report and
// block self-reports.
//
// Usage example (listing):
//   showReportBottomSheet(
//     context,
//     targetType: 'listing',
//     listingId: listing.id,
//     reportedUserId: listing.sellerId,
//   );
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showReportBottomSheet(
  BuildContext context, {
  required String targetType,
  String? listingId,
  String? serviceId,
  String? hiringPostId,
  String? reportedUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    barrierColor: Colors.black54,
    builder: (ctx) => _ReportSheet(
      targetType: targetType,
      listingId: listingId,
      serviceId: serviceId,
      hiringPostId: hiringPostId,
      reportedUserId: reportedUserId,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReportSheet
// ─────────────────────────────────────────────────────────────────────────────

class _ReportSheet extends StatefulWidget {
  final String targetType;
  final String? listingId;
  final String? serviceId;
  final String? hiringPostId;
  final String? reportedUserId;

  const _ReportSheet({
    required this.targetType,
    this.listingId,
    this.serviceId,
    this.hiringPostId,
    this.reportedUserId,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  /// Returns true only when "Other" is selected and the details field is empty.
  bool get _detailsRequired =>
      _selectedReason != null &&
      _selectedReason!.startsWith('Other') &&
      _detailsController.text.trim().isEmpty;

  Future<void> _submit(OnemarketAppState state, AppStrings s) async {
    // Auth guard — redirect to sign-in sheet.
    if (!state.isSignedIn) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showAuthGateSheet(context, reason: AuthGateReason.generic);
      return;
    }

    if (_selectedReason == null) return;

    if (_detailsRequired) {
      setState(() => _error = s.reportDetailsRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await state.submitReport(
        reason: _selectedReason!,
        targetType: widget.targetType,
        listingId: widget.listingId,
        serviceId: widget.serviceId,
        hiringPostId: widget.hiringPostId,
        reportedUserId: widget.reportedUserId,
        details: _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.reportSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final isDuplicate = msg.contains('unique') ||
          msg.contains('duplicate') ||
          msg.contains('23505') ||
          msg.contains('23p01'); // Postgres unique violation codes
      setState(() {
        _submitting = false;
        _error = isDuplicate ? s.reportAlreadyReported : s.reportError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    // Build reason list using translated labels.
    final reasons = <String>[
      s.reportReasonSpam,
      s.reportReasonMisleading,
      s.reportReasonInappropriate,
      s.reportReasonHarassment,
      s.reportReasonOther,
    ];

    // Self-report guard — silently blocked with a message.
    final isSelf = state.isSignedIn &&
        widget.reportedUserId != null &&
        state.currentUser?.id == widget.reportedUserId;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.reportTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.reportSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Self-report block ────────────────────────────────────────
            if (isSelf) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: cs.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.reportSelfNotAllowed,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // ── Not signed-in hint ─────────────────────────────────────
              if (!state.isSignedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: cs.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.reportLoginRequired,
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Reason chips ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((reason) {
                    final selected = _selectedReason == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      selected: selected,
                      onSelected: (v) {
                        if (v) setState(() => _selectedReason = reason);
                      },
                      selectedColor:
                          cs.primaryContainer.withValues(alpha: 0.6),
                      checkmarkColor: cs.primary,
                      labelStyle: TextStyle(
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Details text field (always shown; required for "Other") ─
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _detailsController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 400,
                  decoration: InputDecoration(
                    labelText: s.reportDetailsLabel,
                    hintText: s.reportDetailsHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _detailsRequired ? s.reportDetailsRequired : null,
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) {
                    // Clear "details required" error as the user types.
                    if (_error == s.reportDetailsRequired) {
                      setState(() => _error = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),

              // ── Error banner ──────────────────────────────────────────
              if (_error != null && _error != s.reportDetailsRequired)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: cs.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // ── Submit button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: FilledButton(
                  onPressed: (_submitting || _selectedReason == null)
                      ? null
                      : () => _submit(state, s),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: cs.error,
                    disabledBackgroundColor:
                        cs.error.withValues(alpha: 0.4),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onError,
                          ),
                        )
                      : Text(
                          s.reportSubmit,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onError,
                          ),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
