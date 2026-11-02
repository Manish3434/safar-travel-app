import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../place_detail/models/place_detail_models.dart';

abstract class WeatherRepository {
  Future<Result<WeatherData>> getWeatherForPlace(String placeId);
}

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return WeatherRepositoryImpl(client);
});

class WeatherRepositoryImpl implements WeatherRepository {
  final ApiClient _client;

  WeatherRepositoryImpl(this._client);

  @override
  Future<Result<WeatherData>> getWeatherForPlace(String placeId) {
    return _client.get<WeatherData>(
      ApiEndpoints.placeWeather(placeId),
      fromJson: (data) => WeatherData.fromJson(data as Map<String, dynamic>),
    );
  }
}
