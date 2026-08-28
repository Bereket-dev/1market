import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../cars/presentation/widgets/car_card.dart';
import 'compare_overlay.dart';
part 'widgets/saved_tiles.dart';
part 'widgets/saved_header.dart';
part 'widgets/saved_compare.dart';

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
    final state = OnemarketAppStateScope.of(context);
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
