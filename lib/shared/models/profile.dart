class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? city;
  final String? language;
  final String? preferredCategory;
  final double rating;
  final int reviewsCount;

  const UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.city,
    this.language,
    this.preferredCategory,
    this.rating = 5.0,
    this.reviewsCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      language: json['language'] as String?,
      preferredCategory: json['preferred_category'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
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
    double? rating,
    int? reviewsCount,
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
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }
}
