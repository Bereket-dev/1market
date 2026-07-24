import '../../core/utils/price_formatter.dart';
import 'syncable_entity.dart';

class Service with SyncableEntity {
  @override
  final String id;
  final String ownerId;
  final String title;
  final String category;
  final String description;
  final String coverDescription;
  final String? cvFileUrl;
  final int yearsOfExperience;
  final String priceRange;
  final String location;
  final bool availability;

  /// Cover image URL stored in Cloudinary.
  final String imageUrl;

  /// All image URLs for this service (multi-image support).
  final List<String> imageUrls;

  final DateTime createdAt;
  @override
  final DateTime localUpdatedAt;
  @override
  final DateTime? remoteUpdatedAt;
  @override
  final SyncStatus syncStatus;

  Service({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.category,
    required this.description,
    required this.coverDescription,
    this.cvFileUrl,
    required this.yearsOfExperience,
    required String priceRange,
    required this.location,
    this.availability = true,
    this.imageUrl = '',
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? localUpdatedAt,
    this.remoteUpdatedAt,
    this.syncStatus = SyncStatus.synced,
  })  : createdAt = createdAt ?? DateTime.now(),
        priceRange = formatETB(priceRange),
        imageUrls = imageUrls ?? const [],
        localUpdatedAt = localUpdatedAt ?? DateTime.now();

  factory Service.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '');
    final localUpdatedAt = DateTime.tryParse(json['local_updated_at'] as String? ?? '');
    final syncStatus = switch ((json['sync_status'] as String?) ?? 'synced') {
      'local' => SyncStatus.local,
      'pending' => SyncStatus.pending,
      'failed' => SyncStatus.failed,
      _ => SyncStatus.synced,
    };

    return Service(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      coverDescription: json['cover_description'] as String? ?? '',
      cvFileUrl: json['cv_file_url'] as String?,
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt() ?? 0,
      priceRange: json['price_range'] as String? ?? '',
      location: json['location'] as String? ?? '',
      availability: json['availability'] as bool? ?? false,
      imageUrl: json['image_url'] as String? ?? '',
      imageUrls: List<String>.from((json['image_urls'] as List?) ?? []),
      createdAt: createdAt ?? DateTime.now(),
      localUpdatedAt: localUpdatedAt ?? updatedAt ?? DateTime.now(),
      remoteUpdatedAt: updatedAt,
      syncStatus: syncStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'category': category,
        'description': description,
        'cover_description': coverDescription,
        'cv_file_url': cvFileUrl,
        'years_of_experience': yearsOfExperience,
        'price_range': priceRange,
        'location': location,
        'availability': availability,
        'image_url': imageUrl,
        'image_urls': imageUrls,
        'created_at': createdAt.toIso8601String(),
        'updated_at': remoteUpdatedAt?.toIso8601String(),
        'local_updated_at': localUpdatedAt.toIso8601String(),
        'sync_status': syncStatus.name,
      };

  Service copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? category,
    String? description,
    String? coverDescription,
    String? cvFileUrl,
    int? yearsOfExperience,
    String? priceRange,
    String? location,
    bool? availability,
    String? imageUrl,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
    SyncStatus? syncStatus,
  }) {
    return Service(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      coverDescription: coverDescription ?? this.coverDescription,
      cvFileUrl: cvFileUrl ?? this.cvFileUrl,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      priceRange: priceRange ?? this.priceRange,
      location: location ?? this.location,
      availability: availability ?? this.availability,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
