import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../data/default_places_data.dart';
import '../models/place_models.dart';

abstract class PlacesRepository {
  Future<Result<List<IndianState>>> getStates();
  Future<Result<List<District>>> getDistricts(String stateCode);
  Future<Result<List<PlaceResult>>> getDistrictPlaces(String districtId, {String? category});
  Future<Result<List<PlaceResult>>> searchPlaces({
    required String query,
    double? lat,
    double? lng,
    String? state,
    String? district,
    String? category,
  });
  Future<Result<PlaceDetail>> getPlaceById(String id);
  Future<Result<List<PlaceResult>>> getNearbyPlaces({
    required double lat,
    required double lng,
    double radius = 50,
    String? category,
  });
  Future<Result<bool>> suggestPlace({required Map<String, dynamic> suggestionData});
}

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PlacesRepositoryImpl(client);
});

class PlacesRepositoryImpl implements PlacesRepository {
  final ApiClient _client;

  PlacesRepositoryImpl(this._client);

  @override
  Future<Result<List<IndianState>>> getStates() async {
    final result = await _client.get<List<IndianState>>(
      ApiEndpoints.regionsStates,
      fromJson: (data) {
        final list = data as List? ?? [];
        return list.map((item) => IndianState.fromJson(item as Map<String, dynamic>)).toList();
      },
    );

    return result.when(
      success: (states) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final jsonString = jsonEncode(states.map((s) => s.toJson()).toList());
          await prefs.setString('cached_regions_states', jsonString);
        } catch (_) {}
        return Result.success(states);
      },
      failure: (failure) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final cached = prefs.getString('cached_regions_states');
          if (cached != null) {
            final rawList = jsonDecode(cached) as List? ?? [];
            final cachedStates = rawList
                .map((e) => IndianState.fromJson(e as Map<String, dynamic>))
                .toList();
            if (cachedStates.isNotEmpty) {
              return Result.success(cachedStates);
            }
          }
        } catch (_) {}
        // Fallback to built-in 36 States catalog so app renders immediately
        return Result.success(DEFAULT_STATES);
      },
    );
  }

  @override
  Future<Result<List<District>>> getDistricts(String stateCode) async {
    final code = stateCode.toUpperCase();
    final result = await _client.get<List<District>>(
      ApiEndpoints.regionsDistricts(code),
      fromJson: (data) {
        final list = data as List? ?? [];
        return list.map((item) => District.fromJson(item as Map<String, dynamic>)).toList();
      },
    );

    return result.when(
      success: (districts) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final jsonString = jsonEncode(districts.map((d) => d.toJson()).toList());
          await prefs.setString('cached_regions_districts_$code', jsonString);
        } catch (_) {}
        return Result.success(districts);
      },
      failure: (failure) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final cached = prefs.getString('cached_regions_districts_$code');
          if (cached != null) {
            final rawList = jsonDecode(cached) as List? ?? [];
            final cachedDistricts = rawList
                .map((e) => District.fromJson(e as Map<String, dynamic>))
                .toList();
            if (cachedDistricts.isNotEmpty) {
              return Result.success(cachedDistricts);
            }
          }
        } catch (_) {}
        // Fallback to canonical districts for this state
        return Result.success(getFallbackDistrictsForState(code));
      },
    );
  }

  @override
  Future<Result<List<PlaceResult>>> getDistrictPlaces(String districtId, {String? category}) async {
    final result = await _client.get<List<PlaceResult>>(
      ApiEndpoints.districtPlaces(districtId, category: category),
      fromJson: (data) {
        final list = data as List? ?? [];
        return list.map((item) => PlaceResult.fromJson(item as Map<String, dynamic>)).toList();
      },
    );

    return result.when(
      success: (places) => Result.success(places),
      failure: (_) {
        final normDistId = districtId.toLowerCase().trim();
        final normCategory = category?.toLowerCase().trim();

        // 1. Filter by district ID
        var spots = DEFAULT_SPOTS.where((spot) {
          final matchesDistrict = spot.districtId?.toLowerCase() == normDistId;
          if (!matchesDistrict) return false;
          if (normCategory != null && normCategory.isNotEmpty && normCategory != 'all') {
            return spot.category.toLowerCase() == normCategory;
          }
          return true;
        }).toList();

        // 2. Fallback to state level if this specific district has no mock spots yet
        if (spots.isEmpty) {
          final statePrefix = normDistId.split('-').first;
          spots = DEFAULT_SPOTS.where((spot) {
            final matchesState = spot.stateCode?.toLowerCase() == statePrefix;
            if (normCategory != null && normCategory.isNotEmpty && normCategory != 'all') {
              return matchesState && spot.category.toLowerCase() == normCategory;
            }
            return matchesState;
          }).toList();
        }

        // 3. Fallback to category match across all spots
        if (spots.isEmpty && normCategory != null && normCategory.isNotEmpty && normCategory != 'all') {
          spots = DEFAULT_SPOTS.where((spot) => spot.category.toLowerCase() == normCategory).toList();
        }

        // 4. Default to first few spots if still empty so screen is never blank
        if (spots.isEmpty) {
          spots = DEFAULT_SPOTS.take(4).toList();
        }

        return Result.success(spots);
      },
    );
  }

  @override
  Future<Result<List<PlaceResult>>> searchPlaces({
    required String query,
    double? lat,
    double? lng,
    String? state,
    String? district,
    String? category,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty &&
        state == null &&
        district == null &&
        (category == null || category.isEmpty || category.toLowerCase() == 'all')) {
      return Result.success(const []);
    }

    final result = await _client.get<List<PlaceResult>>(
      ApiEndpoints.placesSearch,
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (state != null) 'state': state,
        if (district != null) 'district': district,
        if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') 'category': category,
      },
      fromJson: (data) {
        final rawList = data as List? ?? [];
        return rawList
            .map((item) => PlaceResult.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );

    return result.when(
      success: (places) => Result.success(places),
      failure: (_) {
        final q = query.toLowerCase().trim();
        final cat = category?.toLowerCase().trim();
        final st = state?.toLowerCase().trim();
        final dt = district?.toLowerCase().trim();

        final filtered = DEFAULT_SPOTS.where((spot) {
          if (q.isNotEmpty) {
            final matchName = spot.name.toLowerCase().contains(q);
            final matchDesc = spot.description?.toLowerCase().contains(q) ?? false;
            final matchCat = spot.category.toLowerCase().contains(q);
            final matchDist = spot.districtName?.toLowerCase().contains(q) ?? false;
            if (!matchName && !matchDesc && !matchCat && !matchDist) return false;
          }
          if (cat != null && cat.isNotEmpty && cat != 'all') {
            if (spot.category.toLowerCase() != cat) return false;
          }
          if (st != null && st.isNotEmpty) {
            if (spot.stateCode?.toLowerCase() != st) return false;
          }
          if (dt != null && dt.isNotEmpty) {
            if (spot.districtId?.toLowerCase() != dt) return false;
          }
          return true;
        }).toList();

        return Result.success(filtered.isNotEmpty ? filtered : DEFAULT_SPOTS.take(4).toList());
      },
    );
  }

  @override
  Future<Result<PlaceDetail>> getPlaceById(String id) async {
    final result = await _client.get<PlaceDetail>(
      ApiEndpoints.placeDetail(id),
      fromJson: (data) => PlaceDetail.fromJson(data as Map<String, dynamic>),
    );

    return result.when(
      success: (place) => Result.success(place),
      failure: (failure) {
        final matches = DEFAULT_SPOTS.where((s) => s.id == id);
        if (matches.isNotEmpty) {
          final spot = matches.first;
          return Result.success(PlaceDetail(
            id: spot.id,
            name: spot.name,
            nameTa: spot.nameTa,
            nameHi: spot.nameHi,
            category: spot.category,
            stateCode: spot.stateCode,
            stateName: spot.stateName,
            districtId: spot.districtId,
            districtName: spot.districtName,
            location: spot.location,
            rating: spot.rating,
            description: spot.description,
            photos: [
              if (spot.mainPhotoUrl != null) spot.mainPhotoUrl!,
            ],
            sensitive: spot.sensitive,
            source: spot.source,
            fetchedAt: spot.fetchedAt,
            permitRequired: false,
            guideRequired: false,
          ));
        }
        return Result.failure(failure);
      },
    );
  }

  @override
  Future<Result<List<PlaceResult>>> getNearbyPlaces({
    required double lat,
    required double lng,
    double radius = 50,
    String? category,
  }) {
    return _client.get<List<PlaceResult>>(
      ApiEndpoints.placesNearby,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        if (category != null) 'category': category,
      },
      fromJson: (data) {
        final rawList = data as List? ?? [];
        return rawList
            .map((item) => PlaceResult.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Result<bool>> suggestPlace({required Map<String, dynamic> suggestionData}) {
    return _client.post<bool>(
      ApiEndpoints.placesSuggest,
      data: suggestionData,
      fromJson: (_) => true,
    );
  }
}
