import '../models/syncable_entity.dart';

class UserProfile with SyncableEntity {
  @override
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? city;
  final String? language;
  final String? preferredCategory;
  final bool onboardingComplete;
  final double rating;
  final int reviewsCount;
  @override
  final DateTime localUpdatedAt;
  @override
  final DateTime? remoteUpdatedAt;
  @override
  final SyncStatus syncStatus;

  // Not const: the initializer list uses DateTime.now(), which is a runtime
  // call and can never be a compile-time constant.
  UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.city,
    this.language,
    this.preferredCategory,
    this.onboardingComplete = false,
    this.rating = 5.0,
    this.reviewsCount = 0,
    DateTime? localUpdatedAt,
    this.remoteUpdatedAt,
    this.syncStatus = SyncStatus.synced,
  }) : localUpdatedAt = localUpdatedAt ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '');
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      language: json['language'] as String?,
      preferredCategory: json['preferred_category'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      localUpdatedAt: updatedAt ?? DateTime.now(),
      remoteUpdatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'bio': bio,
    'phone': phone,
    'city': city,
    'language': language,
    'preferred_category': preferredCategory,
    'onboarding_complete': onboardingComplete,
    'rating': rating,
    'reviews_count': reviewsCount,
  };

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? city,
    String? language,
    String? preferredCategory,
    bool? onboardingComplete,
    double? rating,
    int? reviewsCount,
    SyncStatus? syncStatus,
    DateTime? localUpdatedAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      language: language ?? this.language,
      preferredCategory: preferredCategory ?? this.preferredCategory,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt,
    );
  }
}
