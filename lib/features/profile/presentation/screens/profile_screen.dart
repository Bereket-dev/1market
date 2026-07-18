import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'Services';

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final myListings = state.getMyListings();

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
                  CachedImageWidget(
                    imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                  ),
                  // Dark scrim so content over it is readable in both modes
                  Container(color: Colors.black.withValues(alpha: 0.38)),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () =>
                            state.pushScreen(SettingsScreenRoute()),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Profile card, pulled up over banner ──────────────────────────
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Avatar with theme-coloured ring
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: cs.primary,
                      child: CachedCircularImage(
                        imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80',
                        radius: 52,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hodan Ahmed',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.verified, color: cs.tertiary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Professional Housekeeper & Plumber',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: cs.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kebele 06, Jigjiga • Joined Dec 2024',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

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
                            Column(children: [
                              Row(children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text('5.0',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: cs.onSurface)),
                              ]),
                              Text('12 ${state.s.profileReviews}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant)),
                            ]),
                            Container(
                                width: 1,
                                height: 30,
                                color: cs.outlineVariant.withValues(alpha: 0.5)),
                            Column(children: [
                              Text('47',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: cs.onSurface)),
                              Text(state.s.profileJobsDone,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant)),
                            ]),
                            Container(
                                width: 1,
                                height: 30,
                                color: cs.outlineVariant.withValues(alpha: 0.5)),
                            Column(children: [
                              Text('100%',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: cs.tertiary)),
                              Text(state.s.profileResponseRate,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab buttons
                    Row(
                      children: ['Services', 'About', 'Reviews'].map((tab) {
                        final isSel = _activeTab == tab;
                        final label = switch (tab) {
                          'Services' => state.s.profileTabServices,
                          'About'    => state.s.profileTabAbout,
                          _          => state.s.profileTabReviews,
                        };
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
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
                                    borderRadius:
                                        BorderRadius.circular(20)),
                              ),
                              child: Text(label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ),
                        );
                      }).toList(),
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
          myListings: myListings,
          onListingTap: (id) =>
              state.pushScreen(ListingDetailScreenRoute(id)),
        );
      case 'About':
        return const _AboutTab();
      default:
        return const _ReviewsTab();
    }
  }
}

// ── Services tab ──────────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  final List<Listing> myListings;
  final void Function(String) onListingTap;
  const _ServicesTab({required this.myListings, required this.onListingTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    if (myListings.isEmpty) {
      return Column(children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 40,
          backgroundColor: cs.primaryContainer.withValues(alpha: 0.2),
          child: Icon(Icons.work_outline, size: 36, color: cs.primary),
        ),
        const SizedBox(height: 16),
        Text(s.profileNoServices,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onSurface)),
        const SizedBox(height: 4),
        Text(
          s.profileNoServicesSub,
          style: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.65),
              fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ]);
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: myListings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = myListings[index];
        return Card(
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side:
                BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          elevation: 0,
          child: InkWell(
            onTap: () => onListingTap(item.id),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedImageWidget(
                    imageUrl: item.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(item.price,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.location_on, color: cs.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(item.location.split(',')[0],
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ── About tab ─────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.profileProfSummary,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: cs.onSurface)),
      const SizedBox(height: 8),
      Text(
        'Highly skilled and dependable professional offering comprehensive '
        'housekeeper, catering, and plumbing support. Over 4 years of '
        'verified experience assisting private homes and business complexes in Jigjiga.',
        style: TextStyle(
            color: cs.onSurfaceVariant, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 20),
      Card(
        color: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.shield, color: cs.tertiary),
                const SizedBox(width: 8),
                Text(s.profileEscrowTitle,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface)),
              ]),
              Text(s.profileEscrowActive,
                  style: TextStyle(
                      color: cs.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(s.profileEscrowWallet,
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 13)),
              Text('15,400 ETB',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSurface)),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 20),
      Text(s.profileSpecialties,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: cs.onSurface)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          'Residential Plumbing',
          'Deep Cleaning',
          'Emergency Repairs',
          'Meal Preparation',
          'Bilingual Support',
        ].map((skill) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(skill,
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

// ── Reviews tab ───────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      _ReviewCard(
        name: 'Ahmed Mohammed',
        date: '2 days ago',
        comment:
            'Hodan was absolutely amazing! Fixed a complicated plumbing issue '
            'in our house within an hour. Extremely professional and courteous.',
      ),
      SizedBox(height: 16),
      _ReviewCard(
        name: 'Hodan Ali',
        date: '1 week ago',
        comment:
            'Great cleaning service, left the house sparkling. Will definitely '
            'hire her again next month!',
      ),
    ]);
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final String comment;
  const _ReviewCard(
      {required this.name, required this.date, required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
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
                  backgroundColor:
                      cs.primaryContainer.withValues(alpha: 0.35),
                  child: Text(name[0],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: cs.primary)),
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
                Text('5.0',
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
