part of '../profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile screen header widgets: avatar/name card, stats, tab bar
// ─────────────────────────────────────────────────────────────────────────────

/// Circular avatar with camera badge and optional upload spinner.
class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final bool uploading;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.displayName,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: cs.primary,
            child: uploading
                ? const CircularProgressIndicator(color: Colors.white)
                : (avatarUrl != null
                    ? CachedCircularImage(imageUrl: avatarUrl!, radius: 52)
                    : CircleAvatar(
                        radius: 52,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      )),
          ),
          if (!uploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                padding: const EdgeInsets.all(6),
                child:
                    Icon(Icons.camera_alt_rounded, size: 16, color: cs.onPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Display name row with inline edit pencil.
class _ProfileNameRow extends StatelessWidget {
  final String displayName;
  final String city;
  final VoidCallback onEdit;

  const _ProfileNameRow({
    required this.displayName,
    required this.city,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: s.editProfileEditName,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined,
                      size: 18,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.65)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(city, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ],
    );
  }
}

/// Stats card: rating, services count, listings count.
class _ProfileStatsCard extends StatelessWidget {
  final double? rating;
  final int? reviewsCount;
  final int servicesCount;
  final int listingsCount;

  const _ProfileStatsCard({
    required this.rating,
    required this.reviewsCount,
    required this.servicesCount,
    required this.listingsCount,
  });

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatCell(
              value: rating?.toStringAsFixed(1) ?? '—',
              label: s.profileReviews,
              icon: Icons.star,
              iconColor: Colors.amber,
              sub: reviewsCount != null
                  ? '$reviewsCount ${s.profileReviews}'
                  : null,
            ),
            Container(
                width: 1,
                height: 30,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
            _StatCell(value: '$servicesCount', label: s.profileTabServices),
            Container(
                width: 1,
                height: 30,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
            _StatCell(value: '$listingsCount', label: s.profileTabListings),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable tab bar for Services / Listings / About / Reviews.
class _ProfileTabBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabSelected;

  const _ProfileTabBar({
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    const tabs = ['Services', 'Listings', 'About', 'Reviews'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSel = activeTab == tab;
          final label = switch (tab) {
            'Services' => s.profileTabServices,
            'Listings' => s.profileTabListingsLong,
            'About'    => s.profileTabAbout,
            _          => s.profileTabReviews,
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () => onTabSelected(tab),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSel ? cs.primary : cs.surfaceContainerHighest,
                foregroundColor:
                    isSel ? cs.onPrimary : cs.onSurfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
