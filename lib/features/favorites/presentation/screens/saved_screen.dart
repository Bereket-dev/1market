import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/router/routes.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final savedListings = state.getSavedListings();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.s.savedTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: kPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.compare_arrows, color: kPrimary),
                      onPressed: state.toggleCompareMode,
                      style: IconButton.styleFrom(
                        backgroundColor: state.compareModeEnabled
                            ? kPrimary.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Empty state ──────────────────────────────────────────────────
              if (savedListings.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: kSurfaceContainerLow,
                            child: Icon(
                              Icons.bookmark_border,
                              size: 48,
                              color: kOnSurfaceVariant.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.s.savedEmpty,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the bookmark icon on any item you love to '
                            'save it here and keep track of your favourites.',
                            style: TextStyle(
                              fontSize: 13,
                              color: kOnSurfaceVariant.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                if (state.compareModeEnabled)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Select up to 2 items to compare side-by-side. '
                      '(${state.selectedCompareIds.length}/2 selected)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    itemCount: savedListings.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = savedListings[index];
                      final isChosen =
                          state.selectedCompareIds.contains(item.id);

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isChosen && state.compareModeEnabled
                                    ? kPrimary
                                    : Colors.transparent,
                                width: isChosen && state.compareModeEnabled
                                    ? 3
                                    : 0,
                              ),
                            ),
                            child: PremiumClassifiedCard(
                              listing: item,
                              onSaveToggle: () =>
                                  state.toggleSaveListing(item.id),
                              onTap: () {
                                if (state.compareModeEnabled) {
                                  state.toggleCompareSelection(item.id);
                                } else {
                                  state.pushScreen(
                                      ListingDetailScreenRoute(item.id));
                                }
                              },
                            ),
                          ),
                          if (isChosen && state.compareModeEnabled)
                            const Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: kPrimary,
                                child: Icon(Icons.check,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

          // ── Floating compare bar ─────────────────────────────────────────
          if (state.compareModeEnabled &&
              state.selectedCompareIds.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.selectedCompareIds.length} items selected',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            state.selectedCompareIds.length < 2
                                ? 'Choose 1 more item'
                                : 'Ready to analyse',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: state.selectedCompareIds.length == 2
                            ? () =>
                                setState(() => _showCompareOverlay = true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryContainer,
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          state.s.savedCompareButton,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Compare overlay ───────────────────────────────────────────────
          if (_showCompareOverlay &&
              state.selectedCompareIds.length == 2)
            CompareOverlay(
              listings: savedListings
                  .where((l) =>
                      state.selectedCompareIds.contains(l.id))
                  .toList(),
              onClose: () =>
                  setState(() => _showCompareOverlay = false),
            ),
        ],
      ),
    );
  }
}
