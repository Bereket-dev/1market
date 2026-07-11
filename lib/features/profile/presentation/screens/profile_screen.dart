import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';

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
    final myListings = state.allListings
        .where((l) => l.isCustom || l.sellerName.contains('Me'))
        .toList();

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
                  Image.network(
                    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.3)),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
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

            // ── Profile info block ────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 56,
                      backgroundColor: kBackground,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hodan Ahmed',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kOnSurface,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.verified, color: kVerifiedColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Professional Housekeeper & Plumber',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: kPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kebele 06, Jigjiga • Joined Dec 2024',
                      style: TextStyle(color: kOnSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Stats card
                    Card(
                      color: kSurfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: kOutlineVariant.withOpacity(0.3)),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '5.0',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                                Text(
                                  '12 Reviews',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: kOnSurfaceVariant),
                                ),
                              ],
                            ),
                            Container(
                                width: 1,
                                height: 30,
                                color: kOutlineVariant.withOpacity(0.3)),
                            const Column(
                              children: [
                                Text(
                                  '47',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  'Jobs Done',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: kOnSurfaceVariant),
                                ),
                              ],
                            ),
                            Container(
                                width: 1,
                                height: 30,
                                color: kOutlineVariant.withOpacity(0.3)),
                            const Column(
                              children: [
                                Text(
                                  '100%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: kVerifiedColor,
                                  ),
                                ),
                                Text(
                                  'Response Rate',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: kOnSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tabs
                    Row(
                      children: ['Services', 'About', 'Reviews'].map((tab) {
                        final isSel = _activeTab == tab;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => _activeTab = tab),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSel
                                    ? kPrimary
                                    : kSurfaceContainerHigh,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: Text(
                                tab,
                                style: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : kOnSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Tab content
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

// ── Services tab ─────────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  final List<Listing> myListings;
  final void Function(int id) onListingTap;

  const _ServicesTab({required this.myListings, required this.onListingTap});

  @override
  Widget build(BuildContext context) {
    if (myListings.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundColor: kPrimary.withOpacity(0.05),
            child: const Icon(Icons.work_outline, size: 36, color: kPrimary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No services posted yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the central + button to publish your professional service ad instantly.',
            style: TextStyle(
                color: kOnSurfaceVariant.withOpacity(0.6), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: myListings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = myListings[index];
        return Card(
          color: kSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
          ),
          elevation: 0,
          child: InkWell(
            onTap: () => onListingTap(item.id),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(item.imageUrl,
                        width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.price,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: kPrimary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              item.location.split(',')[0],
                              style: const TextStyle(
                                  color: kOnSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kOnSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── About tab ────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Summary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Highly skilled and dependable professional offering comprehensive '
          'housekeeper, catering, and plumbing support. Over 4 years of '
          'verified experience assisting private homes and business complexes '
          'in Jigjiga.',
          style: TextStyle(
              color: kOnSurfaceVariant, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),

        // Escrow vault card
        Card(
          color: kSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, color: kVerifiedColor),
                        SizedBox(width: 8),
                        Text(
                          'Escrow Safety Vault',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Text(
                      'Active',
                      style: TextStyle(
                          color: kVerifiedColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Secured Escrow Wallet',
                      style: TextStyle(
                          color: kOnSurfaceVariant, fontSize: 13),
                    ),
                    Text(
                      '15,400 ETB',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Specialties
        const Text(
          'Verified Specialties',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Reviews tab ───────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ReviewCard(
          name: 'Ahmed Mohammed',
          date: '2 days ago',
          comment:
              'Hodan was absolutely amazing! Fixed a complicated plumbing '
              'issue in our house within an hour. Extremely professional and courteous.',
        ),
        SizedBox(height: 16),
        _ReviewCard(
          name: 'Hodan Ali',
          date: '1 week ago',
          comment:
              'Great cleaning service, left the house sparkling and clean. '
              'Will definitely hire her again next month!',
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final String comment;

  const _ReviewCard({
    required this.name,
    required this.date,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: kPrimary.withOpacity(0.1),
                      child: Text(
                        name.substring(0, 1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: kPrimary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                              fontSize: 10,
                              color: kOnSurfaceVariant.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '5.0',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                  fontSize: 13, color: kOnSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
