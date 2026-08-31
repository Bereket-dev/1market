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
//   • Edit, unlist/relist, or delete their post
//
// "Post a new listing" navigates to the wizard.
// ─────────────────────────────────────────────────────────────────────────────

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) OnemarketAppStateScope.of(context).loadMyListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final posts = state.getMyListings();
    final listed = posts.where((p) => !p.isHidden).toList();
    final unlisted = posts.where((p) => p.isHidden).toList();

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
              style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
            ),
          ),
        ],
      ),
      body: posts.isEmpty
          ? _EmptyMyListings(state: state, cs: cs)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                if (unlisted.isNotEmpty) ...[
                  _ListingSectionHeader(
                    label: state.s.listingUnlisted,
                    icon: Icons.visibility_off_rounded,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  ...unlisted.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MyListingTile(listing: p, state: state),
                    ),
                  ),
                  if (listed.isNotEmpty) const SizedBox(height: 8),
                ],
                if (listed.isNotEmpty) ...[
                  _ListingSectionHeader(
                    label: state.s.listingListed,
                    icon: Icons.visibility_rounded,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  ...listed.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MyListingTile(listing: p, state: state),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ListingSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;

  const _ListingSectionHeader({
    required this.label,
    required this.icon,
    required this.cs,
  });

  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: cs.onSurfaceVariant),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
