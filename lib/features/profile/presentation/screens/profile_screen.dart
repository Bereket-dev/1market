import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/onemarket_cities.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
part 'widgets/profile_stats.dart';
part 'widgets/profile_services_tab.dart';
part 'widgets/profile_listings_tab.dart';
part 'widgets/profile_header.dart';
part 'widgets/profile_about_reviews.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'Services';

  /// Shows a snackbar with [message].
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Picks a profile photo and uploads it; shows a loading overlay while busy.
  Future<void> _pickAvatar(OnemarketAppState state) async {
    setState(() => _avatarUploading = true);
    try {
      final err = await state.uploadAvatarImage();
      if (err != null && mounted) _showSnack(err);
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  bool _avatarUploading = false;

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final profile = state.profile;
    final myListings = state.getMyListings();

    final displayName = profile?.displayName ?? 'Your Name';
    final avatarUrl = profile?.avatarUrl;
    final city = profile?.city ?? OnemarketCities.launchDefault;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: state.s.settingsTitle,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => state.pushScreen(SettingsScreenRoute()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                    // ── Avatar with camera badge ─────────────────────────────
                    GestureDetector(
                      onTap: _avatarUploading ? null : () => _pickAvatar(state),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Avatar circle
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: cs.primary,
                            child: _avatarUploading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : (avatarUrl != null
                                    ? CachedCircularImage(
                                        imageUrl: avatarUrl, radius: 52)
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
                          // Camera badge — bottom-right
                          if (!_avatarUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cs.surface,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: cs.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Name row with inline-edit pencil ────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Pencil button — navigates to the full edit profile screen
                        const SizedBox(width: 4),
                        Tooltip(
                          message: state.s.editProfileEditName,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                state.pushScreen(EditProfileScreenRoute()),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.65),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      city,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Edit Profile text button
                    OutlinedButton.icon(
                      onPressed: () => state.pushScreen(EditProfileScreenRoute()),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(state.s.editProfileTitle),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats card
                    Card(
                      color: cs.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatCell(
                              value: profile?.rating.toStringAsFixed(1) ?? '—',
                              label: state.s.profileReviews,
                              icon: Icons.star,
                              iconColor: Colors.amber,
                              sub: profile != null
                                  ? '${profile.reviewsCount} ${state.s.profileReviews}'
                                  : null,
                            ),
                            Container(
                                width: 1,
                                height: 30,
                                color: cs.outlineVariant.withValues(alpha: 0.5)),
                            _StatCell(
                              value: '${state.getMyServices().length}',
                              label: state.s.profileTabServices,
                            ),
                            Container(
                                width: 1,
                                height: 30,
                                color: cs.outlineVariant.withValues(alpha: 0.5)),
                            _StatCell(
                              value: '${myListings.length}',
                              label: state.s.profileTabListings,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Services',
                          'Listings',
                          'About',
                          'Reviews',
                        ].map((tab) {
                          final isSel = _activeTab == tab;
                          final label = switch (tab) {
                            'Services' => state.s.profileTabServices,
                            'Listings' => state.s.profileTabListingsLong,
                            'About' => state.s.profileTabAbout,
                            _ => state.s.profileTabReviews,
                          };
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => _activeTab = tab),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSel
                                    ? cs.primary
                                    : cs.surfaceContainerHighest,
                                foregroundColor: isSel
                                    ? cs.onPrimary
                                    : cs.onSurfaceVariant,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTabContent(state, myListings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(OnemarketAppState state, List<Listing> myListings) {
    switch (_activeTab) {
      case 'Services':
        return _ServicesTab(
          services: state.getMyServices(),
          onManageTap: () => state.pushScreen(ServiceManagementScreenRoute()),
          onAddServiceTap: () => state.pushScreen(ServiceEditScreenRoute(null)),
          onMyHiringPostsTap: () =>
              state.pushScreen(HiringManagementScreenRoute()),
          onMyApplicationsTap: () =>
              state.pushScreen(MyApplicationsScreenRoute()),
          hiringPostCount: state.getMyHiringPosts().length,
          applicationCount: state.myApplications.length,
        );
      case 'Listings':
        return _ListingsTab(
          listings: myListings,
          onManageTap: () => state.pushScreen(MyListingsScreenRoute()),
          onPostTap: () => state.pushScreen(PostWizardScreenRoute()),
        );
      case 'About':
        return _AboutTab(bio: state.profile?.bio);
      default:
        return _ReviewsTab(state: state);
    }
  }
}

// ── Stat cell widget ──────────────────────────────────────────────────────────
