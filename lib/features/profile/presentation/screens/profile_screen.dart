import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

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

  /// Picks a banner image and uploads it; shows a loading overlay while busy.
  Future<void> _pickBanner(KoolanAppState state) async {
    setState(() => _bannerUploading = true);
    try {
      final err = await state.uploadBannerImage();
      // err is null on success or user-cancel; non-null is a real error message.
      if (err != null && mounted) _showSnack(err);
    } finally {
      if (mounted) setState(() => _bannerUploading = false);
    }
  }

  /// Picks a profile photo and uploads it; shows a loading overlay while busy.
  Future<void> _pickAvatar(KoolanAppState state) async {
    setState(() => _avatarUploading = true);
    try {
      final err = await state.uploadAvatarImage();
      if (err != null && mounted) _showSnack(err);
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  bool _bannerUploading = false;
  bool _avatarUploading = false;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final profile = state.profile;
    final myListings = state.getMyListings();

    final displayName = profile?.displayName ?? 'Your Name';
    final avatarUrl = profile?.avatarUrl;
    final bannerUrl = profile?.bannerUrl;
    final city = profile?.city ?? 'Jigjiga';
    final isVerified = profile?.faydaVerified ?? false;

    // Fallback banner when user hasn't set one yet.
    const fallbackBanner =
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Banner ───────────────────────────────────────────────────────
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image (user's own or fallback)
                  CachedImageWidget(
                    imageUrl: bannerUrl ?? fallbackBanner,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.38)),

                  // Settings button — top-right
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => state.pushScreen(SettingsScreenRoute()),
                      ),
                    ),
                  ),

                  // ── Banner edit pencil — top-left ────────────────────────
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _bannerUploading
                        ? const CircleAvatar(
                            backgroundColor: Colors.black38,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            child: IconButton(
                              tooltip: state.s.editProfileChangeBanner,
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _pickBanner(state),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // ── Profile card pulled up over banner ───────────────────────────
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
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
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, color: cs.tertiary, size: 20),
                        ],
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
                              label: 'Listings',
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
                            'Listings' => 'My Listings',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(KoolanAppState state, List<Listing> myListings) {
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

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final String? sub;

  const _StatCell({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      if (icon != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: iconColor ?? cs.primary, size: 16),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface)),
        ])
      else
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface)),
      Text(sub ?? label,
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
    ]);
  }
}

// ── Services tab ──────────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  final List<Service> services;
  final VoidCallback onManageTap;
  final VoidCallback onAddServiceTap;
  final VoidCallback onMyHiringPostsTap;
  final VoidCallback onMyApplicationsTap;
  final int hiringPostCount;
  final int applicationCount;

  const _ServicesTab({
    required this.services,
    required this.onManageTap,
    required this.onAddServiceTap,
    required this.onMyHiringPostsTap,
    required this.onMyApplicationsTap,
    required this.hiringPostCount,
    required this.applicationCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final state = KoolanAppStateScope.of(context);
    final s     = state.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Action buttons ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onManageTap,
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('Manage All'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAddServiceTap,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(s.servicesAddNew),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Service cards ─────────────────────────────────────────────────
        if (services.isEmpty) ...[
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 38,
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(Icons.work_outline,
                size: 36, color: cs.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Text(s.profileNoServices,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(s.profileNoServicesSub,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length > 3 ? 3 : services.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final service = services[index];
              return _ProfileServiceCard(
                service: service,
                onTap: () => state.pushScreen(
                    ServiceDetailScreenRoute(service.id)),
              );
            },
          ),
          if (services.length > 3) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onManageTap,
              child: Text(
                '+ ${services.length - 3} more services',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],

        Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 4),

        _ProfileActionRow(
          icon: Icons.work_outline,
          label: s.profileMyHiringPosts,
          badge: hiringPostCount > 0 ? '$hiringPostCount' : null,
          onTap: onMyHiringPostsTap,
        ),
        const SizedBox(height: 4),
        _ProfileActionRow(
          icon: Icons.send_outlined,
          label: s.profileMyApplications,
          badge: applicationCount > 0 ? '$applicationCount' : null,
          onTap: onMyApplicationsTap,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Rich service preview card used in the profile Services tab.
/// Taps into ServiceDetailScreen.
class _ProfileServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;
  const _ProfileServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final isAvail = service.availability;
    final s       = KoolanAppStateScope.of(context).s;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvail
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: isAvail ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image / placeholder ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: service.imageUrl.isNotEmpty
                  ? CachedImageWidget(
                      imageUrl: service.imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorWidget: _ServicePlaceholder(cs: cs),
                    )
                  : _ServicePlaceholder(cs: cs),
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service.category,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Title
                  Text(
                    service.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Price
                  if (service.priceRange.isNotEmpty)
                    Text(
                      service.priceRange,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: cs.primary),
                    ),
                  const SizedBox(height: 3),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          service.location,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Availability dot + arrow ───────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvail ? cs.primary : cs.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAvail ? s.servicesAvailable : s.servicesUnavailable,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAvail ? cs.primary : cs.error),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _ServicePlaceholder({required this.cs});
  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        color: cs.primaryContainer.withValues(alpha: 0.3),
        child: Icon(Icons.work_outline_rounded,
            color: cs.primary.withValues(alpha: 0.6), size: 28),
      );
}

// ── About tab (no escrow) ─────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final String? bio;
  const _AboutTab({this.bio});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.profileProfSummary,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface)),
      const SizedBox(height: 8),
      Text(
        bio != null && bio!.isNotEmpty
            ? bio!
            : 'No bio added yet. Tap "Edit Profile" to add one.',
        style:
            TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 20),
      Text(s.profileSpecialties,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          'Jigjiga',
          'Verified',
        ].map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(tag,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 11)),
          );
        }).toList(),
      ),
    ]);
  }
}

// ── Reviews tab (real data) ───────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  final KoolanAppState state;
  const _ReviewsTab({required this.state});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  bool _loading = false;
  List<ServiceReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final services = widget.state.getMyServices();
    final all = <ServiceReview>[];
    for (final svc in services) {
      final r = await widget.state.loadReviewsForService(svc.id);
      all.addAll(r);
    }
    // Also surface cached reviews
    if (all.isEmpty) {
      for (final svc in services) {
        all.addAll(widget.state.getReviewsForService(svc.id));
      }
    }
    // Sort newest first
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) setState(() { _reviews = all; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = widget.state.s;

    if (_loading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    if (_reviews.isEmpty) {
      return Column(children: [
        const SizedBox(height: 24),
        Icon(Icons.rate_review_outlined,
            size: 48, color: cs.primary.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(s.reviewsEmpty,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
      ]);
    }

    return Column(
      children: _reviews.map((review) {
        final name = review.reviewerName ?? s.reviewsFallbackUserName;
        final timeAgo = _formatTime(review.createdAt, s);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ReviewCard(
            name: name,
            date: timeAgo,
            comment: review.comment,
            rating: review.rating.toDouble(),
            avatarUrl: review.reviewerAvatarUrl,
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dt, s) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return s.reviewsTimeAgoYears(diff.inDays ~/ 365);
    if (diff.inDays >= 30) return s.reviewsTimeAgoMonths(diff.inDays ~/ 30);
    if (diff.inDays >= 1) return s.reviewsTimeAgoDays(diff.inDays);
    if (diff.inHours >= 1) return s.reviewsTimeAgoHours(diff.inHours);
    return s.reviewsTimeAgoJustNow;
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final String comment;
  final double rating;
  final String? avatarUrl;

  const _ReviewCard({
    required this.name,
    required this.date,
    required this.comment,
    required this.rating,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.35),
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? Text(name[0].toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: cs.primary))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: cs.onSurface)),
                  Text(date,
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                ]),
              ]),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(rating.toStringAsFixed(1),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: cs.onSurface)),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
        ]),
      ),
    );
  }
}

// ── Profile action row ────────────────────────────────────────────────────────

class _ProfileActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _ProfileActionRow({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: cs.onSurface)),
            ),
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.primary)),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Listings tab ──────────────────────────────────────────────────────────────

class _ListingsTab extends StatelessWidget {
  final List<Listing> listings;
  final VoidCallback onManageTap;
  final VoidCallback onPostTap;

  const _ListingsTab({
    required this.listings,
    required this.onManageTap,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final state = KoolanAppStateScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Action buttons ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onManageTap,
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('Manage All'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onPostTap,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Post'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Listing cards ─────────────────────────────────────────────────
        if (listings.isEmpty) ...[
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 38,
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(Icons.storefront_outlined,
                size: 36, color: cs.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Text(
            'No listings yet',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Post a car, house, or land to start selling or renting.',
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listings.length > 3 ? 3 : listings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final l = listings[i];
              return _ProfileListingCard(
                listing: l,
                onTap: () => state.pushScreen(ListingDetailScreenRoute(l.id)),
              );
            },
          ),
          if (listings.length > 3) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onManageTap,
              child: Text(
                '+ ${listings.length - 3} more listings',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Rich listing preview card used in the profile Listings tab.
/// Taps into ListingDetailScreen.
class _ProfileListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _ProfileListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // First non-empty image from imageUrls or fallback imageUrl
    final thumb = listing.imageUrls.isNotEmpty
        ? listing.imageUrls.first
        : listing.imageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedImageWidget(
                imageUrl: thumb,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: 72,
                  height: 72,
                  color: cs.surfaceContainerHighest,
                  child: Icon(Icons.image_not_supported_rounded,
                      color: cs.outline, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + condition chips
                  Row(
                    children: [
                      _MiniChip(
                          label: listing.category, cs: cs, primary: true),
                      const SizedBox(width: 6),
                      _MiniChip(
                          label: listing.conditionOrStatus,
                          cs: cs,
                          primary: false),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Title
                  Text(
                    listing.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Price
                  Text(
                    listing.price,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: cs.primary),
                  ),
                  const SizedBox(height: 3),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.location.split(',').first,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Arrow ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final bool primary;
  const _MiniChip(
      {required this.label, required this.cs, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: primary
            ? cs.primaryContainer.withValues(alpha: 0.45)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: primary
            ? null
            : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: primary ? cs.primary : cs.onSurfaceVariant),
      ),
    );
  }
}
