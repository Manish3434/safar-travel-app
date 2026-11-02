import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error/failures.dart';
import '../error/result.dart';
import '../providers/dio_provider.dart';

abstract class ApiClient {
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  });

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  });

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  });
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClientImpl(dio);
});

class ApiClientImpl implements ApiClient {
  final Dio _dio;

  ApiClientImpl(this._dio);

  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  }) async {
    return _send<T>(() => _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
        ), fromJson);
  }

  @override
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  }) async {
    return _send<T>(() => _dio.post<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
        ), fromJson);
  }

  @override
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
    CancelToken? cancelToken,
  }) async {
    return _send<T>(() => _dio.delete<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
        ), fromJson);
  }

  Future<Result<T>> _send<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data)? fromJson,
  ) async {
    try {
      final response = await request();
      final responseBody = response.data;

      // Handle standard envelope { success: true, data: ... } or raw payload
      dynamic rawData = responseBody;
      if (responseBody is Map<String, dynamic> && responseBody.containsKey('data')) {
        rawData = responseBody['data'];
      }

      if (fromJson != null) {
        return Result.success(fromJson(rawData));
      }

      return Result.success(rawData as T);
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    } catch (e) {
      return Result.failure(UnknownFailure('Unexpected data formatting error: $e'));
    }
  }

  AppFailure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMessage;

    if (data is Map<String, dynamic>) {
      serverMessage = data['message'] as String? ?? (data['error'] as Map<String, dynamic>?)?['message'] as String?;
    }

    if (statusCode == 401) {
      return UnauthorizedFailure(serverMessage ?? 'Session expired. Please log in again.');
    }
    if (statusCode == 404) {
      return NotFoundFailure(serverMessage ?? 'Requested resource was not found.');
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerFailure(serverMessage ?? 'Server error ($statusCode). Please try again.', statusCode);
    }

    return UnknownFailure(serverMessage ?? e.message ?? 'Network request failed');
  }
}
