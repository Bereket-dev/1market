import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../cars/presentation/widgets/car_card.dart';
import 'compare_overlay.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _showCompareOverlay = false;

  /// null = show all categories
  String? _activeCategory;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs    = Theme.of(context).colorScheme;
    final all   = state.getSavedListings();

    // Derive the distinct categories present in the saved list
    final categories = all.map((l) => l.category).toSet().toList()..sort();

    // Apply category filter
    final shown = _activeCategory == null
        ? all
        : all.where((l) => l.category == _activeCategory).toList();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              _Header(
                state: state,
                cs: cs,
                compareModeEnabled: state.compareModeEnabled,
              ),

              // ── Category filter chips (only shown when > 1 category) ─────
              if (all.isNotEmpty && categories.length > 1)
                _CategoryChips(
                  categories: categories,
                  active: _activeCategory,
                  onSelect: (cat) =>
                      setState(() => _activeCategory = cat),
                ),

              // ── Compare mode info banner ──────────────────────────────────
              if (state.compareModeEnabled && all.isNotEmpty)
                _CompareBanner(state: state, cs: cs),

              // ── Main content ──────────────────────────────────────────────
              if (all.isEmpty)
                _EmptyState(state: state, cs: cs)
              else if (shown.isEmpty)
                _FilterEmptyState(cs: cs)
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = shown[index];
                      final isChosen =
                          state.selectedCompareIds.contains(item.id);
                      return _SavedListingTile(
                        listing: item,
                        state: state,
                        isChosen: isChosen,
                      );
                    },
                  ),
                ),
            ],
          ),

          // ── Floating compare action bar ───────────────────────────────────
          if (state.compareModeEnabled && state.selectedCompareIds.isNotEmpty)
            _CompareActionBar(
              state: state,
              cs: cs,
              onCompare: () => setState(() => _showCompareOverlay = true),
            ),

          // ── Compare overlay ───────────────────────────────────────────────
          if (_showCompareOverlay && state.selectedCompareIds.length == 2)
            CompareOverlay(
              listings: all
                  .where((l) => state.selectedCompareIds.contains(l.id))
                  .toList(),
              onClose: () => setState(() => _showCompareOverlay = false),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  final bool compareModeEnabled;

  const _Header({
    required this.state,
    required this.cs,
    required this.compareModeEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.s.savedTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: cs.primary,
              ),
            ),
          ),
          // Compare button with icon + label so it's self-explanatory
          InkWell(
            onTap: state.toggleCompareMode,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: compareModeEnabled
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: compareModeEnabled
                      ? cs.primary.withValues(alpha: 0.5)
                      : cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.compare_arrows_rounded,
                    size: 18,
                    color:
                        compareModeEnabled ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.s.savedCompare,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: compareModeEnabled
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? active;
  final ValueChanged<String?> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.active,
    required this.onSelect,
  });

  static IconData _icon(String cat) => switch (cat.toUpperCase()) {
        'CARS'   => Icons.directions_car_rounded,
        'HOUSES' => Icons.home_rounded,
        'LAND'   => Icons.landscape_rounded,
        'SKILLS' => Icons.construction_rounded,
        _        => Icons.inventory_2_outlined,
      };

  String _label(String cat, AppStrings s) => switch (cat.toUpperCase()) {
        'CARS'   => s.savedCatCars,
        'HOUSES' => s.savedCatHouses,
        'LAND'   => s.savedCatLand,
        'SKILLS' => s.savedCatSkills,
        _        => cat,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = KoolanAppStateScope.of(context).s;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _Chip(
            label: s.savedCatAll,
            icon: Icons.apps_rounded,
            selected: active == null,
            cs: cs,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...categories.expand((cat) => [
                _Chip(
                  label: _label(cat, s),
                  icon: _icon(cat),
                  selected: active == cat,
                  cs: cs,
                  onTap: () => onSelect(active == cat ? null : cat),
                ),
                const SizedBox(width: 8),
              ]),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compare mode info banner
// ─────────────────────────────────────────────────────────────────────────────

class _CompareBanner extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  const _CompareBanner({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    final count = state.selectedCompareIds.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.s.savedCompareInfo
                  .replaceAll('{count}', '$count'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
          // Quick exit from compare mode
          GestureDetector(
            onTap: state.toggleCompareMode,
            child: Icon(Icons.close_rounded,
                size: 16, color: cs.primary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saved listing tile  – horizontal layout: image | info | actions
// ─────────────────────────────────────────────────────────────────────────────

class _SavedListingTile extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  final bool isChosen;

  const _SavedListingTile({
    required this.listing,
    required this.state,
    required this.isChosen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inCompare = state.compareModeEnabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isChosen && inCompare
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: isChosen && inCompare ? 2.5 : 1,
        ),
        color: isChosen && inCompare
            ? cs.primaryContainer.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (inCompare) {
            state.toggleCompareSelection(listing.id);
          } else {
            state.pushScreen(ListingDetailScreenRoute(listing.id));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────────────
              _Thumbnail(listing: listing, isChosen: isChosen && inCompare),

              const SizedBox(width: 12),

              // ── Info ───────────────────────────────────────────────────
              Expanded(
                child: _TileInfo(listing: listing, state: state),
              ),

              const SizedBox(width: 8),

              // ── Actions column ─────────────────────────────────────────
              _TileActions(
                listing: listing,
                state: state,
                isChosen: isChosen && inCompare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Listing listing;
  final bool isChosen;
  const _Thumbnail({required this.listing, required this.isChosen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SavedListingImage(
            imageUrl: listing.imageUrl,
            width: 90,
            height: 90,
          ),
        ),
        if (isChosen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cs.primary.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: cs.primary,
                child: Icon(Icons.check_rounded,
                    size: 16, color: cs.onPrimary),
              ),
            ),
          ),
      ],
    );
  }
}

class _TileInfo extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _TileInfo({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price
        Text(
          listing.price,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 2),

        // Title
        Text(
          listing.titleForLocale(state.locale),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // Condition + spec chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _SmallPill(
              label: listing.conditionOrStatus,
              color: cs.primaryContainer,
              textColor: cs.onPrimaryContainer,
            ),
            if (listing.spec1Label != null && listing.spec1Value != null)
              _SmallPill(
                label: listing.spec1Value!,
                color: cs.surfaceContainerHighest,
                textColor: cs.onSurfaceVariant,
                border: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            if (listing.spec2Label != null && listing.spec2Value != null)
              _SmallPill(
                label: listing.spec2Value!,
                color: cs.surfaceContainerHighest,
                textColor: cs.onSurfaceVariant,
                border: cs.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Location
        Row(
          children: [
            Icon(Icons.location_on_rounded,
                size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                listing.location.split(',')[0],
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TileActions extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  final bool isChosen;

  const _TileActions({
    required this.listing,
    required this.state,
    required this.isChosen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Unsave button
        GestureDetector(
          onTap: () => state.toggleSaveListing(listing.id),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_remove_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Verified badge if applicable
        if (listing.verified)
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: cs.tertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.verified_rounded, size: 16, color: cs.tertiary),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating compare action bar
// ─────────────────────────────────────────────────────────────────────────────

class _CompareActionBar extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  final VoidCallback onCompare;

  const _CompareActionBar({
    required this.state,
    required this.cs,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final count   = state.selectedCompareIds.length;
    final ready   = count == 2;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        color: cs.inverseSurface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Selection indicators
              Row(
                children: List.generate(
                  2,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: i < count
                            ? cs.primary
                            : cs.onInverseSurface.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        i < count ? Icons.check_rounded : Icons.add_rounded,
                        size: 16,
                        color: i < count
                            ? cs.onPrimary
                            : cs.onInverseSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.s.savedSelectedCount
                          .replaceAll('{count}', '$count'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.onInverseSurface,
                      ),
                    ),
                    Text(
                      ready
                          ? state.s.savedReadyAnalyse
                          : state.s.savedChooseOne,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            cs.onInverseSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),

              // Compare button
              FilledButton.icon(
                onPressed: ready ? onCompare : null,
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: Text(
                  state.s.savedCompareButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ready ? cs.primary : null,
                  foregroundColor: ready ? cs.onPrimary : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
// Empty states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final KoolanAppState state;
  final ColorScheme cs;
  const _EmptyState({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: cs.surfaceContainerHighest,
                child: Icon(
                  Icons.bookmark_border_rounded,
                  size: 52,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.s.savedEmpty,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.s.savedEmptySubAlt,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => state.pushScreen(HomeScreenRoute()),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(state.s.savedBrowse),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  final ColorScheme cs;
  const _FilterEmptyState({required this.cs});

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_rounded,
                size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              s.savedFilterEmpty,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pill chip  (used in tile info)
// ─────────────────────────────────────────────────────────────────────────────

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color? border;

  const _SmallPill({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
