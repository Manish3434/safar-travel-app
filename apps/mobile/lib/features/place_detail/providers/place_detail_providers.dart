import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../stays/repositories/stays_repository.dart';
import '../../transport/repositories/transport_repository.dart';
import '../../weather/repositories/weather_repository.dart';
import '../models/place_detail_models.dart';

final placeWeatherProvider = FutureProvider.family<Result<WeatherData>, String>((ref, placeId) {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.getWeatherForPlace(placeId);
});

final placeStaysProvider = FutureProvider.family<Result<List<StayItem>>, String>((ref, placeId) {
  final repo = ref.watch(staysRepositoryProvider);
  return repo.getStaysNearPlace(placeId: placeId);
});

class RouteQuery {
  final String from;
  final String to;
  const RouteQuery({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteQuery &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}

final placeTransportProvider = FutureProvider.family<Result<TransportResult>, RouteQuery>((ref, query) {
  final repo = ref.watch(transportRepositoryProvider);
  return repo.getRoutes(from: query.from, to: query.to);
});

class DistanceQuery {
  final String placeId;
  final double lat;
  final double lng;
  const DistanceQuery({required this.placeId, required this.lat, required this.lng});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistanceQuery &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => placeId.hashCode ^ lat.hashCode ^ lng.hashCode;
}

final placeDistanceProvider = FutureProvider.family<Result<Map<String, dynamic>>, DistanceQuery>((ref, query) {
  final repo = ref.watch(transportRepositoryProvider);
  return repo.getDistance(placeId: query.placeId, lat: query.lat, lng: query.lng);
});
