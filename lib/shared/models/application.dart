import 'syncable_entity.dart';

/// Statuses that an Application can be in.
enum ApplicationStatus {
  submitted,
  reviewed,
  accepted,
  rejected;

  static ApplicationStatus fromString(String? s) => switch (s) {
        'reviewed' => reviewed,
        'accepted' => accepted,
        'rejected' => rejected,
        _ => submitted,
      };

  String get name => switch (this) {
        submitted => 'submitted',
        reviewed => 'reviewed',
        accepted => 'accepted',
        rejected => 'rejected',
      };
}

/// An application submitted by a user (applicant) to a [HiringPost].
///
/// Links back to the applicant's [Service] (from Part 1) via [serviceId].
/// Writes by the applicant go through the SyncService queue.
/// Status updates by the hiring post's owner also go through the queue.
class Application with SyncableEntity {
  @override
  final String id;
  final String hiringPostId;
  final String applicantId;

  /// The specific service the applicant is applying from.
  final String serviceId;

  final ApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? statusUpdatedAt;

  // ── SyncableEntity ──────────────────────────────────────────────────────────
  @override
  final DateTime localUpdatedAt;
  @override
  final DateTime? remoteUpdatedAt;
  @override
  final SyncStatus syncStatus;

  // ── Denormalized display fields (loaded via joins) ──────────────────────────
  final String? applicantName;
  final String? applicantAvatarUrl;
  final String? serviceName;
  final String? hiringPostTitle;

  Application({
    required this.id,
    required this.hiringPostId,
    required this.applicantId,
    required this.serviceId,
    this.status = ApplicationStatus.submitted,
    DateTime? submittedAt,
    this.statusUpdatedAt,
    DateTime? localUpdatedAt,
    this.remoteUpdatedAt,
    this.syncStatus = SyncStatus.synced,
    this.applicantName,
    this.applicantAvatarUrl,
    this.serviceName,
    this.hiringPostTitle,
  })  : submittedAt = submittedAt ?? DateTime.now(),
        localUpdatedAt = localUpdatedAt ?? DateTime.now();

  factory Application.fromJson(Map<String, dynamic> json) {
    final submittedAt =
        DateTime.tryParse(json['submitted_at'] as String? ?? '');
    final statusUpdatedAt =
        DateTime.tryParse(json['status_updated_at'] as String? ?? '');
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

    // Support denormalized joins from Supabase select with nested objects.
    final profileJoin =
        json['profiles'] as Map<String, dynamic>?;
    final serviceJoin =
        json['services'] as Map<String, dynamic>?;
    final postJoin =
        json['hiring_posts'] as Map<String, dynamic>?;

    return Application(
      id: json['id'] as String,
      hiringPostId: json['hiring_post_id'] as String,
      applicantId: json['applicant_id'] as String,
      serviceId: json['service_id'] as String,
      status: ApplicationStatus.fromString(
        json['status'] as String?,
      ),
      submittedAt: submittedAt ?? DateTime.now(),
      statusUpdatedAt: statusUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? updatedAt ?? DateTime.now(),
      remoteUpdatedAt: updatedAt,
      syncStatus: syncStatus,
      applicantName: profileJoin?['display_name'] as String?,
      applicantAvatarUrl: profileJoin?['avatar_url'] as String?,
      serviceName: serviceJoin?['title'] as String?,
      hiringPostTitle: postJoin?['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hiring_post_id': hiringPostId,
        'applicant_id': applicantId,
        'service_id': serviceId,
        'status': status.name,
        'submitted_at': submittedAt.toIso8601String(),
        'status_updated_at': statusUpdatedAt?.toIso8601String(),
        'updated_at': remoteUpdatedAt?.toIso8601String(),
        'local_updated_at': localUpdatedAt.toIso8601String(),
        'sync_status': syncStatus.name,
        // Denormalized display fields are NOT persisted to Supabase.
      };

  Application copyWith({
    String? id,
    String? hiringPostId,
    String? applicantId,
    String? serviceId,
    ApplicationStatus? status,
    DateTime? submittedAt,
    DateTime? statusUpdatedAt,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
    SyncStatus? syncStatus,
    String? applicantName,
    String? applicantAvatarUrl,
    String? serviceName,
    String? hiringPostTitle,
  }) {
    return Application(
      id: id ?? this.id,
      hiringPostId: hiringPostId ?? this.hiringPostId,
      applicantId: applicantId ?? this.applicantId,
      serviceId: serviceId ?? this.serviceId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      applicantName: applicantName ?? this.applicantName,
      applicantAvatarUrl:
          applicantAvatarUrl ?? this.applicantAvatarUrl,
      serviceName: serviceName ?? this.serviceName,
      hiringPostTitle: hiringPostTitle ?? this.hiringPostTitle,
    );
  }
}
