enum SyncStatus { local, pending, synced, failed }

mixin SyncableEntity {
  String get id;
  DateTime get localUpdatedAt;
  DateTime? get remoteUpdatedAt;
  SyncStatus get syncStatus;
}
