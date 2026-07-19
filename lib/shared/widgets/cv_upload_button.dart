import 'package:flutter/material.dart';

import '../models/syncable_entity.dart';
import '../services/app_state.dart';
import '../services/cv_upload_service.dart';
import 'sync_status_badge.dart';

/// A self-contained CV upload control.
///
/// Shows:
/// - A labelled button (never icon-only) to pick a file.
/// - A pending [SyncStatusBadge] when the upload is queued offline.
/// - A file-too-large error message (from [app_strings]) when the limit is exceeded.
/// - The current file name when a CV is attached.
///
/// Calls [onUploaded] with (remoteUrl) when the upload completes online,
/// or (null) with status = pending when queued offline.
class CvUploadButton extends StatefulWidget {
  const CvUploadButton({
    super.key,
    required this.serviceId,
    this.currentCvUrl,
    required this.onResult,
  });

  /// The service this CV is for. Used as the Supabase Storage path prefix.
  final String serviceId;

  /// Currently stored remote URL (if any).
  final String? currentCvUrl;

  /// Called after every pick attempt with the result.
  final void Function(CvUploadResult result) onResult;

  @override
  State<CvUploadButton> createState() => _CvUploadButtonState();
}

class _CvUploadButtonState extends State<CvUploadButton> {
  bool _isUploading = false;
  String? _pendingFileName;
  SyncStatus? _pendingStatus;
  String? _errorMessage;

  Future<void> _pick() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    final s = KoolanAppStateScope.of(context).s;
    final result = await CvUploadService.instance.pickAndUpload(
      serviceId: widget.serviceId,
    );

    if (!mounted) return;

    switch (result) {
      case CvUploadCancelled():
        // No-op — user dismissed picker.
        break;
      case CvUploadTooLarge(fileSizeBytes: final size):
        setState(() {
          _errorMessage =
              '${s.servicesCvTooLarge} (${(size / 1024 / 1024).toStringAsFixed(1)} MB / '
              '${(kCvMaxBytes / 1024 / 1024).toInt()} MB max)';
        });
      case CvUploadQueued(
          fileName: final name,
          status: final status,
        ):
        setState(() {
          _pendingFileName = name;
          _pendingStatus = status;
        });
      case CvUploadError(message: final msg):
        setState(() => _errorMessage = msg);
    }

    widget.onResult(result);
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    final hasFile =
        _pendingFileName != null || widget.currentCvUrl != null;
    final displayName = _pendingFileName ??
        widget.currentCvUrl?.split('/').last ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Upload / change button — always labelled ───────────────────────
        FilledButton.icon(
          icon: _isUploading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : const Icon(Icons.upload_file),
          label: Text(
            hasFile ? s.servicesChangeCv : s.servicesUploadCv,
          ),
          onPressed: _isUploading ? null : _pick,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),

        // ── Current file row + sync badge ──────────────────────────────────
        if (hasFile) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.description, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${s.servicesCurrentCv}: $displayName',
                  style: TextStyle(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_pendingStatus != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SyncStatusBadge(status: _pendingStatus!),
                ),
            ],
          ),
        ],

        // ── Error message ──────────────────────────────────────────────────
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: TextStyle(color: cs.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
