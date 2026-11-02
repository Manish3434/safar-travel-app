import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safar/features/saved_places/providers/saved_places_provider.dart';
import 'package:safar/features/search/models/place_models.dart';

void main() {
  group('SavedPlacesNotifier Tests', () {
    const testPlace = PlaceResult(
      id: 'tn-001',
      name: 'Hogenakkal Falls',
      category: 'waterfall',
      description: 'Scenic waterfall',
      location: LatLng(lat: 12.1, lng: 77.7),
      sensitive: false,
      source: 'mock',
      fetchedAt: '2026-10-29T12:00:00Z',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('toggleSave adds place when not present and marks as isSaved', () async {
      final notifier = SavedPlacesNotifier();

      expect(notifier.isSaved(testPlace.id), isFalse);

      await notifier.toggleSave(testPlace);

      expect(notifier.isSaved(testPlace.id), isTrue);
      expect(notifier.state.length, equals(1));
      expect(notifier.state.first.id, equals('tn-001'));
    });

    test('toggleSave removes place when already present', () async {
      final notifier = SavedPlacesNotifier();

      await notifier.toggleSave(testPlace);
      expect(notifier.isSaved(testPlace.id), isTrue);

      await notifier.toggleSave(testPlace);
      expect(notifier.isSaved(testPlace.id), isFalse);
      expect(notifier.state, isEmpty);
    });
  });
}
