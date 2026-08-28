import 'package:flutter_test/flutter_test.dart';
import 'package:onemarket/shared/models/service.dart';
import 'package:onemarket/shared/models/syncable_entity.dart';

void main() {
  test('Service round-trips through JSON and preserves sync metadata', () {
    final service = Service(
      id: 'svc-1',
      ownerId: 'user-1',
      title: 'House cleaning',
      category: 'HOUSEHOLD',
      description: 'Deep cleaning and repairs',
      coverDescription: 'Fast, reliable house cleaning',
      yearsOfExperience: 4,
      priceRange: 'ETB 800-1200',
      location: 'Kebele 06',
      availability: true,
      createdAt: DateTime.utc(2024, 1, 2),
      syncStatus: SyncStatus.pending,
      localUpdatedAt: DateTime.utc(2024, 1, 2, 12),
    );

    final json = service.toJson();
    final restored = Service.fromJson(json);

    expect(restored.id, service.id);
    expect(restored.title, service.title);
    expect(restored.coverDescription, service.coverDescription);
    expect(restored.availability, isTrue);
    expect(restored.syncStatus, SyncStatus.pending);
  });
}
