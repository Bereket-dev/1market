import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
part 'widgets/my_listings_tiles.dart';
part 'widgets/my_listings_empty.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MyListingsScreen
//
// Shows the current user's own marketplace posts (CARS / HOUSES / LAND).
// Each tile lets the user:
//   • View the live detail page
//   • Delete their post (with confirmation)
//
// "Post a new listing" navigates to the wizard.
// ─────────────────────────────────────────────────────────────────────────────

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final cs    = Theme.of(context).colorScheme;
    final posts = state.getMyListings();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => state.popScreen(),
        ),
        title: Text(
          state.s.profileTabListingsLong,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          // Quick shortcut to post a new listing
          TextButton.icon(
            onPressed: () => state.pushScreen(PostWizardScreenRoute()),
            icon: Icon(Icons.add_rounded, size: 18, color: cs.primary),
            label: Text(
              state.s.profileNewPost,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
      body: posts.isEmpty
          ? _EmptyMyListings(state: state, cs: cs)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _MyListingTile(
                listing: posts[index],
                state: state,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
