import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../place_detail/models/place_detail_models.dart';

abstract class TransportRepository {
  Future<Result<TransportResult>> getRoutes({
    required String from,
    required String to,
    String? date,
  });

  Future<Result<Map<String, dynamic>>> getDistance({
    required String placeId,
    required double lat,
    required double lng,
  });
}

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TransportRepositoryImpl(client);
});

class TransportRepositoryImpl implements TransportRepository {
  final ApiClient _client;

  TransportRepositoryImpl(this._client);

  @override
  Future<Result<TransportResult>> getRoutes({
    required String from,
    required String to,
    String? date,
  }) {
    return _client.get<TransportResult>(
      ApiEndpoints.transportRoutes,
      queryParameters: {
        'from': from,
        'to': to,
        if (date != null) 'date': date,
      },
      fromJson: (data) => TransportResult.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getDistance({
    required String placeId,
    required double lat,
    required double lng,
  }) {
    return _client.get<Map<String, dynamic>>(
      ApiEndpoints.placeDistance(placeId),
      queryParameters: {
        'lat': lat,
        'lng': lng,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}
