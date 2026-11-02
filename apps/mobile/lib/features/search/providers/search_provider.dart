import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../models/place_models.dart';
import '../repositories/places_repository.dart';

import 'state_district_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.family<Result<List<PlaceResult>>, String>((ref, query) async {
  final repo = ref.watch(placesRepositoryProvider);
  final state = ref.watch(selectedStateFilterProvider);
  final district = ref.watch(selectedDistrictFilterProvider);
  final category = ref.watch(selectedCategoryFilterProvider);

  if (district != null && query.trim().isEmpty) {
    return repo.getDistrictPlaces(district.id, category: category);
  }

  return repo.searchPlaces(
    query: query,
    state: state?.code,
    district: district?.id,
    category: category,
  );
});

final districtPlacesProvider = FutureProvider.family<Result<List<PlaceResult>>, ({String districtId, String? category})>((ref, arg) async {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.getDistrictPlaces(arg.districtId, category: arg.category);
});

final placeDetailProvider = FutureProvider.family<Result<PlaceDetail>, String>((ref, placeId) async {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.getPlaceById(placeId);
});

