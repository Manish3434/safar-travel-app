import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar/core/error/result.dart';
import 'package:safar/core/l10n/generated/app_localizations.dart';
import 'package:safar/features/search/district_places_screen.dart';
import 'package:safar/features/search/models/place_models.dart';
import 'package:safar/features/search/repositories/places_repository.dart';

class StubDistrictPlacesRepo implements PlacesRepository {
  @override
  Future<Result<List<IndianState>>> getStates() async => Result.success([]);

  @override
  Future<Result<List<District>>> getDistricts(String stateCode) async => Result.success([]);

  @override
  Future<Result<List<PlaceResult>>> getDistrictPlaces(String districtId, {String? category}) async {
    return Result.success([
      const PlaceResult(
        id: 'tn-005',
        name: 'Marina Beach',
        nameTa: 'மெரினா கடற்கரை',
        category: 'beach',
        stateCode: 'TN',
        districtId: 'tn-chennai',
        description: 'World famous natural urban beach along the Bay of Bengal.',
        location: LatLng(lat: 13.04, lng: 80.28),
        sensitive: false,
        source: 'mock',
        fetchedAt: '2026-10-30T10:00:00Z',
      ),
      const PlaceResult(
        id: 'tn-006',
        name: 'Government Museum',
        nameTa: 'எழும்பூர் அரசு அருங்காட்சியகம்',
        category: 'museum',
        stateCode: 'TN',
        districtId: 'tn-chennai',
        description: 'Historic museum housing ancient bronzes and antiquities.',
        location: LatLng(lat: 13.06, lng: 80.25),
        sensitive: false,
        source: 'mock',
        fetchedAt: '2026-10-30T10:00:00Z',
      ),
    ]);
  }

  @override
  Future<Result<List<PlaceResult>>> searchPlaces({
    required String query,
    double? lat,
    double? lng,
    String? state,
    String? district,
    String? category,
  }) async =>
      Result.success([]);

  @override
  Future<Result<PlaceDetail>> getPlaceById(String id) async => throw UnimplementedError();

  @override
  Future<Result<List<PlaceResult>>> getNearbyPlaces({
    required double lat,
    required double lng,
    double radius = 50,
    String? category,
  }) async =>
      Result.success([]);

  @override
  Future<Result<bool>> suggestPlace({required Map<String, dynamic> suggestionData}) async =>
      Result.success(true);
}

void main() {
  const testState = IndianState(
    code: 'TN',
    name: 'Tamil Nadu',
    nameTa: 'தமிழ்நாடு',
    imageUrl: 'https://example.com/tn.jpg',
    districtCount: 38,
    spotCount: 10,
  );

  const testDistrict = District(
    id: 'tn-chennai',
    stateCode: 'TN',
    name: 'Chennai',
    nameTa: 'சென்னை',
    spotCount: 5,
  );

  Widget createWrapper() {
    return ProviderScope(
      overrides: [
        placesRepositoryProvider.overrideWithValue(StubDistrictPlacesRepo()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: DistrictPlacesScreen(
          district: testDistrict,
          state: testState,
        ),
      ),
    );
  }

  group('DistrictPlacesScreen Tests', () {
    testWidgets('Renders district header, top-pinned category pills and places list', (tester) async {
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWrapper());
      await tester.pumpAndSettle();

      // Verify district and state in AppBar
      expect(find.text('Chennai'), findsOneWidget);
      expect(find.textContaining('Tamil Nadu'), findsOneWidget);

      // Verify Category Pills directly above spots
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Beaches'), findsOneWidget);
      expect(find.text('Forests'), findsOneWidget);
      expect(find.text('Bird Sanctuaries'), findsOneWidget);
      expect(find.textContaining('Wildlife'), findsOneWidget);
      expect(find.text('Heritage'), findsOneWidget);
      expect(find.text('Museums'), findsOneWidget);

      // Verify places rendered in the list
      expect(find.text('Marina Beach'), findsOneWidget);
      expect(find.text('Government Museum'), findsOneWidget);
      expect(find.textContaining('Bay of Bengal'), findsOneWidget);
    });

    testWidgets('Tapping category pill updates filter state', (tester) async {
      await tester.pumpWidget(createWrapper());
      await tester.pumpAndSettle();

      // Tap Beaches category pill
      await tester.tap(find.text('Beaches'));
      await tester.pumpAndSettle();

      // Verify beaches selection remains interactive
      expect(find.text('Beaches'), findsOneWidget);
    });
  });
}
