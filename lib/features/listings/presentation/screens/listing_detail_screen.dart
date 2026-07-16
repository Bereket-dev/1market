import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/icon_for_spec.dart';
import '../../../../shared/services/app_state.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isContactUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final listing = state.getListingById(widget.listingId);

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => state.popScreen(),
          ),
        ),
        body: Center(child: Text(state.s.listingNotFound)),
      );
    }

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

                      // Photo counter pill – bottom left
                      Positioned(
                        left: 24,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
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

                      // Page count pill – bottom right
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '1 / 3',
                            style:
                                TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),

                      // Back / Share / Save buttons overlay
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _OverlayCircleButton(
                              icon: Icons.arrow_back,
                              cs: cs,
                              onPressed: () => state.popScreen(),
                            ),
                            Row(
                              children: [
                                _OverlayCircleButton(
                                  icon: Icons.share,
                                  cs: cs,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Link shared!')));
                                  },
                                ),
                                const SizedBox(width: 8),
                                _OverlayCircleButton(
                                  icon: listing.isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  cs: cs,
                                  iconColor: listing.isSaved
                                      ? Colors.redAccent
                                      : null,
                                  onPressed: () =>
                                      state.toggleSaveListing(listing.id),
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
                              color: cs.primaryContainer.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              listing.category == 'SKILLS'
                                  ? 'Verified Skilled Professional'
                                  : 'Verified Listing',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          Text(
                            listing.price,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: cs.outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            listing.location,
                            style: TextStyle(color: cs.onSurfaceVariant),
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
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.description.isEmpty
                            ? 'Dedicated listing in Jigjiga. Authentic and ready for immediate transition.'
                            : listing.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Map widget
                      Text(
                        'Location',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            CustomPaint(
                              painter: _MapPainter(cs),
                              child: const SizedBox.expand(),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.95),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Kebele 06, Jigjiga Central',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: cs.onSurface),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Opening Google Maps...'),
                                        ));
                                      },
                                      child: Row(
                                        children: [
                                          Text('Open in Maps',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: cs.primary)),
                                          const SizedBox(width: 4),
                                          Icon(Icons.open_in_new,
                                              size: 12, color: cs.primary),
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
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
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
                        side: BorderSide(color: cs.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            state.s.detailChat,
                            style: TextStyle(
                              color: cs.primary,
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
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event, color: cs.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            listing.category == 'SKILLS'
                                ? state.s.detailRequestHire
                                : state.s.detailViewProperty,
                            style: TextStyle(
                              color: cs.onPrimary,
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

// ── Photo overlay circular button ─────────────────────────────────────────────

class _OverlayCircleButton extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _OverlayCircleButton({
    required this.icon,
    required this.cs,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: cs.surface.withValues(alpha: 0.88),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? cs.primary),
        onPressed: onPressed,
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: cs.primary, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
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
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
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
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.sellerRating} (${listing.sellerReviewsCount} ${state.s.detailReviews})',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
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
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Text(
                state.s.detailViewProfile,
                style: TextStyle(color: cs.onSurface),
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact Details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: cs.onSurface),
                ),
                Icon(Icons.lock, color: cs.primary, size: 28),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Phone numbers and direct emails are protected to avoid '
              'phishing/spam. Interact safely using escrow.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (isUnlocked) ...[
              Text(
                'Phone: +251 91 123 4567',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Email: contact@jigjigamarketplace.et',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ] else
              ElevatedButton(
                onPressed: onUnlock,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, color: cs.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      unlockLabel,
                      style: TextStyle(color: cs.onPrimary),
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

// ── Map painter (theme-aware) ─────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  final ColorScheme cs;
  const _MapPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    // Background – use a mid-tone surface so it reads in both modes
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = cs.surfaceContainerHighest,
    );

    // Roads
    final roadPaint = Paint()
      ..color = cs.surface
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = cs.outlineVariant.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal road
    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        roadPaint);

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
        Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height),
        roadPaint);

    // Location marker
    final cx = Offset(size.width / 3, size.height / 2);
    canvas.drawCircle(
        cx, 24, Paint()..color = cs.primary.withValues(alpha: 0.18));
    canvas.drawCircle(cx, 8, Paint()..color = cs.surface);
    canvas.drawCircle(cx, 4, Paint()..color = cs.primary);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.cs != cs;
}
