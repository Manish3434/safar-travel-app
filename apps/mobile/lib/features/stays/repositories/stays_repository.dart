import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../place_detail/models/place_detail_models.dart';

abstract class StaysRepository {
  Future<Result<List<StayItem>>> getStaysNearPlace({
    required String placeId,
    int? maxPrice,
    double? minRating,
    String? type,
  });
}

final staysRepositoryProvider = Provider<StaysRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return StaysRepositoryImpl(client);
});

class StaysRepositoryImpl implements StaysRepository {
  final ApiClient _client;

  StaysRepositoryImpl(this._client);

  @override
  Future<Result<List<StayItem>>> getStaysNearPlace({
    required String placeId,
    int? maxPrice,
    double? minRating,
    String? type,
  }) {
    return _client.get<List<StayItem>>(
      ApiEndpoints.placeStays(placeId),
      queryParameters: {
        if (maxPrice != null) 'price_max': maxPrice,
        if (minRating != null) 'rating_min': minRating,
        if (type != null) 'type': type,
      },
      fromJson: (data) {
        final list = data as List? ?? [];
        return list.map((item) => StayItem.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }
}
