import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_state.dart';

/// Opens a CV URL: image files preview in-app, PDFs/other files open externally.
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

  /// Preview images in a dialog; open PDFs and other files in an external app.
  static Future<void> open(BuildContext context, String url) async {
    if (url.isEmpty) return;
    if (isImageUrl(url)) {
      await _showImagePreview(context, url);
      return;
    }
    await openExternal(context, url);
  }

  static Future<void> openExternal(BuildContext context, String url) async {
    final s = KoolanAppStateScope.of(context).s;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      _showFailed(context, s.servicesCvOpenFailed);
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showFailed(context, s.servicesCvOpenFailed);
      }
    } catch (_) {
      if (context.mounted) _showFailed(context, s.servicesCvOpenFailed);
    }
  }

  static Future<void> copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    final s = KoolanAppStateScope.of(context).s;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.servicesCvLinkCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<void> _showImagePreview(BuildContext context, String url) {
    final s = KoolanAppStateScope.of(context).s;
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
            onPressed: () {
              Navigator.of(ctx).pop();
              openExternal(context, url);
            },
            child: Text(s.servicesDetailCvView),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.servicesCvClose),
          ),
        ],
      ),
    );
  }

  static void _showFailed(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
