import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safar/core/offline/offline_map_models.dart';
import 'package:safar/core/offline/offline_map_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineRegion Model Tests', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime(2026, 10, 30, 10, 0);
      final region = OfflineRegion(
        id: 'reg_ga_north',
        name: 'North Goa Coast',
        centerLat: 15.4925,
        centerLng: 73.7736,
        minZoom: 11,
        maxZoom: 14,
        tileCount: 64,
        sizeBytes: 908800,
        status: OfflineRegionStatus.downloaded,
        downloadedAt: now,
      );

      final json = region.toJson();
      expect(json['id'], 'reg_ga_north');
      expect(json['name'], 'North Goa Coast');
      expect(json['tileCount'], 64);
      expect(json['status'], 'downloaded');

      final parsed = OfflineRegion.fromJson(json);
      expect(parsed.id, region.id);
      expect(parsed.centerLat, region.centerLat);
      expect(parsed.centerLng, region.centerLng);
      expect(parsed.tileCount, region.tileCount);
      expect(parsed.status, OfflineRegionStatus.downloaded);
      expect(parsed.formattedSize, '887.5 KB');
    });

    test('copyWith updates properties properly', () {
      final region = OfflineRegion(
        id: 'test',
        name: 'Test Region',
        centerLat: 10.0,
        centerLng: 20.0,
        minZoom: 11,
        maxZoom: 14,
        tileCount: 0,
        sizeBytes: 0,
        status: OfflineRegionStatus.downloading,
        downloadedAt: DateTime.now(),
      );

      final updated = region.copyWith(
        status: OfflineRegionStatus.downloaded,
        tileCount: 42,
        sizeBytes: 600000,
      );

      expect(updated.status, OfflineRegionStatus.downloaded);
      expect(updated.tileCount, 42);
      expect(updated.sizeBytes, 600000);
      expect(updated.name, 'Test Region');
    });
  });

  group('OfflineRegionsNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('downloads and registers offline region correctly', () async {
      final notifier = OfflineRegionsNotifier();
      // Allow initial async load
      await Future.delayed(const Duration(milliseconds: 20));

      expect(notifier.state, isEmpty);

      double lastProgress = 0.0;
      await notifier.downloadRegion(
        id: 'reg_nilgiris',
        name: 'Nilgiris, TN',
        lat: 11.4102,
        lng: 76.6950,
        onProgress: (p) => lastProgress = p,
      );

      expect(lastProgress, 1.0);
      expect(notifier.state.length, 1);
      final saved = notifier.state.first;
      expect(saved.id, 'reg_nilgiris');
      expect(saved.status, OfflineRegionStatus.downloaded);
      expect(saved.tileCount, greaterThan(0));

      // Test distance check within 20km
      final isNearby = notifier.isDownloaded(11.42, 76.70, radiusKm: 15);
      expect(isNearby, isTrue);

      // Test distance check far away (e.g. Chennai ~400km away)
      final isFar = notifier.isDownloaded(13.0827, 80.2707, radiusKm: 15);
      expect(isFar, isFalse);

      expect(notifier.totalSizeBytes, greaterThan(0));
      expect(notifier.totalTileCount, greaterThan(0));

      // Test delete
      await notifier.deleteRegion('reg_nilgiris');
      expect(notifier.state, isEmpty);
      expect(notifier.totalSizeBytes, 0);
      expect(notifier.totalTileCount, 0);

      // Test clearAllRegions
      await notifier.downloadRegion(
        id: 'reg_1',
        name: 'Region 1',
        lat: 10.0,
        lng: 20.0,
      );
      await notifier.downloadRegion(
        id: 'reg_2',
        name: 'Region 2',
        lat: 30.0,
        lng: 40.0,
      );
      expect(notifier.state.length, 2);
      await notifier.clearAllRegions();
      expect(notifier.state, isEmpty);
    });
  });
}
