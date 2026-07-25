part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Overlay circle button  (back / share on hero image)
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OverlayCircleButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save pill  (bookmark toggle on hero image)
// ─────────────────────────────────────────────────────────────────────────────

class _SavePill extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _SavePill({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final saved = listing.isSaved;
    return Material(
      color: saved
          ? Colors.redAccent.withValues(alpha: 0.85)
          : Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Auth gate: saving a listing requires sign-in.
          if (!state.isSignedIn) {
            showAuthGateSheet(context, reason: AuthGateReason.save);
            return;
          }
          state.toggleSaveListing(listing.id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                saved ? 'Saved' : 'Save',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Condition pill  (bottom-left of hero image)
// ─────────────────────────────────────────────────────────────────────────────

class _ConditionPill extends StatelessWidget {
  final String label;
  const _ConditionPill({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento spec box
// ─────────────────────────────────────────────────────────────────────────────

class _BentoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BentoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Translated badge  (inline with title when machine-translated)
// ─────────────────────────────────────────────────────────────────────────────

class _TranslatedBadge extends StatelessWidget {
  final AppStrings s;
  const _TranslatedBadge({required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: s.translatedTooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: cs.tertiary.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 11, color: cs.tertiary),
            const SizedBox(width: 4),
            Text(
              s.translatedBadge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
