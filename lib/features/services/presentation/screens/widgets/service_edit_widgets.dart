part of '../service_edit_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CV Preview Card
// Shows the existing CV filename, a copy-URL action, and an inline preview
// note — without requiring url_launcher.
// ─────────────────────────────────────────────────────────────────────────────

class _CvPreviewCard extends StatelessWidget {
  final String cvUrl;
  final ColorScheme cs;
  final dynamic s; // AppStrings

  const _CvPreviewCard({
    required this.cvUrl,
    required this.cs,
    required this.s,
  });

  String get _fileName {
    final parts = cvUrl.split('/');
    return parts.isNotEmpty ? parts.last : cvUrl;
  }

  bool get _isImage {
    final ext = cvUrl.toLowerCase().split('.').last.split('?').first;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  void _showPreviewDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding:
            const EdgeInsets.fromLTRB(16, 16, 16, 8),
        title: Row(
          children: [
            Icon(Icons.description_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'CV Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview if it's an image file
            if (_isImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  cvUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: cs.outline, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // File name
            Text(
              _fileName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // URL (truncated)
            Text(
              cvUrl,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Copy URL chip
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: cvUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded,
                        size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Copy link',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPreviewDialog(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isImage
                    ? Icons.image_rounded
                    : Icons.picture_as_pdf_rounded,
                color: cs.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current CV',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fileName,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to preview',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.visibility_rounded,
                color: cs.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image picker sub-widgets (shared with edit_listing_screen pattern)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface));
  }
}

class _RemoteImageTile extends StatelessWidget {
  final String url;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _RemoteImageTile(
      {required this.url, required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedImageWidget(
            imageUrl: url,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 120,
              height: 120,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded,
                  color: cs.outline, size: 28),
            ),
          ),
        ),
        _RemoveButton(cs: cs, onRemove: onRemove),
      ],
    );
  }
}

class _LocalImageTile extends StatelessWidget {
  final String path;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _LocalImageTile(
      {required this.path, required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              height: 120,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded,
                  color: cs.outline, size: 28),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('New',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary)),
          ),
        ),
        _RemoveButton(cs: cs, onRemove: onRemove),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _RemoveButton({required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          decoration:
              BoxDecoration(color: cs.error, shape: BoxShape.circle),
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 14, color: cs.onError),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onTap;
  final String? label;
  const _AddTile({required this.cs, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: label != null ? 160 : 120,
        height: 120,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 28, color: cs.primary),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(label!,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
