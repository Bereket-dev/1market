import 'syncable_entity.dart';

/// A hiring post created by a user looking for a skilled service provider.
///
/// Visibility rules:
/// - status == 'open'  → visible to everyone in the browse list.
/// - status == 'closed' → hidden from the public browse list, but still
///   visible in the poster's own management screen.
///
/// Writes go through the SyncService queue (same pattern as [Service]).
class HiringPost with SyncableEntity {
  @override
  final String id;
  final String posterId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String priceRange;

  /// 'open' or 'closed'.
  final String status;

  final DateTime createdAt;

  @override
  final DateTime localUpdatedAt;
  @override
  final DateTime? remoteUpdatedAt;
  @override
  final SyncStatus syncStatus;

  /// Denormalized applicant count — updated from the applications table.
  /// Not persisted to the hiring_posts table; loaded separately.
  final int applicantCount;

  HiringPost({
    required this.id,
    required this.posterId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.priceRange,
    this.status = 'open',
    DateTime? createdAt,
    DateTime? localUpdatedAt,
    this.remoteUpdatedAt,
    this.syncStatus = SyncStatus.synced,
    this.applicantCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        localUpdatedAt = localUpdatedAt ?? DateTime.now();

  bool get isOpen => status == 'open';

  factory HiringPost.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['created_at'] as String? ?? '');
    final updatedAt =
        DateTime.tryParse(json['updated_at'] as String? ?? '');
    final localUpdatedAt =
        DateTime.tryParse(json['local_updated_at'] as String? ?? '');
    final syncStatus = switch (
        (json['sync_status'] as String?) ?? 'synced') {
      'local' => SyncStatus.local,
      'pending' => SyncStatus.pending,
      'failed' => SyncStatus.failed,
      _ => SyncStatus.synced,
    };

    return HiringPost(
      id: json['id'] as String,
      posterId: json['poster_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      location: json['location'] as String? ?? '',
      priceRange: json['price_range'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: createdAt ?? DateTime.now(),
      localUpdatedAt: localUpdatedAt ?? updatedAt ?? DateTime.now(),
      remoteUpdatedAt: updatedAt,
      syncStatus: syncStatus,
      applicantCount:
          (json['applicant_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'poster_id': posterId,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'price_range': priceRange,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': remoteUpdatedAt?.toIso8601String(),
        'local_updated_at': localUpdatedAt.toIso8601String(),
        'sync_status': syncStatus.name,
        // applicantCount is not persisted to Supabase — loaded separately.
      };

  HiringPost copyWith({
    String? id,
    String? posterId,
    String? title,
    String? description,
    String? category,
    String? location,
    String? priceRange,
    String? status,
    DateTime? createdAt,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
    SyncStatus? syncStatus,
    int? applicantCount,
  }) {
    return HiringPost(
      id: id ?? this.id,
      posterId: posterId ?? this.posterId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      priceRange: priceRange ?? this.priceRange,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      applicantCount: applicantCount ?? this.applicantCount,
    );
  }
}
