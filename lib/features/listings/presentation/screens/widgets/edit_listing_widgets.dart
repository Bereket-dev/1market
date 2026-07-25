part of '../edit_listing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
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
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 100,
              height: 100,
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
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 100,
              height: 100,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded,
                  color: cs.outline, size: 28),
            ),
          ),
        ),
        // "New" badge
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
        width: label != null ? 140 : 100,
        height: 100,
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
