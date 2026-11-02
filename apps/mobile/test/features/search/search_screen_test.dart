import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar/core/error/result.dart';
import 'package:safar/core/l10n/generated/app_localizations.dart';
import 'package:safar/features/search/models/place_models.dart';
import 'package:safar/features/search/repositories/places_repository.dart';
import 'package:safar/features/search/search_screen.dart';

class StubPlacesRepository implements PlacesRepository {
  @override
  Future<Result<List<IndianState>>> getStates() async => Result.success([]);

  @override
  Future<Result<List<District>>> getDistricts(String stateCode) async => Result.success([]);

  @override
  Future<Result<List<PlaceResult>>> getDistrictPlaces(String districtId, {String? category}) async =>
      Result.success([]);

  @override
  Future<Result<List<PlaceResult>>> searchPlaces({
    required String query,
    double? lat,
    double? lng,
    String? state,
    String? district,
    String? category,
  }) async {
    return Result.success([
      const PlaceResult(
        id: 'tn-002',
        name: 'Ooty',
        category: 'hill-station',
        description: 'Queen of hill stations',
        location: LatLng(lat: 11.4, lng: 76.6),
        sensitive: false,
        source: 'mock',
        fetchedAt: '2026-10-29T12:00:00Z',
      ),
    ]);
  }

  @override
  Future<Result<PlaceDetail>> getPlaceById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<PlaceResult>>> getNearbyPlaces({
    required double lat,
    required double lng,
    double radius = 50,
    String? category,
  }) async {
    return Result.success([]);
  }

  @override
  Future<Result<bool>> suggestPlace({required Map<String, dynamic> suggestionData}) async {
    return Result.success(true);
  }
}

Widget createSearchScreenTestWrapper({String? initialQuery}) {
  return ProviderScope(
    overrides: [
      placesRepositoryProvider.overrideWithValue(StubPlacesRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: SearchScreen(initialQuery: initialQuery),
    ),
  );
}

void main() {
  group('SearchScreen Widget Tests', () {
    testWidgets('Shows search field and category filter chips including Beaches, Bird Sanctuaries, Wildlife, Museums', (tester) async {
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSearchScreenTestWrapper());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.textContaining('🏖️ Beaches'), findsOneWidget);
      expect(find.textContaining('🌿 Forests'), findsOneWidget);
      expect(find.textContaining('🦜 Bird Sanctuaries'), findsOneWidget);
      expect(find.textContaining('🦁 Wildlife'), findsOneWidget);
      expect(find.textContaining('🏛️ Heritage'), findsOneWidget);
      expect(find.textContaining('🖼️ Museums'), findsOneWidget);
    });

    testWidgets('Displays search result tile when initialQuery is provided', (tester) async {
      await tester.pumpWidget(createSearchScreenTestWrapper(initialQuery: 'ooty'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // allow debounce
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ooty'), findsOneWidget);
      expect(find.textContaining('Queen of hill stations'), findsOneWidget);
    });
  });
}
