import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../models/place_models.dart';
import '../repositories/places_repository.dart';

/// Provider for loading all 28 States & UTs of India
final statesProvider = FutureProvider<Result<List<IndianState>>>((ref) {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.getStates();
});

/// Provider for loading districts of a given state code (e.g. 'TN' -> 38 districts)
final stateDistrictsProvider = FutureProvider.family<Result<List<District>>, String>((ref, stateCode) {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.getDistricts(stateCode);
});

/// Currently selected State filter (e.g. Tamil Nadu)
final selectedStateFilterProvider = StateProvider<IndianState?>((ref) => null);

/// Currently selected District filter (e.g. Nilgiris)
final selectedDistrictFilterProvider = StateProvider<District?>((ref) => null);

/// Provider for loading spots in a specific district
final districtPlacesProvider = FutureProvider.family<Result<List<PlaceResult>>, String>((ref, districtId) {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.getDistrictPlaces(districtId);
});
