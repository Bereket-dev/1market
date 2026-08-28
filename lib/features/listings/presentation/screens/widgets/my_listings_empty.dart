part of '../my_listings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMyListings extends StatelessWidget {
  final OnemarketAppState state;
  final ColorScheme cs;
  const _EmptyMyListings({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(
                Icons.storefront_outlined,
                size: 52,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No listings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Post a car, house, or land plot to start selling or renting on the marketplace.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => state.pushScreen(PostWizardScreenRoute()),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Post a Listing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

