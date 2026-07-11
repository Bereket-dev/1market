import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/icon_for_spec.dart';
import '../../../../shared/services/app_state.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isContactUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final listing =
        state.allListings.firstWhere((l) => l.id == widget.listingId);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Photo area ─────────────────────────────────────────────
                SizedBox(
                  height: 360,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(listing.imageUrl, fit: BoxFit.cover),

                      // Photo counter
                      Positioned(
                        left: 24,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const CircleAvatar(
                                  radius: 3,
                                  backgroundColor: Colors.white30),
                              const SizedBox(width: 4),
                              const CircleAvatar(
                                  radius: 3,
                                  backgroundColor: Colors.white30),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '1 / 3',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),

                      // Header actions
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: kPrimary),
                                onPressed: () => state.popScreen(),
                              ),
                            ),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.9),
                                  child: IconButton(
                                    icon: const Icon(Icons.share,
                                        color: kPrimary),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('Link shared!')));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.9),
                                  child: IconButton(
                                    icon: Icon(
                                      listing.isSaved
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: listing.isSaved
                                          ? Colors.red
                                          : kPrimary,
                                    ),
                                    onPressed: () =>
                                        state.toggleSaveListing(listing.id),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Info area ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              listing.category == 'SKILLS'
                                  ? 'Verified Skilled Professional'
                                  : 'Verified Listing',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ),
                          Text(
                            listing.price,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: kOutline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            listing.location,
                            style:
                                const TextStyle(color: kOnSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bento spec grid
                      Column(
                        children: [
                          Row(
                            children: [
                              if (listing.spec1Label != null &&
                                  listing.spec1Value != null)
                                Expanded(
                                  child: _BentoBox(
                                    label: listing.spec1Label!,
                                    value: listing.spec1Value!,
                                    icon: iconForSpec(listing.spec1Label!),
                                  ),
                                ),
                              if (listing.spec1Label != null &&
                                  listing.spec2Label != null)
                                const SizedBox(width: 12),
                              if (listing.spec2Label != null &&
                                  listing.spec2Value != null)
                                Expanded(
                                  child: _BentoBox(
                                    label: listing.spec2Label!,
                                    value: listing.spec2Value!,
                                    icon: iconForSpec(listing.spec2Label!),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (listing.spec3Label != null &&
                                  listing.spec3Value != null)
                                Expanded(
                                  child: _BentoBox(
                                    label: listing.spec3Label!,
                                    value: listing.spec3Value!,
                                    icon: iconForSpec(listing.spec3Label!),
                                  ),
                                ),
                              if (listing.spec3Label != null &&
                                  listing.spec4Label != null)
                                const SizedBox(width: 12),
                              if (listing.spec4Label != null &&
                                  listing.spec4Value != null)
                                Expanded(
                                  child: _BentoBox(
                                    label: listing.spec4Label!,
                                    value: listing.spec4Value!,
                                    icon: iconForSpec(listing.spec4Label!),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        state.s.detailDescription,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.description.isEmpty
                            ? 'Dedicated listing in Jigjiga. Authentic and ready for immediate transition.'
                            : listing.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kOnSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Map widget
                      const Text(
                        'Location',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: kOutlineVariant.withOpacity(0.4)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            CustomPaint(
                              painter: _MapPainter(kPrimary),
                              child: const SizedBox.expand(),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: Colors.white.withOpacity(0.9),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Kebele 06, Jigjiga Central',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Opening Google Maps...'),
                                        ));
                                      },
                                      child: const Row(
                                        children: [
                                          Text('Open in Maps',
                                              style:
                                                  TextStyle(fontSize: 12)),
                                          SizedBox(width: 4),
                                          Icon(Icons.open_in_new, size: 12),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seller card
                      _SellerCard(listing: listing, state: state),
                      const SizedBox(height: 24),

                      // Contact card
                      _ContactCard(
                        isUnlocked: _isContactUnlocked,
                        unlockLabel: state.s.detailUnlockContact,
                        onUnlock: () =>
                            setState(() => _isContactUnlocked = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky bottom CTA bar ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white.withOpacity(0.95),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          state.pushScreen(ActiveChatScreenRoute(0)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: kPrimary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat, color: kPrimary),
                          const SizedBox(width: 8),
                          Text(
                            state.s.detailChat,
                            style: const TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Request logged. Partner notified!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            listing.category == 'SKILLS'
                                ? state.s.detailRequestHire
                                : state.s.detailViewProperty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

// ── Bento spec box ────────────────────────────────────────────────────────────

class _BentoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BentoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: kPrimary, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: kOnSurfaceVariant)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ── Seller card ───────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final dynamic listing;
  final KoolanAppState state;

  const _SellerCard({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.2)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.s.detailSeller,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: kOnSurfaceVariant.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    listing.sellerImage.isEmpty
                        ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80'
                        : listing.sellerImage,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.sellerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.sellerRating} (${listing.sellerReviewsCount} ${state.s.detailReviews})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.s.detailProfileVerified)),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: kOutlineVariant),
              ),
              child: Text(
                state.s.detailViewProfile,
                style: const TextStyle(color: kOnSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final bool isUnlocked;
  final String unlockLabel;
  final VoidCallback onUnlock;

  const _ContactCard({
    required this.isUnlocked,
    required this.unlockLabel,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: kPrimary.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact Details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Icon(Icons.lock, color: kPrimary, size: 28),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Phone numbers and direct emails are protected to avoid '
              'phishing/spam. Interact safely using escrow.',
              style: TextStyle(fontSize: 13, color: kOnSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (isUnlocked) ...[
              const Text(
                'Phone: +251 91 123 4567',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Email: contact@jigjigamarketplace.et',
                style: TextStyle(color: kOnSurfaceVariant),
              ),
            ] else
              ElevatedButton(
                onPressed: onUnlock,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      unlockLabel,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Map painter ───────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  final Color primaryColor;
  const _MapPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF1F3F5),
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal road
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), roadPaint);

    // Dashes
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + 10, size.height / 2),
        dashPaint,
      );
      startX += 20;
    }

    // Vertical road
    canvas.drawLine(
        Offset(size.width / 3, 0), Offset(size.width / 3, size.height), roadPaint);

    // Marker rings
    final cx = Offset(size.width / 3, size.height / 2);
    canvas.drawCircle(cx, 24, Paint()..color = primaryColor.withOpacity(0.2));
    canvas.drawCircle(cx, 8, Paint()..color = Colors.white);
    canvas.drawCircle(cx, 4, Paint()..color = primaryColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
