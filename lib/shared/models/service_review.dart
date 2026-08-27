/// A review for a specific service, left by a reviewer.
///
/// Submission is gated: the reviewer must own a hiring post that accepted
/// an application for this service (and must not own the service).
class ServiceReview {
  const ServiceReview({
    required this.id,
    required this.serviceId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatarUrl,
  });

  final String id;
  final String serviceId;
  final String reviewerId;

  /// 1–5 star rating.
  final int rating;
  final String comment;
  final DateTime createdAt;

  /// Denormalized display name fetched when loading reviews.
  final String? reviewerName;
  final String? reviewerAvatarUrl;

  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(
          json['created_at'] as String? ?? '',
        ) ??
        DateTime.now();
    return ServiceReview(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      rating: (json['rating'] as num?)?.toInt() ?? 3,
      comment: json['comment'] as String? ?? '',
      createdAt: createdAt,
      reviewerName: json['reviewer_name'] as String?,
      reviewerAvatarUrl: json['reviewer_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_id': serviceId,
        'reviewer_id': reviewerId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}
