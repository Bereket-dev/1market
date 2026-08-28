part of '../post_wizard_screen.dart';

class _PhotosSection extends StatelessWidget {
  final OnemarketAppState state;
  final VoidCallback onRebuild;
  const _PhotosSection({required this.state, required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    final paths = state.postImagePaths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Count indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel(
              label: s.wizardPhotosLabel,
              isRequired: false,
              requiredSuffix: s.wizardRequired,
            ),
            Text(
              '${paths.length}/8',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal thumbnail strip + add button
        if (paths.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: paths.length + (paths.length < 8 ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == paths.length) {
                  return _AddImageButton(
                    onTap: () async {
                      await state.pickListingImages(context);
                      onRebuild();
                    },
                    cs: cs,
                    label: s.wizardAttachMedia,
                  );
                }
                return _ImageThumbnail(
                  path: paths[index],
                  cs: cs,
                  onRemove: () {
                    state.removeListingImage(index);
                    onRebuild();
                  },
                );
              },
            ),
          ),

        // Full-width upload zone when no images yet
        if (paths.isEmpty)
          InkWell(
            onTap: () async {
              await state.pickListingImages(context);
              onRebuild();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 40, color: cs.primary),
                  const SizedBox(height: 8),
                  Text(
                    s.wizardAttachMedia,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.wizardMediaHint,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant
                            .withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String path;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _ImageThumbnail(
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
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: BoxDecoration(
                  color: cs.error, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 14, color: cs.onError),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  final String label;
  const _AddImageButton(
      {required this.onTap, required this.cs, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 28, color: cs.primary),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit footer — single CTA button + offline banner
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitFooter extends StatelessWidget {
  final OnemarketAppState state;
  final double bottom;
  final VoidCallback onSubmit;
  const _SubmitFooter({
    required this.state,
    required this.bottom,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    final isUploading = state.isUploadingListingImages;

    return Container(
      color: cs.surface,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Offline warning banner
          _OfflineBanner(state: state),

          const SizedBox(height: 8),

          // Submit button
          FilledButton.icon(
            onPressed: isUploading ? null : onSubmit,
            icon: isUploading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.onPrimary,
                    ),
                  )
                : Icon(Icons.check_rounded),
            label: Text(
              s.wizardSubmit,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline banner — shown when device is offline
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final OnemarketAppState state;
  const _OfflineBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;

    // dataError is set by submitPost on network failure;
    // show the offline message so the user knows the draft will sync later.
    if (state.dataError == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.wizardOfflineBanner,
              style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
