import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/place_detail/place_detail_screen.dart';
import '../../features/saved_places/saved_places_screen.dart';
import '../../features/offline_maps/offline_maps_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/search/district_places_screen.dart';
import '../../features/search/models/place_models.dart';

/// Route names — use these constants instead of raw strings
abstract class AppRoutes {
  static const home = '/';
  static const search = '/search';
  static const placeDetail = '/places/:id';
  static const savedPlaces = '/saved';
  static const offlineMaps = '/offline-maps';
  static const login = '/login';
  static const districtPlaces = '/district-places';

  static String placeDetailPath(String id) => '/places/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: AppRoutes.placeDetail,
        builder: (context, state) => PlaceDetailScreen(
          placeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.savedPlaces,
        builder: (context, state) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: AppRoutes.offlineMaps,
        builder: (context, state) => const OfflineMapsScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.districtPlaces,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final district = extra['district'] as District;
          final indianState = extra['state'] as IndianState;
          return DistrictPlacesScreen(district: district, state: indianState);
        },
      ),
    ],
  );
});
