import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A cache manager that keeps images for 90 days and holds up to 2 000 files.
/// Using a named singleton ensures every widget shares the same on-disk store.
class KoolanImageCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'koolanImageCache';

  static final KoolanImageCacheManager instance = KoolanImageCacheManager._();

  KoolanImageCacheManager._()
      : super(
          Config(
            _key,
            stalePeriod: const Duration(days: 90),
            maxNrOfCacheObjects: 2000,
            repo: JsonCacheInfoRepository(databaseName: _key),
            fileService: HttpFileService(),
          ),
        );
}

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Show the error/placeholder widget immediately for empty URLs —
    // no network request attempted, no spinner shown.
    if (imageUrl.isEmpty) {
      final fallback = errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: KoolanImageCacheManager.instance,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
      cacheKey: imageUrl,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }
}

/// Category-aware image placeholder for listings with no photo.
///
/// Shows a tinted background + a large icon that matches the listing category,
/// so it is visually distinct from a loaded image while clearly communicating
/// content type.  Do NOT use a loading spinner or shimmer here — the user
/// must immediately understand this is a placeholder, not a pending load.
class ListingPlaceholder extends StatelessWidget {
  final String category;
  final double? width;
  final double? height;

  const ListingPlaceholder({
    super.key,
    required this.category,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = _iconForCategory(category);

    return Container(
      width: width,
      height: height,
      color: cs.primaryContainer.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.primary.withValues(alpha: 0.55), size: _iconSize),
          const SizedBox(height: 4),
          Text(
            _labelForCategory(category),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.primary.withValues(alpha: 0.55),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  double get _iconSize {
    final h = height ?? 80;
    if (h >= 200) return 56;
    if (h >= 100) return 36;
    return 24;
  }

  static IconData _iconForCategory(String category) =>
      switch (category.toUpperCase()) {
        'CARS' => Icons.directions_car_rounded,
        'HOUSES' => Icons.home_rounded,
        'LAND' => Icons.landscape_rounded,
        'SKILLS' => Icons.construction_rounded,
        'OTHERS' => Icons.category_outlined,
        _ => Icons.inventory_2_outlined,
      };

  static String _labelForCategory(String category) =>
      switch (category.toUpperCase()) {
        'CARS' => 'No photo',
        'HOUSES' => 'No photo',
        'LAND' => 'No photo',
        'SKILLS' => 'No photo',
        _ => 'No photo',
      };
}

class CachedCircularImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedCircularImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: KoolanImageCacheManager.instance,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) =>
          placeholder ??
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            child: const CircularProgressIndicator(),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
      cacheKey: imageUrl,
    );
  }
}