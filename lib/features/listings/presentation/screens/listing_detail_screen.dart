import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/icon_for_spec.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/models/profile.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/share_service.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../../../../shared/widgets/report_bottom_sheet.dart';
import '../../../../shared/widgets/similar_section.dart';
part 'widgets/listing_detail_widgets.dart';
part 'widgets/listing_detail_viewing_sheet.dart';
part 'widgets/listing_detail_seller.dart';
part 'widgets/listing_detail_sections.dart';
part 'widgets/listing_detail_hero.dart';
part 'widgets/listing_detail_contact.dart';
part 'widgets/listing_detail_actions.dart';

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
  /// Resolved phone number: starts from listing.sellerPhone and is
  /// enriched by a background profile fetch when it is missing.
  String? _resolvedPhone;
  bool _fetchingPhone = false;
  bool _phoneCheckScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = OnemarketAppStateScope.of(context);
    state.recordItemViewed(widget.listingId);

    // Defer state updates until the AnimatedSwitcher has completed its current build.
    if (!_phoneCheckScheduled) {
      _phoneCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeLoadSellerPhone(state);
      });
    }
  }

  /// If the listing already carries a phone number we use it directly.
  /// Otherwise we kick off a profile fetch using the seller_id.
  void _maybeLoadSellerPhone(OnemarketAppState state) {
    final listing = state.getListingById(widget.listingId);
    if (listing == null) return;

    // Already have phone — nothing to fetch.
    if (listing.sellerPhone != null && listing.sellerPhone!.isNotEmpty) {
      if (_resolvedPhone != listing.sellerPhone) {
        setState(() => _resolvedPhone = listing.sellerPhone);
      }
      return;
    }

    // Check if we already have it cached in the public profile store.
    final sellerId = listing.sellerId;
    if (sellerId == null || sellerId.isEmpty) return;

    final cached = state.getCachedPublicProfile(sellerId);
    if (cached?.phone != null && cached!.phone!.isNotEmpty) {
      setState(() => _resolvedPhone = cached.phone);
      return;
    }

    // Fetch from Supabase.
    if (_fetchingPhone) return;
    setState(() => _fetchingPhone = true);
    state.loadPublicProfile(sellerId, notify: false).then((
      UserProfile? profile,
    ) {
      if (!mounted) return;
      setState(() {
        _resolvedPhone = profile?.phone;
        _fetchingPhone = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = OnemarketAppStateScope.of(context);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroImage(listing: listing, state: state),
                  _InfoSection(listing: listing, state: state),
                  _SpecsSection(listing: listing),
                  _DescriptionSection(listing: listing, state: state),
                  _MapSection(listing: listing, state: state),
                  _SellerCard(listing: listing, state: state),
                  _ContactActions(
                    listing: listing,
                    resolvedPhone: _resolvedPhone,
                    fetchingPhone: _fetchingPhone,
                  ),
                  if (listing.isOwnedByCurrentUser)
                    _OwnerListingActions(listing: listing, state: state),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SimilarListingsSection(anchor: listing),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StickyBar(listing: listing, state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero image  – single image OR swipeable PageView carousel when multiple
// images exist.  Dot indicators are shown only when count > 1.
// ─────────────────────────────────────────────────────────────────────────────
