import 'dart:async';
import 'package:dio/dio.dart';

/// Exponential Backoff Retry Interceptor for idempotent network failures
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final isGetMethod = requestOptions.method.toUpperCase() == 'GET';
    final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;

    // Retry only on network blips or timeouts for GET operations
    final isRetryable = isGetMethod &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError ||
            (err.response?.statusCode != null && err.response!.statusCode! >= 500));

    if (isRetryable && retryCount < maxRetries) {
      final nextCount = retryCount + 1;
      requestOptions.extra['retry_count'] = nextCount;

      // Exponential backoff with jitter
      final delay = baseDelay * (1 << (nextCount - 1));
      await Future<void>.delayed(delay);

      try {
        final response = await dio.fetch<dynamic>(requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return super.onError(e, handler);
      }
    }

    return super.onError(err, handler);
  }
}
