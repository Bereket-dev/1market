/// A single entry from the [marketplace_changes] change-log table.
///
/// Returned by the [get_changes_since] Postgres RPC as a JSONB array element.
/// The [version] is a monotonically increasing bigserial that the client
/// persists as a cursor so subsequent calls only fetch newer rows.
class MarketplaceChange {
  /// Monotonic sequence number from the [marketplace_changes] table.
  final int version;

  /// Which entity type changed. One of: 'listing', 'service', 'hiring_post'.
  final String entityType;

  /// UUID of the affected entity row.
  final String entityId;

  /// DML operation that produced this change record.
  /// One of: 'INSERT', 'UPDATE', 'DELETE'.
  final String operation;

  /// Server timestamp when the change was recorded.
  final DateTime changedAt;

  /// Full entity row JSON as stored in the change-log payload column.
  ///
  /// Null when the entity was hard-deleted by an admin (payload is not
  /// captured for hard deletes — use [operation] == 'DELETE' to detect them).
  final Map<String, dynamic>? payload;

  const MarketplaceChange({
    required this.version,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.changedAt,
    required this.payload,
  });

  factory MarketplaceChange.fromJson(Map<String, dynamic> json) {
    return MarketplaceChange(
      version: (json['version'] as num).toInt(),
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      operation: json['operation'] as String,
      changedAt: DateTime.parse(json['changed_at'] as String).toUtc(),
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'changed_at': changedAt.toIso8601String(),
        'payload': payload,
      };

  @override
  String toString() =>
      'MarketplaceChange(v=$version, $operation $entityType/$entityId)';
}
