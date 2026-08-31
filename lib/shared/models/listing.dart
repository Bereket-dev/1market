import '../../core/utils/price_formatter.dart';
import 'syncable_entity.dart';

class Listing with SyncableEntity {
  @override
  final String id;

  /// Category: CARS, HOUSES, LAND, SKILLS
  final String category;
  final String title;
  final String price;
  final String imageUrl;
  final String location;
  final bool verified;
  final bool isSaved;
  final String conditionOrStatus;

  /// Seller display name — sourced from the joined profiles row.
  final String sellerName;

  /// Seller avatar URL — sourced from the joined profiles row.
  final String sellerImage;

  /// Seller rating — sourced from the joined profiles row.
  final double sellerRating;

  /// Seller review count — sourced from the joined profiles row.
  final int sellerReviewsCount;

  /// Seller phone — sourced from the joined profiles row.
  final String? sellerPhone;
  final String description;
  final String? spec1Label;
  final String? spec1Value;
  final String? spec2Label;
  final String? spec2Value;
  final String? spec3Label;
  final String? spec3Value;
  final String? spec4Label;
  final String? spec4Value;
  final String? sellerId;

  /// Additional listing images (uploaded to Cloudinary).
  /// The first URL is used as the primary thumbnail when [imageUrl] is empty.
  final List<String> imageUrls;

  @override
  final DateTime localUpdatedAt;
  @override
  final DateTime? remoteUpdatedAt;
  @override
  final SyncStatus syncStatus;

  /// True when posted by the current user.
  final bool isOwnedByCurrentUser;
  final bool isHidden;
  final DateTime? deletedAt;

  // ── Translation fields ──────────────────────────────────────────────────────
  /// The language code of the original post (e.g. 'en', 'am', 'so').
  final String originalLanguage;

  /// Machine-translated title variants keyed by locale code.
  /// e.g. {"en": "Toyota Land Cruiser", "am": "...", "so": "..."}
  /// Only populated for target languages — the source language value
  /// is always read from [title] directly, never from this map.
  final Map<String, String> titleTranslations;

  /// Machine-translated description variants keyed by locale code.
  final Map<String, String> descriptionTranslations;

  // Not const: the initializer list uses DateTime.now(), which is a runtime
  // call and can never be a compile-time constant.
  Listing({
    required this.id,
    required this.category,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.location,
    this.verified = false,
    this.isSaved = false,
    required this.conditionOrStatus,
    required this.sellerName,
    this.sellerImage = '',
    this.sellerRating = 4.8,
    this.sellerReviewsCount = 12,
    this.description = '',
    this.spec1Label,
    this.spec1Value,
    this.spec2Label,
    this.spec2Value,
    this.spec3Label,
    this.spec3Value,
    this.spec4Label,
    this.spec4Value,
    this.sellerId,
    this.sellerPhone,
    this.imageUrls = const [],
    DateTime? localUpdatedAt,
    this.remoteUpdatedAt,
    this.syncStatus = SyncStatus.synced,
    this.isOwnedByCurrentUser = false,
    this.isHidden = false,
    this.deletedAt,
    this.originalLanguage = 'en',
    this.titleTranslations = const {},
    this.descriptionTranslations = const {},
  }) : localUpdatedAt = localUpdatedAt ?? DateTime.now();

  /// Returns the title in [locale], falling back to [title] if no translation
  /// exists yet for that locale.
  String titleForLocale(String locale) {
    if (locale == originalLanguage) return title;
    return titleTranslations[locale] ?? title;
  }

  /// Returns the description in [locale], falling back to [description].
  String descriptionForLocale(String locale) {
    if (locale == originalLanguage) return description;
    return descriptionTranslations[locale] ?? description;
  }

  /// Returns true when [locale] is a machine-translated variant
  /// (i.e. viewing in a different language than the original).
  bool isTranslatedFor(String locale) =>
      locale != originalLanguage && titleTranslations.containsKey(locale);

  factory Listing.fromJson(
    Map<String, dynamic> json, {
    bool isSaved = false,
    bool isOwnedByCurrentUser = false,
  }) {
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '');

    Map<String, String> parseTranslations(dynamic raw) {
      if (raw == null) return const {};
      if (raw is Map) {
        return Map<String, String>.fromEntries(
          raw.entries.map(
            (e) => MapEntry(e.key.toString(), e.value.toString()),
          ),
        );
      }
      return const {};
    }

    return Listing(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      price: formatETB(json['price'] as String? ?? ''),
      imageUrl: json['image_url'] as String,
      location: json['location'] as String,
      verified: json['verified'] as bool? ?? false,
      isSaved: isSaved,
      conditionOrStatus: json['condition_or_status'] as String,
      // ── Seller fields: read from joined profiles row when available,
      //    fall back to the denormalized columns for legacy/offline rows.
      sellerName: () {
        final p = json['profiles'] as Map<String, dynamic>?;
        return p?['display_name'] as String? ??
            json['seller_name'] as String? ??
            'Seller';
      }(),
      sellerImage: () {
        final p = json['profiles'] as Map<String, dynamic>?;
        return p?['avatar_url'] as String? ??
            json['seller_image'] as String? ??
            '';
      }(),
      sellerRating: () {
        final p = json['profiles'] as Map<String, dynamic>?;
        return (p?['rating'] as num?)?.toDouble() ??
            (json['seller_rating'] as num?)?.toDouble() ??
            4.8;
      }(),
      sellerReviewsCount: () {
        final p = json['profiles'] as Map<String, dynamic>?;
        return (p?['reviews_count'] as int?) ??
            json['seller_reviews_count'] as int? ??
            0;
      }(),
      sellerPhone: () {
        final p = json['profiles'] as Map<String, dynamic>?;
        return p?['phone'] as String? ?? json['seller_phone'] as String?;
      }(),
      description: json['description'] as String? ?? '',
      spec1Label: json['spec1_label'] as String?,
      spec1Value: json['spec1_value'] as String?,
      spec2Label: json['spec2_label'] as String?,
      spec2Value: json['spec2_value'] as String?,
      spec3Label: json['spec3_label'] as String?,
      spec3Value: json['spec3_value'] as String?,
      spec4Label: json['spec4_label'] as String?,
      spec4Value: json['spec4_value'] as String?,
      isHidden: json['is_hidden'] as bool? ?? false,
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
      localUpdatedAt: createdAt ?? DateTime.now(),
      remoteUpdatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
      isOwnedByCurrentUser: isOwnedByCurrentUser,
      originalLanguage: json['original_language'] as String? ?? 'en',
      titleTranslations: parseTranslations(json['title_translations']),
      descriptionTranslations: parseTranslations(
        json['description_translations'],
      ),
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'price': price,
    'image_url': imageUrl,
    'location': location,
    'verified': verified,
    'is_saved': isSaved,
    'condition_or_status': conditionOrStatus,
    'seller_id': sellerId,
    'description': description,
    'spec1_label': spec1Label,
    'spec1_value': spec1Value,
    'spec2_label': spec2Label,
    'spec2_value': spec2Value,
    'spec3_label': spec3Label,
    'spec3_value': spec3Value,
    'spec4_label': spec4Label,
    'spec4_value': spec4Value,
    'created_at': localUpdatedAt.toIso8601String(),
    'updated_at': remoteUpdatedAt?.toIso8601String(),
    'original_language': originalLanguage,
    'title_translations': titleTranslations,
    'description_translations': descriptionTranslations,
    'image_urls': imageUrls,
    'is_hidden': isHidden,
    'deleted_at': deletedAt?.toIso8601String(),
  };

  Listing copyWith({
    String? id,
    String? category,
    String? title,
    String? price,
    String? imageUrl,
    String? location,
    bool? verified,
    bool? isSaved,
    String? conditionOrStatus,
    String? sellerName,
    String? sellerImage,
    double? sellerRating,
    int? sellerReviewsCount,
    String? description,
    String? spec1Label,
    String? spec1Value,
    String? spec2Label,
    String? spec2Value,
    String? spec3Label,
    String? spec3Value,
    String? spec4Label,
    String? spec4Value,
    String? sellerId,
    String? sellerPhone,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
    SyncStatus? syncStatus,
    bool? isOwnedByCurrentUser,
    bool? isHidden,
    DateTime? deletedAt,
    String? originalLanguage,
    Map<String, String>? titleTranslations,
    Map<String, String>? descriptionTranslations,
    List<String>? imageUrls,
  }) {
    return Listing(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      verified: verified ?? this.verified,
      isSaved: isSaved ?? this.isSaved,
      conditionOrStatus: conditionOrStatus ?? this.conditionOrStatus,
      sellerName: sellerName ?? this.sellerName,
      sellerImage: sellerImage ?? this.sellerImage,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerReviewsCount: sellerReviewsCount ?? this.sellerReviewsCount,
      description: description ?? this.description,
      spec1Label: spec1Label ?? this.spec1Label,
      spec1Value: spec1Value ?? this.spec1Value,
      spec2Label: spec2Label ?? this.spec2Label,
      spec2Value: spec2Value ?? this.spec2Value,
      spec3Label: spec3Label ?? this.spec3Label,
      spec3Value: spec3Value ?? this.spec3Value,
      spec4Label: spec4Label ?? this.spec4Label,
      spec4Value: spec4Value ?? this.spec4Value,
      sellerId: sellerId ?? this.sellerId,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
      isHidden: isHidden ?? this.isHidden,
      deletedAt: deletedAt ?? this.deletedAt,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      titleTranslations: titleTranslations ?? this.titleTranslations,
      descriptionTranslations:
          descriptionTranslations ?? this.descriptionTranslations,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
