import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../search/models/place_models.dart';

final savedPlacesProvider = StateNotifierProvider<SavedPlacesNotifier, List<PlaceResult>>((ref) {
  return SavedPlacesNotifier();
});

class SavedPlacesNotifier extends StateNotifier<List<PlaceResult>> {
  static const _storageKey = 'safar_saved_places_v1';

  SavedPlacesNotifier() : super([]) {
    _loadFromLocal();
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      final places = rawList.map((str) {
        final json = jsonDecode(str) as Map<String, dynamic>;
        return PlaceResult.fromJson(json);
      }).toList();
      state = places;
    } catch (_) {}
  }

  Future<void> toggleSave(PlaceResult place) async {
    final exists = state.any((p) => p.id == place.id);
    List<PlaceResult> updated;
    if (exists) {
      updated = state.where((p) => p.id != place.id).toList();
    } else {
      updated = [place, ...state];
    }
    state = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = updated.map((p) => jsonEncode({
        'id': p.id,
        'name': p.name,
        'name_ta': p.nameTa,
        'name_hi': p.nameHi,
        'category': p.category,
        'main_photo_url': p.mainPhotoUrl,
        'distance_km': p.distanceKm,
        'rating': p.rating,
        'description': p.description,
        'location': {'lat': p.location.lat, 'lng': p.location.lng},
        'sensitive': p.sensitive,
        'source': p.source,
        'fetched_at': p.fetchedAt,
      })).toList();
      await prefs.setStringList(_storageKey, rawList);
    } catch (_) {}
  }

  bool isSaved(String placeId) {
    return state.any((p) => p.id == placeId);
  }
}
