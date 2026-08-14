part of '../service_edit_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CV Preview Card
// Shows the existing CV filename and opens a real preview / external viewer.
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => CvViewer.open(context, cvUrl),
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
                CvViewer.isImageUrl(cvUrl)
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
                    s.servicesCurrentCv,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CvViewer.fileName(cvUrl),
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
                    s.servicesCvTapToPreview,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.visibility_rounded, color: cs.primary, size: 18),
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
