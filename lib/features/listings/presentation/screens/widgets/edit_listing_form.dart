part of '../edit_listing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Form widgets for EditListingScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal scrollable image row: remote tiles, new-local tiles, add button.
class _ImagesRow extends StatelessWidget {
  final List<String> existingUrls;
  final List<String> newPaths;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  const _ImagesRow({
    required this.existingUrls,
    required this.newPaths,
    required this.onPickImages,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  int get _totalCount => existingUrls.length + newPaths.length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int i = 0; i < existingUrls.length; i++) ...[
            _RemoteImageTile(
              url: existingUrls[i],
              cs: cs,
              onRemove: () => onRemoveExisting(i),
            ),
            const SizedBox(width: 8),
          ],
          for (int i = 0; i < newPaths.length; i++) ...[
            _LocalImageTile(
              path: newPaths[i],
              cs: cs,
              onRemove: () => onRemoveNew(i),
            ),
            const SizedBox(width: 8),
          ],
          if (_totalCount < 8)
            _AddTile(
              cs: cs,
              label: _totalCount == 0 ? 'Add Photos' : null,
              onTap: onPickImages,
            ),
        ],
      ),
    );
  }
}

/// Styled [TextFormField] used for every text field in [EditListingScreen].
class _ListingField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _ListingField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
      ),
      validator: validator,
    );
  }
}
