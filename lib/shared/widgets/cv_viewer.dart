import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/app_state.dart';

/// Opens a CV URL inside the app. Images use a preview dialog; PDFs use the in-app viewer.
class CvViewer {
  CvViewer._();

  static bool isImageUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.contains('/image/upload/');
  }

  static String fileName(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final parts = path.split('/');
    final last = parts.isNotEmpty ? parts.last : url;
    return last.isNotEmpty ? last : url;
  }

  /// Preview images and PDFs inside the app.
  static Future<void> open(BuildContext context, String url) async {
    if (url.isEmpty) return;
    if (isImageUrl(url)) {
      await _showImagePreview(context, url);
      return;
    }
    await _showPdfPreview(context, url);
  }

  static Future<void> copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    final s = OnemarketAppStateScope.of(context).s;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.servicesCvLinkCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<void> _showPdfPreview(BuildContext context, String url) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _CvPdfScreen(url: url)));
  }

  static Future<void> _showImagePreview(BuildContext context, String url) {
    final s = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        title: Row(
          children: [
            Icon(Icons.description_rounded, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.servicesCvPreviewTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    errorBuilder: (_, _, _) => Container(
                      height: 120,
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: cs.outline,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fileName(url),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => copyLink(context, url),
            child: Text(s.servicesCvCopyLink),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.servicesCvClose),
          ),
        ],
      ),
    );
  }
}

class _CvPdfScreen extends StatelessWidget {
  final String url;
  const _CvPdfScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          CvViewer.fileName(url),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: state.s.servicesCvCopyLink,
            icon: const Icon(Icons.link_rounded),
            onPressed: () => CvViewer.copyLink(context, url),
          ),
        ],
      ),
      body: ColoredBox(
        color: cs.surface,
        child: SfPdfViewer.network(
          url,
          onDocumentLoadFailed: (details) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.s.servicesCvOpenFailed)),
            );
          },
          canShowScrollHead: true,
          canShowScrollStatus: true,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          enableDoubleTapZooming: true,
          interactionMode: PdfInteractionMode.pan,
          scrollDirection: PdfScrollDirection.vertical,
          initialZoomLevel: 1.0,
        ),
      ),
    );
  }
}
