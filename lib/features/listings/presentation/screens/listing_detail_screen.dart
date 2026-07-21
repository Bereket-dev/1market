import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/icon_for_spec.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/similar_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ListingDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    KoolanAppStateScope.of(context).recordItemViewed(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    final state   = KoolanAppStateScope.of(context);
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

    final session         = state.getSessionForListing(widget.listingId);
    final contactRevealed = session?.contactRevealed ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // ── Scrollable content ───────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(listing: listing, state: state),
                _InfoSection(listing: listing, state: state),
                _SpecsSection(listing: listing),
                _DescriptionSection(listing: listing, state: state),
                _MapSection(listing: listing, state: state),
                _SellerCard(listing: listing, state: state),
                _ContactCard(
                  contactRevealed: contactRevealed,
                  sessionId: session?.id,
                  onStartChat: () async {
                    final threadId =
                        await state.startChatForListing(widget.listingId);
                    if (!context.mounted) return;
                    if (threadId != null) {
                      final idx = state.chatSessions
                          .indexWhere((s) => s.id == threadId);
                      if (idx != -1) {
                        state.pushScreen(ActiveChatScreenRoute(idx));
                      }
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SimilarListingsSection(anchor: listing),
                ),
              ],
            ),
          ),

          // ── Sticky CTA bar ───────────────────────────────────────────────
          _StickyBar(listing: listing, state: state),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero image  (single image from DB – no fake page counter)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _HeroImage({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Photo ──────────────────────────────────────────────────────
          listing.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: listing.imageUrl,
                  cacheManager: KoolanImageCacheManager.instance,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported,
                        size: 48, color: cs.outline),
                  ),
                )
              : Container(
                  color: cs.surfaceContainerHighest,
                  child: Icon(Icons.image_not_supported,
                      size: 48, color: cs.outline),
                ),

          // ── Gradient scrim so top buttons are always legible ───────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Back / Share / Save row ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverlayCircleButton(
                  icon: Icons.arrow_back,
                  onPressed: () => state.popScreen(),
                ),
                Row(
                  children: [
                    // Edit button — only for the listing owner
                    if (listing.isOwnedByCurrentUser) ...[
                      _OverlayCircleButton(
                        icon: Icons.edit_outlined,
                        onPressed: () => state
                            .pushScreen(EditListingScreenRoute(listing.id)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _OverlayCircleButton(
                      icon: Icons.share_outlined,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.s.detailLinkShared)),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _SavePill(listing: listing, state: state),
                  ],
                ),
              ],
            ),
          ),

          // ── Condition pill – bottom-left corner ────────────────────────
          Positioned(
            left: 16,
            bottom: 16,
            child: _ConditionPill(label: listing.conditionOrStatus),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info section  – price, title, location, verified badge
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _InfoSection({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Price + verified badge row ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  listing.price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (listing.verified) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: cs.tertiary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: cs.tertiary, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        listing.category == 'SKILLS'
                            ? state.s.detailVerifiedPro
                            : state.s.detailVerifiedListing,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Title (+ translated badge if applicable) ───────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  listing.titleForLocale(state.locale),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
              if (listing.isTranslatedFor(state.locale)) ...[
                const SizedBox(width: 8),
                _TranslatedBadge(s: state.s),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Location ───────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: cs.primary, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  listing.location,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Specs bento grid  – renders only the spec slots that have data (up to 4)
// ─────────────────────────────────────────────────────────────────────────────

class _SpecsSection extends StatelessWidget {
  final Listing listing;
  const _SpecsSection({required this.listing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = KoolanAppStateScope.of(context).s;

    // Collect only the slots that are fully populated
    final specs = <({String label, String value})>[];
    void add(String? l, String? v) {
      if (l != null && l.isNotEmpty && v != null && v.isNotEmpty) {
        specs.add((label: l, value: v));
      }
    }

    add(listing.spec1Label, listing.spec1Value);
    add(listing.spec2Label, listing.spec2Value);
    add(listing.spec3Label, listing.spec3Value);
    add(listing.spec4Label, listing.spec4Value);

    if (specs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.detailSpecs,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Pair specs into rows of 2
          for (int i = 0; i < specs.length; i += 2) ...[
            Row(
              children: [
                Expanded(
                  child: _BentoBox(
                    label: specs[i].label,
                    value: specs[i].value,
                    icon: iconForSpec(specs[i].label),
                  ),
                ),
                if (i + 1 < specs.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoBox(
                      label: specs[i + 1].label,
                      value: specs[i + 1].value,
                      icon: iconForSpec(specs[i + 1].label),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
            if (i + 2 < specs.length) const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description section
// ─────────────────────────────────────────────────────────────────────────────

class _DescriptionSection extends StatefulWidget {
  final Listing listing;
  final KoolanAppState state;
  const _DescriptionSection({required this.listing, required this.state});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final s    = widget.state.s;
    final text = widget.listing
        .descriptionForLocale(widget.state.locale)
        .trim();

    if (text.isEmpty) return const SizedBox.shrink();

    const kCollapsedLines = 4;
    final isLong = text.length > 200;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.detailDescription,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
            maxLines: _expanded ? null : kCollapsedLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (isLong) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map section  – schematic map + location label + open-in-maps action
// ─────────────────────────────────────────────────────────────────────────────

class _MapSection extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _MapSection({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = state.s;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.detailLocationLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Schematic map background
                  CustomPaint(
                    painter: _MapPainter(cs),
                    child: const SizedBox.expand(),
                  ),
                  // Bottom bar: location text + open-maps button
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.95),
                        border: Border(
                          top: BorderSide(
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.3)),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: cs.primary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              listing.location,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(s.detailOpeningMaps),
                              ));
                            },
                            icon: Icon(Icons.open_in_new,
                                size: 13, color: cs.primary),
                            label: Text(
                              s.detailOpenMaps,
                              style: TextStyle(
                                  fontSize: 12, color: cs.primary),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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

// ─────────────────────────────────────────────────────────────────────────────
// Seller card  – uses real DB fields: sellerName, sellerImage, sellerRating,
//                sellerReviewsCount
// ─────────────────────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _SellerCard({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = state.s;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            Text(
              s.detailSeller.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Avatar – from DB sellerImage, falls back to initials
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primaryContainer,
                  child: listing.sellerImage.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: listing.sellerImage,
                            cacheManager: KoolanImageCacheManager.instance,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _SellerInitials(
                              name: listing.sellerName,
                              cs: cs,
                            ),
                          ),
                        )
                      : _SellerInitials(name: listing.sellerName, cs: cs),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.sellerName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            listing.sellerRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${listing.sellerReviewsCount} ${s.detailReviews})',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // View profile button
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.detailProfileVerified)),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                        color: cs.outlineVariant),
                  ),
                  child: Text(
                    s.detailViewProfile,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Initials fallback for seller avatar
class _SellerInitials extends StatelessWidget {
  final String name;
  final ColorScheme cs;
  const _SellerInitials({required this.name, required this.cs});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Text(
      initials,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: cs.onPrimaryContainer,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact card  – thread-scoped reveal, no paywall
// Revealed automatically after 3 exchanged messages, or via explicit share
// ─────────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final bool contactRevealed;
  final String? sessionId;
  final VoidCallback onStartChat;

  const _ContactCard({
    required this.contactRevealed,
    required this.sessionId,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = KoolanAppStateScope.of(context).s;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: cs.primary.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  contactRevealed ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: cs.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  s.detailContactDetailsTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contactRevealed) ...[
              // ── Revealed ──────────────────────────────────────────────
              _ContactRow(
                icon: Icons.phone_rounded,
                text: '+251 91 123 4567',
                color: cs.primary,
              ),
              const SizedBox(height: 8),
              _ContactRow(
                icon: Icons.email_outlined,
                text: 'contact@jigjigamarketplace.et',
                color: cs.onSurfaceVariant,
              ),
            ] else ...[
              // ── Hidden ────────────────────────────────────────────────
              Text(
                s.detailContactHidden,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStartChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 18),
                  label: Text(
                    sessionId != null
                        ? s.detailGoToChat
                        : s.detailStartChat,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ContactRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky bottom CTA bar
// ─────────────────────────────────────────────────────────────────────────────

class _StickyBar extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _StickyBar({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = state.s;

    Future<void> startChat() async {
      final threadId = await state.startChatForListing(listing.id);
      if (!context.mounted) return;
      if (threadId != null) {
        final idx =
            state.chatSessions.indexWhere((sess) => sess.id == threadId);
        if (idx != -1) state.pushScreen(ActiveChatScreenRoute(idx));
      }
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Row(
          children: [
            // Chat button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: startChat,
                icon: Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: cs.primary),
                label: Text(
                  s.detailChat,
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: cs.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Primary action button
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.detailRequestLogged)),
                  );
                },
                icon: Icon(
                  listing.category == 'SKILLS'
                      ? Icons.handshake_outlined
                      : Icons.calendar_month_outlined,
                  size: 18,
                ),
                label: Text(
                  listing.category == 'SKILLS'
                      ? s.detailRequestHire
                      : s.detailViewProperty,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay circle button  (back / share on hero image)
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OverlayCircleButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save pill  (bookmark toggle on hero image)
// ─────────────────────────────────────────────────────────────────────────────

class _SavePill extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _SavePill({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final saved = listing.isSaved;
    return Material(
      color: saved
          ? Colors.redAccent.withValues(alpha: 0.85)
          : Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => state.toggleSaveListing(listing.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                saved ? 'Saved' : 'Save',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Condition pill  (bottom-left of hero image)
// ─────────────────────────────────────────────────────────────────────────────

class _ConditionPill extends StatelessWidget {
  final String label;
  const _ConditionPill({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento spec box
// ─────────────────────────────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map painter  (theme-aware schematic street map)
// ─────────────────────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  final ColorScheme cs;
  const _MapPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = cs.surfaceContainerHighest,
    );

    final roadPaint = Paint()
      ..color = cs.surface
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = cs.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal road
    canvas.drawLine(
        Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5),
        roadPaint);
    // Vertical road
    canvas.drawLine(
        Offset(size.width * 0.35, 0),
        Offset(size.width * 0.35, size.height),
        roadPaint);
    // Secondary horizontal
    canvas.drawLine(
        Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25),
        Paint()
          ..color = cs.surface
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke);

    // Dashes on main horizontal
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height * 0.5),
        Offset(x + 10, size.height * 0.5),
        dashPaint,
      );
      x += 22;
    }

    // Location pin
    final cx = Offset(size.width * 0.35, size.height * 0.5);
    canvas.drawCircle(
        cx, 22, Paint()..color = cs.primary.withValues(alpha: 0.15));
    canvas.drawCircle(
        cx, 10, Paint()..color = cs.primary.withValues(alpha: 0.9));
    canvas.drawCircle(cx, 5, Paint()..color = cs.onPrimary);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.cs != cs;
}

// ─────────────────────────────────────────────────────────────────────────────
// Translated badge  (inline with title when machine-translated)
// ─────────────────────────────────────────────────────────────────────────────

class _TranslatedBadge extends StatelessWidget {
  final AppStrings s;
  const _TranslatedBadge({required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: s.translatedTooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: cs.tertiary.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 11, color: cs.tertiary),
            const SizedBox(width: 4),
            Text(
              s.translatedBadge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
