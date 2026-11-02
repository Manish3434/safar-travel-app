import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safar/core/error/failures.dart';
import 'package:safar/core/error/result.dart';
import 'package:safar/core/network/api_client.dart';
import 'package:safar/features/search/repositories/places_repository.dart';

class FakeApiClient implements ApiClient {
  Result<dynamic>? mockResult;
  String? lastPath;
  Map<String, dynamic>? lastQueryParams;
  dynamic lastData;

  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    if (mockResult!.isSuccess) {
      final raw = mockResult!.dataOrNull;
      return Result.success(fromJson != null ? fromJson(raw) : raw as T);
    }
    return Result.failure(mockResult!.failureOrNull!);
  }

  @override
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    if (mockResult!.isSuccess) {
      final raw = mockResult!.dataOrNull;
      return Result.success(fromJson != null ? fromJson(raw) : raw as T);
    }
    return Result.failure(mockResult!.failureOrNull!);
  }

  @override
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  }) async {
    return Result.success(true as T);
  }
}

void main() {
  group('PlacesRepository Tests', () {
    late FakeApiClient client;
    late PlacesRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      client = FakeApiClient();
      repository = PlacesRepositoryImpl(client);
    });

    test('searchPlaces returns empty list without calling API when query is empty', () async {
      final result = await repository.searchPlaces(query: '');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
      expect(client.lastPath, isNull);
    });

    test('searchPlaces passes query, lat, lng and parses PlaceResult list', () async {
      client.mockResult = Result.success([
        {
          'id': 'tn-001',
          'name': 'Hogenakkal',
          'category': 'waterfall',
          'description': 'Scenic waterfall',
          'location': {'lat': 12.1, 'lng': 77.7},
          'sensitive': false,
          'source': 'mock',
          'fetched_at': '2026-10-29T12:00:00Z',
        }
      ]);

      final result = await repository.searchPlaces(query: 'waterfall', lat: 12.0, lng: 77.0);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));
      expect(result.dataOrNull?.first.name, equals('Hogenakkal'));
      expect(client.lastPath, equals('/api/v1/places/search'));
      expect(client.lastQueryParams?['q'], equals('waterfall'));
      expect(client.lastQueryParams?['lat'], equals(12.0));
    });

    test('getPlaceById fetches place detail correctly', () async {
      client.mockResult = Result.success({
        'id': 'tn-002',
        'name': 'Ooty',
        'category': 'hill-station',
        'description': 'Queen of hills',
        'location': {'lat': 11.4, 'lng': 76.6},
        'sensitive': false,
        'source': 'mock',
        'fetched_at': '2026-10-29T12:00:00Z',
        'photos': ['https://example.com/ooty.jpg'],
        'permit_required': false,
        'guide_required': false,
      });

      final result = await repository.getPlaceById('tn-002');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, equals('tn-002'));
      expect(result.dataOrNull?.photos.length, equals(1));
      expect(client.lastPath, equals('/api/v1/places/tn-002'));
    });

    test('suggestPlace posts suggestion payload to /api/v1/places/suggest', () async {
      client.mockResult = Result.success(true);

      final result = await repository.suggestPlace(suggestionData: {
        'name': 'Secret Falls',
        'description': 'Hidden spot near Wayanad border',
      });

      expect(result.isSuccess, isTrue);
      expect(client.lastPath, equals('/api/v1/places/suggest'));
      expect(client.lastData['name'], equals('Secret Falls'));
    });

    test('repository returns failure when ApiClient returns failure', () async {
      client.mockResult = Result.failure(const NetworkFailure('No connection'));

      final result = await repository.getPlaceById('unknown');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('getStates fetches list of Indian states', () async {
      client.mockResult = Result.success([
        {
          'code': 'TN',
          'name': 'Tamil Nadu',
          'name_ta': 'தமிழ்நாடு',
          'district_count': 38,
          'image_url': 'https://example.com/tn.jpg',
        }
      ]);

      final result = await repository.getStates();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));
      expect(result.dataOrNull?.first.name, equals('Tamil Nadu'));
      expect(result.dataOrNull?.first.districtCount, equals(38));
      expect(client.lastPath, equals('/api/v1/regions/states'));
    });

    test('getDistricts fetches districts for a given state code', () async {
      client.mockResult = Result.success([
        {
          'id': 'tn-nilgiris',
          'name': 'Nilgiris',
          'name_ta': 'நீலகிரி',
          'state_code': 'TN',
          'spot_count': 1,
        }
      ]);

      final result = await repository.getDistricts('TN');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));
      expect(result.dataOrNull?.first.id, equals('tn-nilgiris'));
      expect(client.lastPath, equals('/api/v1/regions/states/TN/districts'));
    });

    test('getDistrictPlaces fetches tourist spots for a specific district', () async {
      client.mockResult = Result.success([
        {
          'id': 'tn-002',
          'name': 'Ooty',
          'category': 'hill-station',
          'state_code': 'TN',
          'district_id': 'tn-nilgiris',
          'description': 'Queen of hill stations',
          'location': {'lat': 11.41, 'lng': 76.70},
          'sensitive': false,
          'source': 'mock',
          'fetched_at': '2026-10-29T12:00:00Z',
        }
      ]);

      final result = await repository.getDistrictPlaces('tn-nilgiris');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));
      expect(result.dataOrNull?.first.districtId, equals('tn-nilgiris'));
      expect(client.lastPath, equals('/api/v1/places/districts/tn-nilgiris'));
    });

    test('getDistrictPlaces passes category filter in query path', () async {
      client.mockResult = Result.success(<dynamic>[]);

      await repository.getDistrictPlaces('tn-chennai', category: 'beach');

      expect(client.lastPath, equals('/api/v1/places/districts/tn-chennai?category=beach'));
    });

    test('searchPlaces includes category in queryParameters', () async {
      client.mockResult = Result.success(<dynamic>[]);

      await repository.searchPlaces(query: '', district: 'tn-nilgiris', category: 'wildlife');

      expect(client.lastQueryParams?['category'], equals('wildlife'));
      expect(client.lastQueryParams?['district'], equals('tn-nilgiris'));
    });
  });
}
