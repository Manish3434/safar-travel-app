import 'package:flutter_test/flutter_test.dart';
import 'package:safar/core/network/api_endpoints.dart';

void main() {
  group('ApiEndpoints Catalog Tests', () {
    test('All endpoints must start with /api/v1 version prefix', () {
      expect(ApiEndpoints.login, startsWith('/api/v1/'));
      expect(ApiEndpoints.register, startsWith('/api/v1/'));
      expect(ApiEndpoints.placesSearch, startsWith('/api/v1/'));
      expect(ApiEndpoints.placesNearby, startsWith('/api/v1/'));
      expect(ApiEndpoints.placesSuggest, startsWith('/api/v1/'));
      expect(ApiEndpoints.transportRoutes, startsWith('/api/v1/'));
      expect(ApiEndpoints.savedPlaces, startsWith('/api/v1/'));
    });

    test('Parameterized endpoint builders format URLs correctly', () {
      expect(ApiEndpoints.placeDetail('tn-001'), equals('/api/v1/places/tn-001'));
      expect(ApiEndpoints.placeWeather('tn-001'), equals('/api/v1/places/tn-001/weather'));
      expect(ApiEndpoints.placeStays('tn-001'), equals('/api/v1/places/tn-001/stays'));
      expect(ApiEndpoints.placeDistance('tn-001'), equals('/api/v1/places/tn-001/distance'));
      expect(ApiEndpoints.savedPlaceById('sp-101'), equals('/api/v1/saved-places/sp-101'));
    });
  });
}
