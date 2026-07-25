import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_strings.dart';
import '../models/listing.dart';
import '../models/service.dart';
import '../models/hiring_post.dart';

// Base URL used in every shared link.  When Firebase Dynamic Links (or a
// custom redirect server) are set up, replace this with the real domain so
// the link opens the app directly.  Even as a plain URL it gives recipients a
// meaningful destination and improves SEO.
const _kBaseUrl = 'https://koolan.app';

/// Lightweight helper that builds a rich share message and invokes the OS
/// native share sheet (WhatsApp, Telegram, Facebook, SMS, copy, …).
///
/// All methods accept an optional [sharePositionOrigin] for iPad popover
/// support — on phones it is ignored.
class ShareService {
  const ShareService._();

  // ── Listing ──────────────────────────────────────────────────────────────────

  static Future<void> shareListing(
    Listing listing,
    AppStrings s, {
    Rect? sharePositionOrigin,
  }) async {
    final url = '$_kBaseUrl/listing/${listing.id}';
    final body = s.shareListingBody(
      listing.title,
      listing.price,
      listing.location,
      url,
    );
    await Share.share(
      body,
      subject: s.shareListingSubject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  // ── Service ──────────────────────────────────────────────────────────────────

  static Future<void> shareService(
    Service service,
    AppStrings s, {
    Rect? sharePositionOrigin,
  }) async {
    final url = '$_kBaseUrl/service/${service.id}';
    final body = s.shareServiceBody(
      service.title,
      service.category,
      service.priceRange,
      url,
    );
    await Share.share(
      body,
      subject: s.shareServiceSubject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  // ── Hiring post ───────────────────────────────────────────────────────────────

  static Future<void> shareHiringPost(
    HiringPost post,
    AppStrings s, {
    Rect? sharePositionOrigin,
  }) async {
    final url = '$_kBaseUrl/hiring/${post.id}';
    final body = s.shareHiringBody(
      post.title,
      post.category,
      post.location,
      url,
    );
    await Share.share(
      body,
      subject: s.shareHiringSubject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
