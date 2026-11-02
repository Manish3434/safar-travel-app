/// Centralized API Endpoints Catalog.
/// Single source of truth for all backend REST routes and parameter builders.
abstract class ApiEndpoints {
  static const String _prefix = '/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '$_prefix/auth/login';
  static const String register = '$_prefix/auth/register';

  // ── Regions (Single Source of Truth) ──────────────────────────────────────
  static const String regionsStates = '$_prefix/regions/states';
  static String regionsDistricts(String stateCode) => '$_prefix/regions/states/$stateCode/districts';

  // ── Places ────────────────────────────────────────────────────────────────
  static const String placesSearch = '$_prefix/places/search';
  static const String placesNearby = '$_prefix/places/nearby';
  static const String placesSuggest = '$_prefix/places/suggest';
  static const String placesStates = regionsStates; // Backward-compatible alias
  static String stateDistricts(String stateCode) => regionsDistricts(stateCode);
  static String districtPlaces(String districtId, {String? category}) {
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      return '$_prefix/places/districts/$districtId?category=${Uri.encodeComponent(category)}';
    }
    return '$_prefix/places/districts/$districtId';
  }
  static String placeDetail(String id) => '$_prefix/places/$id';
  static String placeDistance(String id) => '$_prefix/places/$id/distance';
  static String placeWeather(String id) => '$_prefix/places/$id/weather';
  static String placeStays(String id) => '$_prefix/places/$id/stays';

  // ── Transport ─────────────────────────────────────────────────────────────
  static const String transportRoutes = '$_prefix/transport/routes';

  // ── Saved Places ──────────────────────────────────────────────────────────
  static const String savedPlaces = '$_prefix/saved-places';
  static String savedPlaceById(String id) => '$_prefix/saved-places/$id';
}
